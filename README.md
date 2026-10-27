# Multivexa AI

Android creative studio using KIE for image/video/music generation and Supabase for authentication and persistent creation history.

## Supabase setup
1. In Supabase, copy your **Project URL** and **publishable key** (legacy anon key is also client-safe).
2. In GitHub **Settings → Secrets and variables → Actions → Variables**, add `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`.
3. Run `supabase/schema.sql` in Supabase **SQL Editor** to create the history table and Row Level Security policies.
4. Ensure Email is enabled under Supabase **Authentication → Providers**. If email confirmation is enabled, new users must confirm their email before signing in.
5. Never put a Supabase secret/service-role key in the mobile app or repository. The app uses only the publishable key and relies on RLS.

The app supports Supabase email/password registration and sign-in, session restoration, and per-user saved generation history.

## KIE gateway deployment
Deploy this repository to Render as a web service with **Root Directory** set to `server`. Set `KIE_API_KEY` as a Render secret environment variable and set `KIE_IMAGE_MODEL`, `KIE_VIDEO_MODEL`, and `KIE_MUSIC_MODEL` to valid model IDs enabled for your KIE account. Check `/health` after deployment. Never put the KIE key in the app.

## Flutterwave credit top-ups
1. Run the updated `supabase/schema.sql` in Supabase SQL Editor. It adds the wallet and idempotent payment ledger.
2. In Render, set these server-only environment variables on the `server` service:
   - `FLW_SECRET_KEY`: Flutterwave secret key (use test credentials first).
   - `PUBLIC_API_URL`: the deployed HTTPS API origin, e.g. `https://your-service.onrender.com` (no trailing slash).
   - `SUPABASE_URL`: the Supabase project URL.
   - `SUPABASE_PUBLISHABLE_KEY`: the Supabase publishable/anon key, used to validate signed-in users.
   - `SUPABASE_SERVICE_ROLE_KEY`: Supabase service-role key, server-side only; never add it to Flutter, GitHub commits, or client build variables.
3. Deploy the server, then build the app with `MULTIVEXA_API_URL` set to the same HTTPS Render origin.
4. The app offers ₦1,500 / 100 credits, ₦5,000 / 300 credits, ₦10,000 / 800 credits, and ₦13,600 / 1,000 credits. Payment is credited only after the backend verifies the Flutterwave transaction.

Never commit or paste Flutterwave secret keys into the app or GitHub source. If a secret key has already been shared in a chat, rotate it in the Flutterwave dashboard before deploying.

## Build APK
Add GitHub Actions variables:
- `MULTIVEXA_API_URL`: deployed KIE gateway HTTPS URL
- `SUPABASE_URL`: Supabase project URL
- `SUPABASE_PUBLISHABLE_KEY`: Supabase publishable/anon key

Push to `main` or manually run **Actions → Build Multivexa Android APK**. The workflow builds and uploads `multivexa-android-release`.

Local build:
```sh
flutter pub get
flutter build apk --release --dart-define=MULTIVEXA_API_URL=https://YOUR-SERVICE.onrender.com --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

## Limitations
Paid top-ups are stored in the Supabase wallet and loaded on app startup. Generation deductions are still demo-only and are not yet enforced server-side; enforce spending and quotas on the backend before production. A KIE task submission does not mean the media has finished rendering.
