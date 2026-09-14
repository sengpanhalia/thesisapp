# thesisapp — the USEA student app

The Flutter app students use to browse and reserve textbooks from the USEA Smart
Inventory Management System, and to follow their orders. It never touches the
database: everything goes through the system's REST API (`api/v1`).

## What a student can do

- Sign in with their student number and password (`student_login.php`); the app
  keeps the signed session and sends it as `X-Student-Session`.
- Browse the books that are **on sale and have copies free** — books with none
  free are not shown (`books.php`, `categories.php`, optionally only their own
  year and semester).
- Put books in a basket and reserve them under one order code (`orders.php`).
  Lines whose book is no longer offered drop out of the basket, and quantities
  are capped at the copies free.
- Follow their orders and cancel one still waiting (`me.php`, `orders.php`).
- Read the messages the counter sends — confirmed, ready, collected, cancelled
  (`notifications.php`) — and get them as phone notifications (Firebase;
  the phone registers itself with `devices.php`).

The order then goes: Reception confirms the payment → the book room hands the
books over.

## Running it

```bash
cp dart_defines.example.json dart_defines.json   # once; fill in the values
./run.sh                                          # flutter run with those values
```

`dart_defines.json` (git-ignored) holds:

- `USEA_API_BASE_URL` — the system's `api/v1` address, e.g.
  `https://<server>/USEA_Smart_Inventory_Management_System/api/v1`
- `USEA_API_TOKEN` — the same value as `api.token` in the server's
  `config/secrets.json`

## Building for release

```bash
flutter build apk --release --dart-define-from-file=dart_defines.json
flutter build appbundle --release --dart-define-from-file=dart_defines.json
flutter build ios --release --dart-define-from-file=dart_defines.json
```

Build against the **server's** address, not a local one. Firebase needs
`android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`.

## Checks

```bash
flutter analyze
flutter build apk --debug
```

More detail on deploying the whole system: `doc/setup.md`.
