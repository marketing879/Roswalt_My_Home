const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onDocumentUpdated, onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp, FieldValue } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const { getMessaging } = require('firebase-admin/messaging');
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

// Looks up an employee by phone number in the org-wide staff directory
// (staffDirectory), server-side only — the directory itself is never
// exposed to unauthenticated clients. Only returns a match if that
// person's record has loginEnabled=true (set once their phone/email are
// filled in), so adding a name to the directory alone doesn't grant login.
exports.lookupStaffByPhone = onCall(async (request) => {
  const phone = String(request.data?.phone || '').replace(/\D/g, '');
  if (!phone) {
    throw new HttpsError('invalid-argument', 'A valid phone number is required.');
  }

  const snap = await db
    .collection('staffDirectory')
    .where('phone', '==', phone)
    .where('loginEnabled', '==', 'true')
    .limit(1)
    .get();

  if (snap.empty) {
    return { found: false };
  }

  const d = snap.docs[0].data();
  return {
    found: true,
    data: {
      name: d.name,
      employeeId: d.employeeId,
      email: d.email,
      designation: d.designation,
    },
  };
});

// Returns {employeeId, name} for every login-enabled staff member, so a
// signed-in employee can pick a real colleague as their leave/regularisation
// buddy (rather than typing a free-text name nobody can be notified at).
// Requires auth; never exposed to unauthenticated clients. Only ~450
// records today, so one full list per pick is simpler and cheap enough to
// beat paginating a prefix search.
exports.listStaffDirectory = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'You must be signed in.');
  }
  const snap = await db.collection('staffDirectory').where('loginEnabled', '==', 'true').get();
  return {
    staff: snap.docs.map((d) => ({ employeeId: d.data().employeeId, name: d.data().name })),
  };
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

// Writes a permanent record to employees/{uid}/notifications regardless of
// whether the push itself is delivered (device offline, token missing, app
// uninstalled, notification swiped away without tapping) - the in-app
// Notifications panel reads this collection so history is never dependent
// on transient FCM delivery.
async function notifyEmployee(uid, title, body, data) {
  await db.collection('employees').doc(uid).collection('notifications').add({
    title, body, data: data || {}, read: false, createdAt: FieldValue.serverTimestamp(),
  });

  const tokenSnap = await db.collection('employees').doc(uid).collection('meta').doc('fcm').get();
  const token = tokenSnap.data()?.token;
  if (!token) return;
  try {
    await getMessaging().send({
      token,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data || {}).map(([k, v]) => [k, String(v)])),
    });
  } catch (e) {
    console.error('FCM send failed', e);
  }
}

// Finds the uid of the employee doc holding a given employeeId (e.g.
// "ASH-030"). Used to turn a real-world employee ID - a reporting manager,
// or the employee picked as a leave/regularisation buddy - into the uid
// needed to look up their FCM token.
async function findUidByEmployeeId(employeeId) {
  if (!employeeId) return null;
  const snap = await db.collection('employees').where('employeeId', '==', employeeId).limit(1).get();
  return snap.empty ? null : snap.docs[0].id;
}

// The reporting-manager mapping is maintained on the web admin side, not by
// this app - it's expected as a `reportingManagerId` (employeeId string)
// field on the employee's staffDirectory/{employeeId} doc.
// The real mapping lives in reportingMap/{employeeId} (maintained by the
// HRMS web admin), with separate tlId/hodId fields - NOT
// staffDirectory.reportingManagerId, which doesn't exist. Prefers the TL;
// falls back to the HOD if no TL is assigned, matching the spec's
// TL-first-then-HOD-escalation pattern.
async function findReportingManagerUid(employeeId) {
  if (!employeeId) return null;
  const mapSnap = await db.collection('reportingMap').doc(employeeId).get();
  const managerId = mapSnap.data()?.tlId || mapSnap.data()?.hodId;
  return managerId ? findUidByEmployeeId(managerId) : null;
}

async function notifyBuddy(buddyEmployeeId, title, body, data) {
  const buddyUid = await findUidByEmployeeId(buddyEmployeeId);
  if (buddyUid) await notifyEmployee(buddyUid, title, body, data);
}

// Pushes a notification to the employee (and their buddy, if named) the
// moment a TL/HOD decides their leave request (status flips
// Pending -> Approved/Rejected). The decision itself isn't made here - this
// only fires once something else (the web admin, today) writes that status.
exports.onLeaveRequestDecided = onDocumentUpdated('employees/{uid}/leaveRequests/{requestId}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (before.status === after.status) return;
  if (after.status !== 'Approved' && after.status !== 'Rejected') return;

  const employeeDoc = await db.collection('employees').doc(event.params.uid).get();
  const employeeName = employeeDoc.data()?.name || 'An employee';

  await notifyEmployee(
    event.params.uid,
    `Leave ${after.status}`,
    `Your ${after.type} request (${after.dateLabel}) has been ${after.status.toLowerCase()}.`,
    { type: 'leaveRequest', requestId: event.params.requestId, status: after.status },
  );
  if (after.buddyEmployeeId) {
    await notifyBuddy(
      after.buddyEmployeeId,
      `Leave ${after.status}`,
      `${employeeName}'s ${after.type} request (${after.dateLabel}), which you're the buddy for, has been ${after.status.toLowerCase()}.`,
      { type: 'leaveRequest', requestId: event.params.requestId, status: after.status },
    );
  }
});

// Same as above, for regularisation requests (status Open -> Approved/Rejected).
exports.onRegularisationDecided = onDocumentUpdated('employees/{uid}/regularisations/{requestId}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (before.status === after.status) return;
  if (after.status !== 'Approved' && after.status !== 'Rejected') return;

  const employeeDoc = await db.collection('employees').doc(event.params.uid).get();
  const employeeName = employeeDoc.data()?.name || 'An employee';

  await notifyEmployee(
    event.params.uid,
    `Regularisation ${after.status}`,
    `Your regularisation request for ${after.dateLabel} has been ${after.status.toLowerCase()}.`,
    { type: 'regularisation', requestId: event.params.requestId, status: after.status },
  );
  if (after.buddyEmployeeId) {
    await notifyBuddy(
      after.buddyEmployeeId,
      `Regularisation ${after.status}`,
      `${employeeName}'s regularisation request for ${after.dateLabel}, which you're the buddy for, has been ${after.status.toLowerCase()}.`,
      { type: 'regularisation', requestId: event.params.requestId, status: after.status },
    );
  }
});

// Alerts the reporting manager the moment a new leave/regularisation
// request is filed, so they know something is awaiting their decision.
// Silently does nothing if the employee has no staffDirectory entry, or it
// has no reportingManagerId set yet (see findReportingManagerUid above).
exports.onLeaveRequestCreated = onDocumentCreated('employees/{uid}/leaveRequests/{requestId}', async (event) => {
  const data = event.data.data();
  const employeeDoc = await db.collection('employees').doc(event.params.uid).get();
  const employeeId = employeeDoc.data()?.employeeId;
  const employeeName = employeeDoc.data()?.name || 'An employee';
  const managerUid = await findReportingManagerUid(employeeId);
  if (!managerUid) return;
  await notifyEmployee(
    managerUid,
    'Leave request awaiting your decision',
    `${employeeName} applied for ${data.type} (${data.dateLabel}). Review it on the admin portal.`,
    { type: 'leaveRequestPending', requestId: event.params.requestId, employeeUid: event.params.uid },
  );
});

exports.onRegularisationCreated = onDocumentCreated('employees/{uid}/regularisations/{requestId}', async (event) => {
  const data = event.data.data();
  const employeeDoc = await db.collection('employees').doc(event.params.uid).get();
  const employeeId = employeeDoc.data()?.employeeId;
  const employeeName = employeeDoc.data()?.name || 'An employee';
  const managerUid = await findReportingManagerUid(employeeId);
  if (!managerUid) return;
  await notifyEmployee(
    managerUid,
    'Regularisation request awaiting your decision',
    `${employeeName} requested regularisation for ${data.dateLabel}. Review it on the admin portal.`,
    { type: 'regularisationPending', requestId: event.params.requestId, employeeUid: event.params.uid },
  );
});

// NOTE: the 6-hourly "mark leave / regularise" reminder is already handled
// by adminRemindRegularisation in the separate HRMS web admin's own Cloud
// Functions (same Firebase project, different codebase) - intentionally
// NOT duplicated here to avoid double reminders.
