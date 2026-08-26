const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp, FieldValue } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const crypto = require('crypto');

initializeApp();
const db = getFirestore();

// Collection watched by the official Firebase "Trigger Email" extension
// (firebase/firestore-send-email). Adding a doc here is all this function
// does to send mail - the extension handles the actual SMTP delivery.
const MAIL_COLLECTION = 'mail';

const OTP_TTL_MS = 10 * 60 * 1000; // 10 minutes
const RESEND_COOLDOWN_MS = 60 * 1000; // 60 seconds
const MAX_ATTEMPTS = 5;

function hashCode(code) {
  return crypto.createHash('sha256').update(code).digest('hex');
}

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

// Sends a 6-digit verification code to `email` and stores its hash in
// Firestore (emailOtps/{email}) with a 10-minute expiry. The Firestore
// collection is locked to server-only access (see firestore.rules) -
// clients can only reach it through these callable functions.
exports.sendEmailOtp = onCall(async (request) => {
  const email = normalizeEmail(request.data?.email);
  if (!email || !email.includes('@')) {
    throw new HttpsError('invalid-argument', 'A valid email address is required.');
  }

  const docRef = db.collection('emailOtps').doc(email);
  const existing = await docRef.get();
  if (existing.exists) {
    const createdAtMs = existing.data().createdAt?.toMillis?.() ?? 0;
    if (Date.now() - createdAtMs < RESEND_COOLDOWN_MS) {
      throw new HttpsError('resource-exhausted', 'Please wait a moment before requesting another code.');
    }
  }

  const code = String(Math.floor(100000 + Math.random() * 900000));
  await docRef.set({
    codeHash: hashCode(code),
    expiresAt: Timestamp.fromMillis(Date.now() + OTP_TTL_MS),
    attempts: 0,
    createdAt: Timestamp.now(),
  });

  // Handed off to the "Trigger Email" extension, which watches this
  // collection and does the actual SMTP send.
  await db.collection(MAIL_COLLECTION).add({
    to: email,
    message: {
      subject: 'Your Roswalt My Home verification code',
      text: `Your verification code is ${code}. It expires in 10 minutes.`,
      html: `<div style="font-family:sans-serif;padding:24px;background:#1a0a00;color:#fff;">
        <h2 style="color:#d4af37;margin:0 0 16px;">Roswalt Realty</h2>
        <p style="margin:0 0 8px;">Your verification code is:</p>
        <p style="font-size:32px;font-weight:bold;letter-spacing:6px;color:#d4af37;margin:0 0 16px;">${code}</p>
        <p style="color:#aaa;font-size:12px;margin:0;">This code expires in 10 minutes. If you didn't request this, you can ignore this email.</p>
      </div>`,
    },
  });

  return { success: true };
});

// Verifies a submitted code against the stored hash. On success, mints a
// Firebase custom token for a stable uid derived from the email so the app
// can sign in via signInWithCustomToken and use FirebaseAuth.currentUser as
// its "verified" signal, same as every other auth path in this app.
exports.verifyEmailOtp = onCall(async (request) => {
  const email = normalizeEmail(request.data?.email);
  const code = String(request.data?.code || '').trim();
  if (!email || !code) {
    throw new HttpsError('invalid-argument', 'Email and code are required.');
  }

  const docRef = db.collection('emailOtps').doc(email);
  const snap = await docRef.get();
  if (!snap.exists) {
    throw new HttpsError('not-found', 'No verification code was requested for this email.');
  }
  const data = snap.data();

  if ((data.expiresAt?.toMillis?.() ?? 0) < Date.now()) {
    await docRef.delete();
    throw new HttpsError('deadline-exceeded', 'This code has expired. Please request a new one.');
  }
  if ((data.attempts || 0) >= MAX_ATTEMPTS) {
    await docRef.delete();
    throw new HttpsError('resource-exhausted', 'Too many incorrect attempts. Please request a new code.');
  }
  if (hashCode(code) !== data.codeHash) {
    await docRef.update({ attempts: FieldValue.increment(1) });
    throw new HttpsError('permission-denied', 'Incorrect code. Please try again.');
  }

  await docRef.delete();

  const uid = 'email:' + Buffer.from(email).toString('base64url');
  const token = await getAuth().createCustomToken(uid, { email });
  return { success: true, token };
});

// Returns the given IST-offset day (e.g. -1 for "yesterday in IST") as a
// 'YYYY-MM-DD' key, computed from UTC so it's correct regardless of which
// region the function instance actually runs in.
function istDateKey(offsetDays) {
  const IST_OFFSET_MS = 5.5 * 60 * 60 * 1000;
  const d = new Date(Date.now() + IST_OFFSET_MS);
  d.setUTCDate(d.getUTCDate() + offsetDays);
  const y = d.getUTCFullYear();
  const m = String(d.getUTCMonth() + 1).padStart(2, '0');
  const day = String(d.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

// Runs just after midnight IST every night. Finalizes ("backs up") every
// employee's attendance record for the day that just ended: locks it from
// further edits and backfills totalMinutes for anyone who checked in but
// never checked out. This is the nightly server-side close-out layer on top
// of the real-time writes checkIn()/checkOut() already do from the app.
exports.finalizeDailyAttendance = onSchedule(
  { schedule: '30 0 * * *', timeZone: 'Asia/Kolkata' },
  async () => {
    const dateKey = istDateKey(-1);
    const snap = await db
      .collectionGroup('attendance')
      .where('date', '==', dateKey)
      .where('finalized', '==', false)
      .get();

    if (snap.empty) return;

    const batch = db.batch();
    snap.docs.forEach((doc) => {
      const data = doc.data();
      const update = { finalized: true, finalizedAt: FieldValue.serverTimestamp() };
      if (data.checkIn && !data.checkOut) {
        update.status = data.status || 'present';
        update.autoClosedWithoutCheckOut = true;
      } else if (data.checkIn && data.checkOut && data.totalMinutes == null) {
        update.totalMinutes = Math.round((data.checkOut.toMillis() - data.checkIn.toMillis()) / 60000);
      }
      batch.set(doc.ref, update, { merge: true });
    });
    await batch.commit();
  }
);
