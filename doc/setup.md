# Production Setup Guide

Step-by-step instructions for deploying the **USEA Smart Inventory Management System** backend and the **thesisapp** Flutter mobile application to production.

---

## Table of Contents

1. [Backend System (PHP + MariaDB)](#1-backend-system-php--mariadb)
2. [Mobile App (Flutter)](#2-mobile-app-flutter)
3. [Post-Deployment Checklist](#3-post-deployment-checklist)

---

## 1. Backend System (PHP + MariaDB)

### 1.1 Prerequisites

The server must have the following installed and running:

- **PHP 8.2 or newer** with extensions: `pdo_mysql`, `mbstring`, `zip`, `curl`
- **MariaDB 10.1.4 or newer** — **not MySQL**. The migration scripts use MariaDB-specific syntax (`ADD COLUMN IF NOT EXISTS`, `CHANGE COLUMN IF EXISTS`, `CREATE INDEX IF NOT EXISTS`) that MySQL does not support at any version.
- **mysqldump** — the migration script refuses to run without it
- **Apache** with `mod_rewrite` (or equivalent) and `.htaccess` support

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
       "token": "usea_production_device_token_here",
       "base_url": "https://your-domain.com/USEA_Smart_Inventory_Management_System/api/v1"
     },
     "telegram": {
       "bot_token": "your_telegram_bot_token_here"
     },
     "api_signing_secret": "your_api_signing_secret_here"
   }
   ```

3. Verify the database connection before proceeding:

   ```bash
   php scripts/check_db.php
   ```

   This connects to the database, reports which columns already exist, and makes no changes.

### 1.4 Upgrade the Schema

Run the migration script. It creates an automatic backup before altering anything, so if the backup cannot be taken, nothing runs.

```bash
php scripts/migrate.php --dry-run    # review changes first
php scripts/migrate.php
```

The migration is **idempotent** — running it twice is a safe no-op. Backups are stored in `database/backups/`.

### 1.5 Bootstrap Administrators

Edit `config/access.php` to list the usernames who must be able to sign in before anyone can grant roles through the interface.

Then run:

```bash
php scripts/sync_access.php --dry-run
php scripts/sync_access.php
```

This script never creates accounts — it only grants roles to existing ones. It will also warn you if any bootstrap password is shorter than the 8-character minimum.

### 1.6 Enable Production Mode

Edit `config/app.json` and set:

```json
{
  "environment": "production"
}
```

This disables on-screen error messages. Errors are written to the web server log with a short reference code the user can quote. **Never deploy with this left on `development`** — that setting exposes file paths and internal messages to visitors.

### 1.7 Verify Installation

Run the full test suite:

```bash
sh tests/run.sh
```

This runs 17 checks. Nothing in the suite writes to the live database — the migration check builds a scratch copy and drops it. If the output is green, the system is ready.

### 1.8 Optional: Telegram Bot

If you want the Telegram bot active:

1. Create a Telegram bot via @BotFather and note the bot token.
2. In the web app, go to **Settings → AI and Telegram** and enter the bot token.
3. Generate an API token in **Settings → API Tokens**, ticking **"provide this token to the Telegram bot"**. This writes the plain token to `config/secrets.json` at the moment of creation.
4. Restart the bot after saving credentials.

**Choose one way to keep the bot running:**

**Option A — Cron watcher (works everywhere):**

```bash
* * * * * cd /path/to/USEA_Smart_Inventory_Management_System && php scripts/telegram_bot.php >> storage/telegram-bot-supervisor.log 2>&1
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

The AI assistant requires three things before the chat button appears:

1. The assistant switch enabled in **Settings → AI and Telegram**
2. An AI provider configured (e.g., Azure OpenAI, OpenAI)
3. An API key for that provider

Both the API key and the Telegram token are written to `config/secrets.json`, so the web server user must have write access to that file and its parent directory.

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

- `config/secrets.json` — mode 600 or 640. Contains database password, Telegram bot token, API signing secret, and API tokens.
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

- `database/backups/` — not served. Grow without pruning; each dump is ~140 MB.

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
0 2 * * * cd /path/to/USEA_Smart_Inventory_Management_System && php scripts/backup.php --quiet
```

**Low-stock alerts (twice daily):**

```bash
0 7,13 * * * cd /path/to/USEA_Smart_Inventory_Management_System && php scripts/stock_alerts.php >> storage/stock-alerts.log 2>&1
```

**Telegram bot supervisor (if using cron, not systemd):**

```bash
* * * * * cd /path/to/USEA_Smart_Inventory_Management_System && php scripts/telegram_bot.php >> storage/telegram-bot-supervisor.log 2>&1
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

Build the release APK with the production API URL:

```bash
flutter pub get

flutter build apk \
  --dart-define=USEA_API_BASE_URL=https://your-domain.com/USEA_Smart_Inventory_Management_System/api/v1 \
  --dart-define=USEA_API_TOKEN=your_production_device_token_here
```

For iOS:

```bash
flutter build ios \
  --dart-define=USEA_API_BASE_URL=https://your-domain.com/USEA_Smart_Inventory_Management_System/api/v1 \
  --dart-define=USEA_API_TOKEN=your_production_device_token_here
```

For an Android App Bundle (Google Play):

```bash
flutter build appbundle \
  --dart-define=USEA_API_BASE_URL=https://your-domain.com/USEA_Smart_Inventory_Management_System/api/v1 \
  --dart-define=USEA_API_TOKEN=your_production_device_token_here
```

**Notes:**

- `USEA_API_BASE_URL` must point to the `/api/v1` path of the deployed backend.
- `USEA_API_TOKEN` is the device token created in **Settings → API Tokens** on the web app. Create a dedicated production token and do **not** commit it to source control.
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
- [ ] `php scripts/migrate.php` has been run successfully
- [ ] `sh tests/run.sh` passes all 17 checks
- [ ] At least one administrator account exists and has changed the bootstrap password
- [ ] `config/secrets.json` is not world-readable (mode 600/640)
- [ ] `public/uploads/` has an `.htaccess` denying PHP execution (or equivalent nginx rule)
- [ ] `storage/` is not web-accessible
- [ ] HTTPS is working and `X-Forwarded-Proto` is honoured if behind a reverse proxy
- [ ] The mobile app is built with `--dart-define` pointing to the production API URL
- [ ] `USEA_API_TOKEN` used in the mobile build is a production token (not a dev token)
- [ ] Cron jobs (backup, stock alerts, bot supervisor if using cron) are active
- [ ] Telegram bot is running (if enabled) and responds to commands
- [ ] AI assistant is configured with a provider and API key (if enabled)
- [ ] Firebase Cloud Messaging is configured for the production project
- [ ] Nightly backup cron is tested and dumps are appearing in `database/backups/`
