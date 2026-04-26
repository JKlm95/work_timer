# work_timer

## Firebase setup

1. Create a Firebase project and enable:
   - Authentication -> Email/Password
   - Firestore Database
2. Install FlutterFire CLI and run:
   - `dart pub global activate flutterfire_cli`
   - `flutterfire configure`
3. Keep generated files in project:
   - `lib/firebase_options.dart`
   - platform configs (`google-services.json`, `GoogleService-Info.plist`)
4. Deploy Firestore rules from `firestore.rules`.

## Data strategy

- Full history is stored in Firestore under:
  - `users/{uid}/entries/{entryId}`
- Local storage keeps:
  - current month cache for offline history
  - pending queue for offline writes
- Legacy `work_entries_v1` is migrated once (current month only) after first login.

## Manual test checklist

- Register with email/password and log in.
- Create a timer entry while online and confirm it appears in Firestore.
- Turn internet off, create entry, confirm local history still updates.
- Turn internet on, reopen history, confirm pending entry syncs to Firestore.
- Reinstall app, log in again, confirm remote history is available.
- Open old month range without internet, confirm offline fallback message and no remote fetch.