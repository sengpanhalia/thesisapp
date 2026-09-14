# Production Setup Guide

Step-by-step instructions for deploying the **USEA Smart Inventory Management System** backend and the **thesisapp** Flutter mobile application to production.

---

## Table of Contents

1. [Backend System (PHP + MySQL)](#1-backend-system-php--mysql)
2. [Mobile App (Flutter)](#2-mobile-app-flutter)
3. [Post-Deployment Checklist](#3-post-deployment-checklist)

---

## 1. Backend System (PHP + MySQL)

### 1.1 Prerequisites

The server must have the following installed and running:

- **PHP 8.2 or newer** with extensions: `pdo_mysql`, `mbstring`, `zip`, `curl`
- **The university's `usea_main` database** — MySQL 8.0.31 on the server
  (MariaDB 10.x also works)
- **Apache** with `.htaccess` support

The web server process user must have write access to:
- `config/`
- `data/`
- `database/backups/`
- `public/uploads/`
- `storage/exports/`

On XAMPP/macOS the web user is usually `daemon`. On Linux it is usually `www-data` or `apache`.

### 1.2 Deploy Files

Copy the entire `USEA_Smart_Inventory_Management_System/` directory to the server's document root or any subdirectory served by Apache.

The application derives its own base URL from the running script, so **no path editing is required** when moving to a different folder name.

### 1.3 Database Configuration

1. Copy the example secrets file:

   ```bash
   cp config/secrets.example.json config/secrets.json
   ```

2. Edit `config/secrets.json` with your production database credentials and production API details. At minimum, fill in:

   ```json
   {
     "db": {
       "host": "localhost",
       "port": 3306,
       "socket": "",
       "name": "usea_main",
       "user": "usea_inv",
       "password": "your_secure_password_here"
     },
     "api": {
       "token": "a_long_random_token_at_least_16_characters",
       "token_user": "bivc",
       "scope": "",
       "base_url": "https://your-domain.com/USEA_Smart_Inventory_Management_System/api/v1"
     },
     "telegram": {
       "bot_token": "your_telegram_bot_token_here"
     },
     "api_signing_secret": "your_api_signing_secret_here"
   }
   ```

   `api.token` is the one token the Telegram bot and the mobile app use; there is
   no screen that issues tokens. Push notifications also need a Firebase service
   account key at `config/firebase_service_account.json`.

3. Open `login.php`. If the database cannot be reached, or is missing this
   system's tables, the page says so and names the SQL file to run.

### 1.4 Upgrade the Schema

The database manager backs up `usea_main`, then opens phpMyAdmin → `usea_main`
→ SQL, and pastes and runs:

```
doc/New Table and Field to Add to Server/Schema of New Table and Field.sql
```

It adds 11 new tables, 85 new columns and 35 indexes, then fills in only the
new columns. It changes no existing column, value or trigger, runs on MySQL 8
and MariaDB, and is safe to run twice. `New Table and Field.md` beside it lists
every table and column with its purpose.

### 1.5 Bootstrap Administrators

`config/access.php` lists the usernames who must be able to sign in before
anyone can grant roles through the interface (`bivc`, `bunseang`). They can sign
in with their existing university password straight after the schema upgrade —
their ADMIN role is filled in by the SQL, and also written at their first
sign-in. They then give everyone else a role in Settings ▸ Users.

Nothing is created: roles are only ever granted to accounts the university
already has.

### 1.6 Enable Production Mode

Edit `config/app.json` and set:

```json
{
  "environment": "production"
}
```

This disables on-screen error messages. Errors are written to the web server log with a short reference code the user can quote. **Never deploy with this left on `development`** — that setting exposes file paths and internal messages to visitors.

### 1.7 Verify Installation

Sign in as an administrator and open each system once (Stock, Book, Reception,
Asset, Settings). With the bot switched on, Settings ▸ AI & Telegram should say
"Bot is running", and this should end with "All required checks passed":

```bash
php telegram-bot/telegram_bot.php doctor
```

### 1.8 Optional: Telegram Bot

If you want the Telegram bot active:

1. Create a Telegram bot via @BotFather and note the bot token.
2. In the web app, go to **Settings → AI and Telegram**: enter the bot token and
   the chats — `chat_admin` (purchase approvals), `chat_stock` (materials),
   `chat_book` (books). A room with no chat is not sent anything.
3. Make sure `api.token` and `api.base_url` are set in `config/secrets.json`;
   the bot reads both.
4. Check and start it: `php telegram-bot/telegram_bot.php doctor`, then
   `php telegram-bot/telegram_bot.php start`. After that, the switch on the
   settings screen starts and stops it.

**Choose one way to keep the bot running:**

**Option A — Cron watcher (works everywhere):**

```bash
* * * * * cd /path/to/USEA_Smart_Inventory_Management_System && php telegram-bot/telegram_bot.php >> storage/telegram-bot-supervisor.log 2>&1
```

**Option B — systemd (Linux servers):**

Create `/etc/systemd/system/usea-bot.service`:

```ini
[Unit]
Description=USEA inventory Telegram bot
After=network-online.target

[Service]
User=www-data
WorkingDirectory=/path/to/USEA_Smart_Inventory_Management_System/telegram-bot
ExecStart=/path/to/USEA_Smart_Inventory_Management_System/telegram-bot/venv/bin/python bot.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl enable --now usea-bot
systemctl status usea-bot
journalctl -u usea-bot -f
```

The `User=` account must be able to read `config/secrets.json`.

### 1.9 Optional: AI Assistant

The assistant answers from the system's own data — there is no AI provider and
no API key. It needs only:

1. The switch enabled in **Settings → AI and Telegram**
2. The roles that may use the chat panel ticked on the same screen

The Telegram token and the switch are written to `config/secrets.json`, so the
web server user must have write access to that file and its parent directory.

If the bot reports its token is not set after you saved one, the web server could not write the file. Fix permissions:

```bash
# macOS
chmod +a "www-data allow read,write,execute,delete,add_file,add_subdirectory,file_inherit,directory_inherit" config
chmod +a "www-data allow read,write" config/secrets.json

# Linux
sudo chgrp -R www-data config public/uploads
sudo chmod 770 config public/uploads
sudo chmod 660 config/secrets.json
```

Keep `secrets.json` at mode 600 or 640. Do **not** make it world-writable.

### 1.10 Security & Permissions

**File permissions:**

- `config/secrets.json` — mode 600 or 640. Contains the database password, the Telegram bot token, the API signing secret and the API token.
- `config/` — writable by the web server user only.
- `public/uploads/` — writable by the web server user. Ships with an `.htaccess` that disables PHP execution inside it. If you use nginx, add:

  ```nginx
  location ^~ /public/uploads/ {
    location ~ \.(php|phar|cgi|pl)$ { deny all; }
  }
  ```

- `storage/` — not served by the web server. Contains exports and logs. For nginx:

  ```nginx
  location ^~ /storage/ { deny all; }
  ```

- `telegram-bot/` — not served (its `.htaccess` denies it); the two PHP files in it run only from the command line.

**HTTPS:**

HTTPS is detected automatically. If TLS terminates at a reverse proxy, `X-Forwarded-Proto` is honoured so session cookies get the `Secure` flag and absolute URLs still say `https`.

**Trusted proxies (Cloudflare, load balancers):**

If the server sits behind a proxy, add the proxy ranges to `config/app.json`:

```json
{
  "trusted_proxies": ["173.245.48.0/20", "2400:cb00::/32"]
}
```

Cloudflare publishes the full list at `https://www.cloudflare.com/ips/`.

**Do not challenge `/api/v1/*` with Bot Fight Mode or a CAPTCHA.** The phone app and Telegram bot cannot answer HTML challenges — they expect JSON.

### 1.11 Scheduled Tasks (Cron)

**Nightly database backup:**

```bash
0 2 * * * mysqldump --single-transaction usea_main | gzip > /path/to/backups/usea_main-$(date +\%F).sql.gz
```

(The database credentials come from the cron user's `~/.my.cnf`. Keep the
backups outside the web root.)

**Low-stock alerts (twice daily):**

```bash
0 7,13 * * * cd /path/to/USEA_Smart_Inventory_Management_System && php telegram-bot/stock_alerts.php >> storage/stock-alerts.log 2>&1
```

**Telegram bot supervisor (if using cron, not systemd):**

```bash
* * * * * cd /path/to/USEA_Smart_Inventory_Management_System && php telegram-bot/telegram_bot.php >> storage/telegram-bot-supervisor.log 2>&1
```

### 1.12 Legacy Media

If the old system's profile pictures and product images are still needed, point `media.legacy_base` in `config/app.json` at wherever they are served from:

```json
{
  "media": {
    "legacy_base": "https://portal.usea.edu.kh"
  }
}
```

Leave it empty and those rows show a placeholder instead of broken images.

---

## 2. Mobile App (Flutter)

### 2.1 Prerequisites

- **Flutter SDK 3.9.0 or newer**
- **Android SDK** (for Android builds) or **Xcode** (for iOS builds)
- Access to the production API URL
- Firebase project configured for push notifications (if using FCM)

### 2.2 Configure Production API URL

The app reads the API base URL from a build-time environment variable. **Do not** edit `lib/util/api_config.dart` directly — it is overridden at build time.

Put the values in `dart_defines.json` (copy `dart_defines.example.json`; the
file is git-ignored) and build with it:

```bash
flutter pub get
flutter build apk --release --dart-define-from-file=dart_defines.json
flutter build appbundle --release --dart-define-from-file=dart_defines.json   # Google Play
flutter build ios --release --dart-define-from-file=dart_defines.json
```

For development, `./run.sh` runs the app with the same file.

**Notes:**

- `USEA_API_BASE_URL` must point to the `/api/v1` path of the deployed backend.
- `USEA_API_TOKEN` must equal `api.token` in the server's `config/secrets.json`.
  Do **not** commit it to source control.
- If you use an app signing scheme (e.g., Google Play App Signing), configure it in `android/app/build.gradle` before building.

### 2.3 Firebase Cloud Messaging (FCM)

The app uses Firebase Cloud Messaging for push notifications.

1. Ensure `firebase_options.dart` contains your production Firebase project credentials.
2. The `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files must be present in the respective platform folders.
3. Build the release app after confirming FCM is configured, otherwise notifications will not work in production.

### 2.4 App Signing

**Android:**

Sign the release build with your keystore:

```bash
# Build a signed APK using flutter build apk with your existing keystore configured in android/app/build.gradle
flutter build apk --release
```

For Google Play App Signing, upload the App Bundle (`.aab`) and let Google handle the final signing key.

**iOS:**

Archive and distribute via Xcode or:

```bash
flutter build ios --release
```

Then use Xcode to archive and upload to App Store Connect.

### 2.5 Install on Device

- **Android:** Transfer the release APK to the device and install, or distribute via Google Play.
- **iOS:** Install via TestFlight or the App Store.

---

## 3. Post-Deployment Checklist

- [ ] `config/secrets.json` contains production credentials (not the default XAMPP `root` / empty password)
- [ ] `config/app.json` has `"environment": "production"`
- [ ] `usea_main` was backed up, then `Schema of New Table and Field.sql` was run once
- [ ] The same version of the code was deployed with it
- [ ] `api.base_url` in `config/secrets.json` is the server's address (the bot and the asset QR labels use it)
- [ ] At least one administrator account exists and has changed the bootstrap password
- [ ] `config/secrets.json` is not world-readable (mode 600/640)
- [ ] `public/uploads/` has an `.htaccess` denying PHP execution (or equivalent nginx rule)
- [ ] `storage/` is not web-accessible
- [ ] HTTPS is working and `X-Forwarded-Proto` is honoured if behind a reverse proxy
- [ ] The mobile app is built with `--dart-define` pointing to the production API URL
- [ ] `USEA_API_TOKEN` used in the mobile build is a production token (not a dev token)
- [ ] Cron jobs (backup, stock alerts, bot supervisor if using cron) are active
- [ ] Telegram bot is running (if enabled) and responds to commands
- [ ] Settings ▸ AI & Telegram has the admin, stock and book chats (if Telegram is used)
- [ ] Firebase Cloud Messaging is configured for the production project
- [ ] Nightly backup cron is tested and dumps are appearing in `database/backups/`
