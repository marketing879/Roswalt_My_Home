# Field Duty: live map for web admin monitoring

**Why:** Employees can now toggle "Field Duty" in the mobile app, sharing a
live GPS trail with their mapped TL (via `reportingMap.tlId`). The TL can
already watch this in the mobile app itself ("My Team" screen). This spec
is for surfacing the same thing on the web admin, for broader monitoring
(e.g. an ops/HR view across many employees at once, not just one TL's
direct reports).

## Where the data lives (Firestore, same project: `roswalt-my-home`)

```
employees/{uid}/fieldDuty/status
  active: boolean
  startedAt: timestamp
  endedAt: timestamp | null
  currentLat: number
  currentLng: number
  updatedAt: timestamp

employees/{uid}/fieldDuty/status/trail/{autoId}
  latitude: number
  longitude: number
  recordedAt: timestamp
```

- `{uid}` is the same Firebase Auth uid scheme used everywhere else
  (`email:<base64url(email)>`). Cross-reference with `employees/{uid}.employeeId`
  and `employees/{uid}.name` to get the real employee ID / display name.
- `trail` grows for the duration of one active session — order by
  `recordedAt` to draw a polyline.
- There's no `"all"`/broadcast flag — an active session just means
  `active == true` right now, for that specific `uid`.

## Suggested web admin build

Since the web admin backend uses the Firebase Admin SDK (bypasses Firestore
security rules entirely, unlike the mobile app), this is straightforward:

1. Query `collectionGroup('status')` where `active == true` (or iterate
   known employee uids) to find everyone currently on Field Duty.
2. For each, resolve their employeeId/name from the parent `employees/{uid}`
   doc, and optionally their TL from `reportingMap/{employeeId}.tlId`.
3. **Show each employee's map individually, not combined.** This should be
   a list/grid of currently-active employees (name, employeeId, since-when)
   — clicking one opens *that person's own map*, scoped to just their
   `currentLat/currentLng` and their own `trail`. Don't plot multiple
   employees' pins together on one shared map — each person's route is
   viewed on its own, one at a time, the same way the mobile app's "My
   Team" screen already does it (tap a team member → see only their route).
4. Since this is server/admin-side, you can use a **real-time Firestore
   listener** (`onSnapshot`) instead of polling — no cross-user security
   constraint applies here the way it does for the mobile app's TL-to-TL
   view (which deliberately goes through server-verified Cloud Functions
   instead of a raw cross-user Firestore read).

## What this does NOT change

Nothing on the mobile app side needs to change for this — the data is
already being written today. This is purely a new consumption path on the
web admin.
