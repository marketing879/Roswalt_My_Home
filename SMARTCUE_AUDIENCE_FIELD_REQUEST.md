# SmartCue: "audience" field on training videos — ✅ ALREADY LIVE

**Status: done, shipped to production.** This is no longer an open request —
keeping this file only as a reference for the exact shape that's live today.

## What's live

`GET https://api.roswaltsmartcue.com/api/training-videos` now returns an
`audience` field on every video, and accepts an optional query filter:

```
GET /api/training-videos                 -> all videos (used by SmartCue's own admin list view)
GET /api/training-videos?audience=cp     -> Channel Partner videos only
GET /api/training-videos?audience=employee -> Employee videos only
```

Field values are **binary** — `"cp" | "employee"` — there is no `"all"`
option. A video is tagged for exactly one app. (This was a deliberate call:
the original spec proposed a third `"all"` value so one video could target
both apps at once; decided against adding it, so every video picks one
audience.)

- **Default:** any video without the field set is treated as `"cp"` — this
  matches the one video that existed before this change shipped, which was
  a CP video and has been explicitly backfilled to `audience: "cp"` in the
  database (not left relying on a live default, since the default only
  applies to new document creation, not existing rows).
- **Upload form:** SmartCue's Training Videos panel (Aziz Khan's login only)
  has an "Audience — which app sees this" dropdown, defaulting to Channel
  Partner App.

## Response shape, for reference

```json
{
  "_id": "6a855210e5832cb7aa0ebb17",
  "title": "Meta and Google Digital Ads Training",
  "description": "",
  "category": "softskills",
  "instructor": "",
  "duration": "31:03",
  "videoUrl": "https://api.roswaltsmartcue.com/api/attachments/....mp4",
  "thumbnailUrl": "https://api.roswaltsmartcue.com/api/attachments/....png",
  "createdBy": "aziz.khan@roswalt.com",
  "createdAt": "...",
  "updatedAt": "...",
  "__v": 0,
  "audience": "cp"
}
```

## What's left on the Roswalt My Home side

`cp_training_screen.dart` and `employee_training_videos_screen.dart` still
need to actually call the filtered endpoints (`?audience=cp` /
`?audience=employee`) instead of the unfiltered one — that wasn't done
because both files were mid-rewrite (uncommitted, active work building a
separate Firebase-based employee video system) at the time this shipped.
Check current state of both screens before wiring this in, since the
employee screen in particular may no longer read from SmartCue at all.
