# Multivexa AI

An Android-first creative studio connecting image, video, and music generation to KIE.

## Deploy the KIE gateway

1. Create a web service on Render from this repository.
2. Set **Root Directory** to `server` and use the included Dockerfile.
3. Add `KIE_API_KEY` as a secret environment variable in Render. Never put this key in Flutter code or GitHub.
4. Set `KIE_IMAGE_MODEL`, `KIE_VIDEO_MODEL`, and `KIE_MUSIC_MODEL` to model IDs enabled in your KIE account. The example values in `.env.example` are placeholders and may need to be changed to the exact model IDs shown by KIE.
5. After deployment, check `https://YOUR-SERVICE.onrender.com/health`. It should return JSON showing the gateway is online.

The gateway provides `POST /api/generate` and `GET /api/tasks/:taskId`. The API key remains server-side. KIE usage may incur charges according to your KIE plan.

## Build the Android APK

GitHub Actions builds a release APK and uploads it as the `multivexa-android-release` artifact. For generation to work on a real phone, build with your deployed gateway URL:

```sh
flutter pub get
flutter build apk --release --dart-define=MULTIVEXA_API_URL=https://YOUR-SERVICE.onrender.com
```

To use this URL in GitHub Actions, add a repository variable named `MULTIVEXA_API_URL` containing the HTTPS gateway URL, then pass it to the build command as `--dart-define=MULTIVEXA_API_URL=${{ vars.MULTIVEXA_API_URL }}`.

## Current limitations

The sign-in/register page is still a prototype, and credits/history are stored in memory only. Production use needs real authentication, persistent user records, server-side credit validation, and rate limiting. A successful task submission means KIE accepted a job; it does not mean the media has finished rendering yet.
