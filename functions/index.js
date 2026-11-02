const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onDocumentUpdated, onDocumentCreated, onDocumentWritten } = require('firebase-functions/v2/firestore');
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

// Field Duty is specifically about the TL relationship (not HOD fallback) -
// a sourcing/field employee's TL is who watches their live route.
async function findTlUid(employeeId) {
  if (!employeeId) return null;
  const mapSnap = await db.collection('reportingMap').doc(employeeId).get();
  const tlId = mapSnap.data()?.tlId;
  return tlId ? findUidByEmployeeId(tlId) : null;
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

// Training videos are uploaded entirely on SmartCue's side (Aziz Khan's
// login there), not through this app — so "new video added" can only be
// detected by polling SmartCue's own catalog, not a Firestore trigger.
// Every 30 minutes: fetches the same feed the Employee Training Videos
// screen reads, diffs it against the last-seen id list (adminMeta/
// smartcueSeenVideos), and notifies every employee for anything new.
//
// CAVEAT: SmartCue's /api/training-videos has no audience field yet (see
// employee_training_videos_screen.dart), so this will also fire for
// videos meant only for CP until that's added upstream.
exports.checkNewTrainingVideos = onSchedule(
  { schedule: 'every 30 minutes', timeZone: 'Asia/Kolkata' },
  async () => {
    let videos;
    try {
      const res = await fetch('https://api.roswaltsmartcue.com/api/training-videos');
      if (!res.ok) return;
      const body = await res.json();
      videos = body.data || [];
    } catch (e) {
      console.error('checkNewTrainingVideos fetch failed', e);
      return;
    }

    const seenDoc = await db.collection('adminMeta').doc('smartcueSeenVideos').get();
    const seenIds = new Set(seenDoc.data()?.ids || []);
    const newVideos = videos.filter((v) => v._id && !seenIds.has(v._id));

    if (newVideos.length > 0) {
      const employeesSnap = await db.collection('employees').get();
      for (const v of newVideos) {
        await Promise.all(employeesSnap.docs.map((doc) => notifyEmployee(
          doc.id,
          'New Training Video',
          `"${v.title || 'A new training video'}" has been added to Training Videos.`,
          { type: 'trainingVideo', videoId: v._id },
        )));
      }
    }

    await db.collection('adminMeta').doc('smartcueSeenVideos').set({
      ids: videos.map((v) => v._id).filter(Boolean),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
);

// Notifies the employee's TL the moment they start Field Duty
// (employees/{uid}/fieldDuty/status.active flips to true). Fires on both
// the very first "start" (doc creation) and every later re-start (update).
exports.onFieldDutyStarted = onDocumentWritten('employees/{uid}/fieldDuty/status', async (event) => {
  const before = event.data.before?.data();
  const after = event.data.after?.data();
  if (!after?.active) return;
  if (before?.active === true) return; // already notified for this session

  const employeeDoc = await db.collection('employees').doc(event.params.uid).get();
  const employeeId = employeeDoc.data()?.employeeId;
  const employeeName = employeeDoc.data()?.name || 'An employee';
  const tlUid = await findTlUid(employeeId);
  if (!tlUid) return;

  await notifyEmployee(
    tlUid,
    'Field Duty started',
    `${employeeName} has started Field Duty. Open My Team to view their live route.`,
    { type: 'fieldDutyStarted', employeeUid: event.params.uid },
  );
});

// For a TL: everyone mapped to them via reportingMap.tlId. For an HOD: the
// org chart's broader reporting line under them - both people mapped
// directly via reportingMap.hodId (no TL assigned yet, or HOD-direct
// reports) AND everyone under each of the HOD's own TLs (reportingMap.tlId
// pointing at one of those TLs), so an HOD sees their whole department, not
// just whoever has no TL. Poll-based (no live listener) since this crosses
// between two different employees' data - deliberately kept server-side
// rather than opening up direct cross-user Firestore reads.
exports.listMyFieldDutyTeam = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'You must be signed in.');
  const myDoc = await db.collection('employees').doc(request.auth.uid).get();
  const myEmployeeId = myDoc.data()?.employeeId;
  if (!myEmployeeId) return { team: [] };

  const docsById = new Map();
  const directTl = await db.collection('reportingMap').where('tlId', '==', myEmployeeId).get();
  for (const doc of directTl.docs) docsById.set(doc.id, doc);

  const directHod = await db.collection('reportingMap').where('hodId', '==', myEmployeeId).get();
  for (const doc of directHod.docs) docsById.set(doc.id, doc);

  // Expand to each of the HOD's direct reports' own reports, so an HOD sees
  // the full department (employee -> TL -> HOD), not only employees with no
  // TL in between.
  for (const tlEmployeeId of directHod.docs.map((d) => d.id)) {
    const subReports = await db.collection('reportingMap').where('tlId', '==', tlEmployeeId).get();
    for (const doc of subReports.docs) docsById.set(doc.id, doc);
  }

  const team = [];
  for (const [employeeId, doc] of docsById) {
    if (employeeId === myEmployeeId) continue;
    const uid = await findUidByEmployeeId(employeeId);
    if (!uid) continue;
    const statusSnap = await db.collection('employees').doc(uid).collection('fieldDuty').doc('status').get();
    const s = statusSnap.data();
    team.push({
      employeeId,
      uid,
      name: doc.data().chartName || employeeId,
      active: s?.active === true,
      currentLat: s?.currentLat ?? null,
      currentLng: s?.currentLng ?? null,
      startedAt: s?.startedAt ? s.startedAt.toDate().toISOString() : null,
    });
  }
  return { team };
});

// For a TL: the live route (current position + trail) of one of their
// direct reports. Verifies the caller is actually that person's mapped TL
// before returning anything - this is the enforcement point, since the
// underlying employees/{uid}/fieldDuty data isn't directly client-readable
// cross-user (see firestore.rules).
exports.getFieldDutyTrail = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'You must be signed in.');
  const targetUid = request.data?.uid;
  if (!targetUid) throw new HttpsError('invalid-argument', 'uid is required.');

  const myDoc = await db.collection('employees').doc(request.auth.uid).get();
  const myEmployeeId = myDoc.data()?.employeeId;
  const targetDoc = await db.collection('employees').doc(targetUid).get();
  const targetEmployeeId = targetDoc.data()?.employeeId;

  const mapSnap = await db.collection('reportingMap').doc(targetEmployeeId).get();
  const targetTlId = mapSnap.data()?.tlId;
  const targetHodId = mapSnap.data()?.hodId;
  const isMyDirectReport = targetTlId === myEmployeeId || targetHodId === myEmployeeId;
  // An HOD can also watch anyone under one of their own TLs (the same
  // department-expansion listMyFieldDutyTeam applies).
  const isUnderMyTl = targetTlId
    ? (await db.collection('reportingMap').doc(targetTlId).get()).data()?.hodId === myEmployeeId
    : false;
  if (!targetEmployeeId || (!isMyDirectReport && !isUnderMyTl)) {
    throw new HttpsError('permission-denied', "You are not this employee's TL or HOD.");
  }

  const statusDoc = db.collection('employees').doc(targetUid).collection('fieldDuty').doc('status');
  const statusSnap = await statusDoc.get();
  const trailSnap = await statusDoc.collection('trail').orderBy('recordedAt').limitToLast(500).get();

  return {
    active: statusSnap.data()?.active === true,
    currentLat: statusSnap.data()?.currentLat ?? null,
    currentLng: statusSnap.data()?.currentLng ?? null,
    startedAt: statusSnap.data()?.startedAt ? statusSnap.data().startedAt.toDate().toISOString() : null,
    trail: trailSnap.docs.map((d) => ({ latitude: d.data().latitude, longitude: d.data().longitude })),
  };
});

// Mirrors a CP "Log Walk-In" tag into our own Firestore and notifies the
// Sourcing Manager mapped to that CP - keyed by MahaRERA (the CP's actual
// registered identity, same one already used for CP login and already sent
// to SFDC with every walk-in). The CP app has no Firebase Auth session at
// all (SFDC-token only, like the rest of the CP flow), so this is a plain
// onCall with no request.auth check - same trust model as sendEmailOtp.
// The mapping itself (cpSourcingMap/{mahaRERA} -> smEmployeeId) is
// maintained on the web admin side, populated from SFDC's own CP-to-SM
// records - not built here, this just reads it.
exports.submitCPWalkInTag = onCall(async (request) => {
  const d = request.data || {};
  const mahaRERA = String(d.mahaRERA || '').trim();
  if (!mahaRERA) throw new HttpsError('invalid-argument', 'mahaRERA is required.');

  const docRef = await db.collection('cpWalkIns').add({
    mahaRERA,
    cpFirm: d.cpFirm || '',
    cpName: d.cpName || '',
    project: d.project || '',
    clientName: d.clientName || '',
    clientPhone: d.clientPhone || '',
    configuration: d.configuration || '',
    budget: d.budget || '',
    status: d.status || 'Hot',
    submittedAt: FieldValue.serverTimestamp(),
  });

  const mapSnap = await db.collection('cpSourcingMap').doc(mahaRERA).get();
  const smEmployeeId = mapSnap.data()?.smEmployeeId;
  if (smEmployeeId) {
    const smUid = await findUidByEmployeeId(smEmployeeId);
    if (smUid) {
      await docRef.set({ smEmployeeId }, { merge: true });
      await notifyEmployee(
        smUid,
        'New CP Walk-In tagged to you',
        `${d.cpName || d.cpFirm || 'A channel partner'} tagged a walk-in: ${d.clientName || 'a client'} (${d.project || 'no project given'}).`,
        { type: 'cpWalkInTagged', walkInId: docRef.id },
      );
    }
  }

  return { success: true };
});

// For a Sourcing Manager: lists every CP walk-in tagged to them
// (cpWalkIns.smEmployeeId == their own employeeId), newest first.
exports.listMyTaggedWalkIns = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'You must be signed in.');
  const myDoc = await db.collection('employees').doc(request.auth.uid).get();
  const myEmployeeId = myDoc.data()?.employeeId;
  if (!myEmployeeId) return { walkIns: [] };

  const snap = await db.collection('cpWalkIns')
    .where('smEmployeeId', '==', myEmployeeId)
    .orderBy('submittedAt', 'desc')
    .limit(100)
    .get();

  return {
    walkIns: snap.docs.map((d) => {
      const w = d.data();
      return {
        id: d.id, cpFirm: w.cpFirm, cpName: w.cpName, project: w.project,
        clientName: w.clientName, clientPhone: w.clientPhone, configuration: w.configuration,
        budget: w.budget, status: w.status,
        submittedAt: w.submittedAt ? w.submittedAt.toDate().toISOString() : null,
      };
    }),
  };
});
