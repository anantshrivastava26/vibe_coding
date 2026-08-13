# LifeLoop Backend

Express + Neon Postgres + Firebase Admin service powering the LifeLoop disaster
alert application.

## Responsibilities

- Verifies Firebase Auth ID tokens sent by the Flutter client
- Persists users, device tokens, disaster events, alerts and delivery status in Neon
- Runs the **alert engine**: matches a disaster event's affected radius against every
  user's saved location, creates alerts only for those inside it, and pushes an FCM
  notification to each affected device
- Prevents duplicate alerts at two levels (see below)

## Local setup

```bash
cd backend
npm install
cp .env.example .env      # then fill in the values
npm run migrate           # creates tables + seeds emergency instructions
npm run dev
```

`.env` values:

| Variable | Purpose |
| --- | --- |
| `DATABASE_URL` | Neon Postgres connection string |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | Path to the Admin SDK key (local dev only) |
| `PORT` | Defaults to 3000 |

The Firebase Admin private key lives at `backend/serviceAccountKey.json` and is
gitignored — it must never be committed.

## Promoting an admin

Roles default to `user`. After registering in the app, promote yourself:

```bash
npm run make-admin -- you@example.com
```

Only admins can reach `/api/admin/*` and the in-app admin dashboard.

## Deploying to Railway

1. Push this repository to GitHub.
2. Create a Railway service from the repo and set **Root Directory** to `backend`.
3. Add these variables (Railway injects `PORT` itself):

   | Variable | Value |
   | --- | --- |
   | `DATABASE_URL` | Your Neon connection string |
   | `FIREBASE_SERVICE_ACCOUNT_JSON` | The full contents of `serviceAccountKey.json` (raw JSON or base64) |

   Do **not** set `FIREBASE_SERVICE_ACCOUNT_PATH` on Railway — the key file is
   gitignored and won't exist there. `src/config/firebaseAdmin.js` reads the
   credential from `FIREBASE_SERVICE_ACCOUNT_JSON` when present and falls back to
   the local file only for development.

4. After deploying, point the Flutter app at the Railway URL by editing
   `lib/config.dart`.

The schema is already migrated against Neon, so no post-deploy migration step is
needed. To re-run it manually: `npm run migrate`.

## API

| Method | Route | Auth | Purpose |
| --- | --- | --- | --- |
| GET | `/health` | – | Liveness check |
| POST | `/api/auth/sync` | Firebase token | Upsert the local user row after sign-in |
| GET | `/api/users/me` | User | Current profile |
| PUT | `/api/users/me/location` | User | Save alert location |
| POST | `/api/users/me/device-token` | User | Register an FCM device token |
| GET | `/api/users/me/alerts` | User | Alert history |
| POST | `/api/admin/disasters/simulate` | Admin | Create an event and dispatch alerts |
| GET | `/api/admin/disasters` | Admin | All recorded events |
| GET | `/api/admin/users` | Admin | All users |
| GET | `/api/admin/notifications` | Admin | Notification delivery status |

## Duplicate-alert prevention

Two database-level guarantees, so retries and repeated feed polls are safe:

- `disaster_events` has `UNIQUE (source, external_id)` — the same upstream event is
  only ever ingested once.
- `alerts` has `UNIQUE (event_id, user_id)` — a user can never receive two alerts for
  the same event.

Both inserts use `ON CONFLICT DO NOTHING`, so re-processing an event is a no-op
rather than an error.

## Notification sound

`src/services/fcm.js` sends every push on the `disaster_alert_channel` Android
channel with the `disaster_alert` sound. That channel and its raw resource
(`android/app/src/main/res/raw/disaster_alert.m4a`) are declared on the Flutter side,
so alerts use the custom tone whether the app is in the foreground, background, or
closed.
