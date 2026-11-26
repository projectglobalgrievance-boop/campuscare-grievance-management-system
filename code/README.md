# CampusCare — code

```
code/
  mac/run.sh          one command to run everything on a Mac
  windows/run.bat     one command to run everything on Windows
  launcher/           what those two commands start (run.py) and the app
                      build they install (CampusCare-local.apk)
  mobile/             the Android app — Flutter (student and admin sides)
  ai-service/         the AI service — Python, FastAPI: classification,
                      priority, duplicates, routing, aliases, geofence check
  firebase/           database security rules, indexes, emulator settings
  keys/               the one place for YOUR keys; empty as delivered
  render.yaml         settings for hosting the AI service on Render
```

The guides in `../guidelines/` explain all of this in full. This page is the
short version.

## Run it

| | Command (from the project folder) |
|---|---|
| Mac | `bash code/mac/run.sh` |
| Windows | `code\windows\run.bat` (or double-click it) |

The command downloads its tools into `code/.tools` (about 3 GB, first run
only; nothing is installed on the computer itself), starts a local database,
login service and the AI service, opens an Android phone on your screen,
installs the app and prints **Local host is ready**.

- Logins: `student@demo.com`, `admin@demo.com`, password `password123`.
  All accounts: `../guidelines/03-access/`.
- Database viewer: http://localhost:4000 — AI service: http://localhost:8000/docs
- Stop: `Ctrl+C` in the window, or close the phone window.
- Logs: `code/.tools/logs/`.
- Problems: `../guidelines/02-how-to-run/`.

## Your own Firebase and hosting

The project is delivered with no keys. To put it online:

1. `../guidelines/04-keys/` — what each key is.
2. `../guidelines/05-firebase/` — create your Firebase project, fill in
   `keys/keys.env`, add `keys/serviceAccount.json`.
3. `../guidelines/06-hosting/` — host the AI service, build the app.

Run a project script against your own Firebase project:

```
bash code/mac/run.sh cloud scripts/seed.py
bash code/mac/run.sh cloud scripts/make_admin.py person@college.edu
```

On Windows the same lines begin `code\windows\run.bat cloud`.

## Building the app

Needs Flutter 3.44 or newer and Android Studio.

For real phones, with your keys:

```
cd code/mobile
flutter build apk --release --target-platform android-arm,android-arm64 --dart-define-from-file=../keys/keys.env
```

For the local run, after changing the app (this replaces the copy the run
command installs):

```
cd code/mobile
flutter build apk --release --target-platform android-arm64,android-x64 --dart-define=USE_EMULATOR=true
cp build/app/outputs/flutter-apk/app-release.apk ../launcher/CampusCare-local.apk
```

Changes to `ai-service/` and `firebase/firestore.rules` need no build: run
the command again.

## Tests

```
cd code/ai-service && python -m pytest      # 44 tests
cd code/mobile && flutter test              # 68 tests
```
