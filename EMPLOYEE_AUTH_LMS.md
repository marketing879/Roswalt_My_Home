# Employee Login & LMS Logic — Reference for Web Admin Portal

This document describes exactly how employee authentication and LMS (Learning
Management System) tracking work in the Roswalt My Home Flutter app, so the
same backend (Firebase project) can be connected to from a separate web admin
portal.

Backend: **Firebase** (Cloud Functions v2, Firestore, Firebase Auth custom
tokens). No Firebase phone-auth or email/password auth is used for employees —
it's a fully custom email-OTP flow backed by Cloud Functions.

---

## 1. Overall flow

```
Employee enters phone number
        │
        ▼
lookupStaffByPhone (Cloud Function, callable)
  reads staffDirectory collection
  → { found: true, data: { name, employeeId, email, designation } }
        │
        ▼
Employee confirms identity ("Yes, this is me")
        │
        ▼
sendEmailOtp (Cloud Function, callable)
  generates 6-digit code, hashes it, stores in emailOtps/{email}
  writes to `mail` collection → Firebase "Trigger Email" extension sends it
        │
        ▼
Employee enters the 6-digit code
        │
        ▼
verifyEmailOtp (Cloud Function, callable)
  checks hash + expiry + attempt count in emailOtps/{email}
  on success: deletes the OTP doc, mints a Firebase custom token
  uid = "email:" + base64url(email)
        │
        ▼
Client calls FirebaseAuth.signInWithCustomToken(token)
        │
        ▼
FirebaseAuth.currentUser is now set → this is the app's "is logged in" signal
```

There is **no separate password** and **no Firebase phone-auth SMS** involved.
"Phone number" is only used as a lookup key into a staff directory; the actual
credential exchanged for a session is the emailed 6-digit code.

---

## 2. Firestore collections

### `staffDirectory` (source of truth for who *can* log in)

Read only from Cloud Functions (never exposed directly to clients). Each
document is one employee record:

| Field          | Type    | Notes                                              |
|----------------|---------|-----------------------------------------------------|
| `phone`        | string  | digits only, matched via exact `==` query           |
| `loginEnabled` | string  | literal `"true"` — must be this exact string to allow login |
| `name`         | string  |                                                       |
| `employeeId`   | string  |                                                       |
| `email`        | string  | destination for the OTP email                        |
| `designation`  | string  |                                                       |

This is the collection your web admin portal should manage — adding a row
here (with `loginEnabled: "true"`, valid `phone`, and `email`) is what grants
an employee access to the mobile app. **Note the value is the string `"true"`,
not a boolean** — match that exactly if you write to this collection from
the admin portal, since the Cloud Function query is `.where('loginEnabled', '==', 'true')`.

### `emailOtps/{email}` (ephemeral, server-only)

```
{
  codeHash: sha256(code),   // never store the raw code
  expiresAt: Timestamp,     // now + 10 minutes
  attempts: number,         // increments on wrong code, capped at 5
  createdAt: Timestamp
}
```
Deleted immediately after successful verification, or after expiry/too many
attempts on the next check.

### `employees/{uid}` (post-login employee data, client-writable by owner only)

`uid` is the custom-token uid: `"email:" + base64url(email)`.

- Firestore rule: `allow read, write: if request.auth != null && request.auth.uid == uid;` — this is a **default-deny-everything-else** ruleset (`match /{document=**} { allow read, write: if false; }`), so `staffDirectory`/`emailOtps`/`mail` are Admin-SDK-only by design, and there is no separate rule scoped to `lmsCourses` specifically — it just inherits the `employees/{uid}/**` rule since it's nested underneath.
- Subcollection `lmsCourses/{courseId}`:
  ```
  { completedLessons: string[] }  // lesson titles, arrayUnion/arrayRemove
  ```
- Subcollection used for attendance (`attendance`, referenced via
  `collectionGroup('attendance')` in the nightly finalize job) — fields
  include `date` (YYYY-MM-DD, IST), `checkIn`, `checkOut`, `totalMinutes`,
  `finalized`, `status`.

### `mail` collection

Write-only hookup for the Firebase **"Trigger Email" extension**
(`firebase/firestore-send-email`). Adding a doc here is what actually sends
the OTP email — the extension handles SMTP delivery, the app code never talks
to an SMTP server directly.

---

## 3. Cloud Functions (functions/index.js)

All are Firebase Functions v2 (`onCall` = callable functions, invoked from
the Flutter app via `FirebaseFunctions.instance.httpsCallable(name).call(data)`).
A web admin portal calling these needs the Firebase Admin/Web SDK configured
against the same project, or can call the callable-function HTTPS endpoint
directly with an ID token.

### `sendEmailOtp({ email })`
- Normalizes email (trim + lowercase).
- Cooldown: rejects if a code was created <60s ago (`resource-exhausted`).
- Generates 6-digit numeric code, hashes with SHA-256, stores in
  `emailOtps/{email}` with a 10-minute TTL.
- Writes a doc to `mail` with subject/text/html for the Trigger Email
  extension to send.
- Returns `{ success: true }`.

### `verifyEmailOtp({ email, code })`
- Loads `emailOtps/{email}`.
- Errors: `not-found` (no code requested), `deadline-exceeded` (expired,
  and deletes the doc), `resource-exhausted` (5+ wrong attempts, deletes
  the doc), `permission-denied` (wrong code, increments `attempts`).
- On match: deletes the OTP doc, mints a custom token via
  `getAuth().createCustomToken(uid, { email })` where
  `uid = 'email:' + Buffer.from(email).toString('base64url')`.
- Returns `{ success: true, token }`.

### `lookupStaffByPhone({ phone })`
- Strips non-digits from `phone`.
- Queries `staffDirectory` where `phone == phone` and `loginEnabled == 'true'`, limit 1.
- Returns `{ found: false }` or `{ found: true, data: { name, employeeId, email, designation } }`.
- This is the only server-side gate on who can start the login flow — a
  directory entry without `loginEnabled: "true"` cannot log in even if
  looked up.

### `finalizeDailyAttendance` (scheduled, not callable)
- Runs `30 0 * * *` Asia/Kolkata (00:30 IST nightly).
- Finds all `attendance` subcollection docs (via `collectionGroup`) for
  yesterday's date where `finalized == false`.
- Locks them (`finalized: true`), backfills `totalMinutes` for anyone who
  checked in but never checked out, sets `autoClosedWithoutCheckOut` in
  that case.
- Not directly relevant to login/LMS, but shows the attendance data shape
  your admin portal may also want to read.

---

## 4. Client-side session persistence (Flutter — for parity reference)

`lib/services/otp_email_service.dart`:
- After `verifyCode()` succeeds, signs in with the custom token and caches
  the verified email in `SharedPreferences` (`verified_email`), plus
  `verified_employee_name` / `_id` / `_designation` (cached separately since
  a custom-token Firebase user has no profile fields of its own).
- `isVerified` is simply `FirebaseAuth.instance.currentUser != null`.
- On relaunch (`session_wrapper.dart`), Firebase Auth's own persisted
  session restores `currentUser` automatically; the cached name/id/designation
  are read back from SharedPreferences to reconstruct the profile without a
  fresh directory lookup.
- `signOut()` clears both the Firebase Auth session and the cached prefs.

For a web admin portal, the equivalent would be: use Firebase Auth's web SDK
`onAuthStateChanged`, and store the same admin's profile fields (from your
own `admins`/`staffDirectory` doc) in your own session/store rather than
SharedPreferences.

---

## 5. LMS logic

**Course catalog is hardcoded client-side** (`lib/providers/employee_lms_provider.dart`,
`lmsCatalog` constant) — there is no Firestore collection defining courses,
titles, or lesson lists today. Only **completion progress** is persisted
server-side, per employee:

- Path: `employees/{uid}/lmsCourses/{courseId}`
- Field: `completedLessons: string[]` (lesson title strings, must match the
  hardcoded lesson names exactly)
- Toggling a lesson does `arrayUnion`/`arrayRemove` on that field.
- Progress % = `completedLessons.length / course.lessons.length`.
- Status: `Not Started` (0%), `In Progress` (0–100%), `Completed` (100%).

Current hardcoded courses (`id`, title, lesson count):
1. `sales-onboarding` — Sales Onboarding (5 lessons)
2. `product-knowledge` — Product Knowledge (4 lessons)
3. `compliance-rera` — Compliance & RERA Basics (4 lessons)
4. `customer-service` — Customer Service Excellence (4 lessons)

No quizzes or certificates exist — completion is lesson-checkbox only.

> Note: there's also a **separate, unrelated "CP Training" module** for Channel
> Partners (`lib/screens/partner/cp_training_screen.dart`, `partner_shell.dart`).
> It's a different feature for a different user type — don't conflate it with
> employee LMS when searching the codebase for "training".

### Implication for the web admin portal

If the admin portal needs to **manage** courses (create/edit courses,
lessons, assign to employees, see completion), you'll need to:
1. Introduce a real `lmsCourses` (or similar) top-level Firestore collection
   as the source of truth for course/lesson definitions — this doesn't exist
   yet, only the per-employee completion subcollection does.
2. Keep writing completion state to `employees/{uid}/lmsCourses/{courseId}`
   in the same shape (`completedLessons: string[]`) so the existing mobile
   app keeps working, or migrate both sides together.
3. Firestore rules currently only allow the employee who owns `uid` to
   read/write their own `employees/{uid}/*` subtree, and deny all other
   direct client access (everything else is server-only, via Admin SDK in
   Cloud Functions). An admin portal will need its own Cloud
   Function/Admin-SDK backend (or custom claims + adjusted rules) to read
   *other* employees' progress — the current rules won't allow an "admin"
   browser session to query across all employees directly.

### Firestore indexes (`firestore.indexes.json`)

Two composite indexes exist, both backing the queries above:
- `attendance` (collection group) on `date` + `finalized` — backs `finalizeDailyAttendance`.
- `staffDirectory` (collection) on `phone` + `loginEnabled` — backs `lookupStaffByPhone`.

No index exists for `lmsCourses`. If the admin portal needs to query LMS
completion **across all employees** (e.g. `collectionGroup('lmsCourses')` for
reporting), you'll need to add a new composite index for that.

### Relevant Firebase/auth package versions (`pubspec.yaml`)

```yaml
firebase_core: ^4.11.0
firebase_auth: ^6.5.3
cloud_functions: ^6.3.5
cloud_firestore: ^6.7.1
```
Match these (or compatible) versions in the web admin portal's Firebase Web
SDK setup to avoid API surface mismatches, especially for custom-token sign-in.

---

## 6. Building the web admin portal — practical notes

- **Same Firebase project**: use the same Firebase config (apiKey, projectId,
  etc.) as the Flutter app so you're reading/writing the same
  `staffDirectory` / `employees` / `emailOtps` data.
- **Admin login is a separate concern**: the OTP flow above is designed for
  *employee* self-login on mobile. For an admin portal, you likely want a
  distinct admin auth path (e.g. Firebase email/password or Google sign-in
  for internal staff), gated by custom claims (`role: 'admin'`) or a
  separate `admins` collection — reuse `verifyEmailOtp`'s pattern only if you
  want admins to log in the same passwordless way.
- **Direct Firestore access from the browser will be blocked** for anything
  outside `employees/{own-uid}` per current rules — the admin portal will
  need its own Cloud Functions (callable or HTTPS) using the Admin SDK to:
  - list/search `staffDirectory` (create/edit employees, toggle `loginEnabled`)
  - read all employees' `lmsCourses` completion for reporting
  - manage a real course-catalog collection if you build one
- **Custom token uid convention**: if the admin portal ever needs to look up
  or write to a specific employee's `employees/{uid}` doc, remember
  `uid = 'email:' + base64url(email)` — this is the only way to compute it
  since it isn't stored anywhere as a separate field.
- **No role/custom claims exist anywhere today** — `session_wrapper.dart`
  decides "is this an employee session" purely from a locally cached
  SharedPreferences value (`cachedEmployeeName`), not from anything
  server-verifiable. `verifyEmailOtp`'s `createCustomToken(uid, { email })`
  sets no role claim. If the admin portal needs a trustworthy, server-side
  "this uid is an employee" check (e.g. for its own Firestore rules or
  Cloud Function auth checks), add
  `admin.auth().setCustomUserClaims(uid, { role: 'employee' })` inside
  `verifyEmailOtp` after the custom token is minted, rather than relying on
  the client-side cache pattern the mobile app uses.
