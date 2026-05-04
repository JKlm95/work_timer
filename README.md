# work_timer

## Firebase setup

1. Create a Firebase project and enable:
   - Authentication -> Email/Password (covers sign-in, sign-up, and password reset e-mails)
   - Firestore Database
   - Optional: Authentication -> Templates — customize the password-reset e-mail if you want
2. Install FlutterFire CLI and generate options (replace `YOUR_PROJECT_ID` with your Firebase project id, e.g. from the Firebase console URL):
   - `dart pub global activate flutterfire_cli`
   - `dart pub global run flutterfire_cli:flutterfire configure --yes --project=YOUR_PROJECT_ID -o lib/firebase_options.dart --overwrite-firebase-options`
   - On Windows, if `flutterfire` is not on PATH, use the `dart pub global run flutterfire_cli:flutterfire ...` form above, or add Pub’s bin folder to PATH.
3. Keep generated files in project (private repo: committing `firebase_options.dart` is normal):
   - `lib/firebase_options.dart` (used by `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` in `lib/main.dart`)
   - platform configs written by the CLI (`google-services.json`, `GoogleService-Info.plist`, etc.)
   - root `firebase.json` — FlutterFire metadata for registered platforms; do not delete if you rely on `flutterfire configure`
4. Deploy Firestore rules from `firestore.rules` (Firebase console **Firestore → Rules**, or Firebase CLI `firebase deploy --only firestore:rules` once a `firestore` section is added to `firebase.json` / project is linked).

## Data strategy

- Full history is stored in Firestore under:
  - `users/{uid}/entries/{entryId}`
- Local storage keeps:
  - current month cache for offline history
  - pending queue for offline writes
- Legacy `work_entries_v1` is migrated once (current month only) after first login.

## Manual test checklist

- Register with email/password and log in.
- On the login screen, use **Zapomniałeś hasła?** (password reset), confirm the reset e-mail arrives, set a new password, then sign in again.
- Create a timer entry while online and confirm it appears in Firestore.
- Turn internet off, create entry, confirm local history still updates.
- Turn internet on, reopen history, confirm pending entry syncs to Firestore.
- Reinstall app, log in again, confirm remote history is available.
- Open old month range without internet, confirm offline fallback message and no remote fetch.