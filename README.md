# GRT 2006–2007 — Grand Reunion Tour

A private, invite-only digital reunion platform for the GRT 2006–2007 class, built as a premium luxury, glassmorphism-themed, 3D-animated web application using Flask + MySQL.

## 1. Project Overview

This application lets classmates view the reunion invitation, browse the student directory (Boys / Girls), browse the photo gallery, read and like announcements, and submit an RSVP — all without registering or logging in. A hidden Administrator dashboard (reachable only via a secret URL plus a two-stage secret-code + login gate) manages all content: students, gallery photos, announcements, RSVP responses, site settings, and an activity log.

The roster used to seed the `students` table was generated from the uploaded class list (Boys and Girls sheets); occupations, cities, and biographies are realistic sample data since no live import pipeline exists in this single-file build.

## 2. Folder Structure

```
GRT-2006-2007/
├── app.py                 # Flask entry point, all routes + logic
├── index.html              # Public site
├── admin.html               # Hidden administrator dashboard
├── style.css                 # All styling
├── script.js                  # Public frontend JS
├── database.py                  # DB connection + CRUD
├── config.py                      # Config, secrets, DB credentials
├── schema.sql                       # MySQL schema + seed data
├── reunion_001.jpg, reunion_002.jpg, class_group_photo.jpg, farewell.webp
├── requirements.txt
└── README.md
```

## 3. Installation

### 3.1 Prerequisites
- Python 3.10+
- MySQL Server 8.0+

### 3.2 Install Python dependencies
```bash
cd GRT-2006-2007
python3 -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 3.3 Set up the MySQL database
```bash
mysql -u root -p < schema.sql
```
This creates the `grt_reunion` database, all tables, and seeds:
- 1 administrator account (username: `admin`, password: `ReunionAdmin@2007` — **change immediately**)
- Full student directory (Boys + Girls) from the class roster
- Sample announcements, gallery photos, and site settings

### 3.4 Configure `config.py`
Open `config.py` and set (directly or via environment variables):
- `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`
- `SECRET_KEY` — Flask session secret (generate with `config.generate_random_secret()`)
- `SECRET_ACCESS_CODE` — the stage-1 admin gate code

Environment variable overrides (recommended for production):
```bash
export GRT_DB_HOST=localhost
export GRT_DB_USER=root
export GRT_DB_PASSWORD=your_password
export GRT_DB_NAME=grt_reunion
export GRT_SECRET_KEY=$(python3 -c "import secrets;print(secrets.token_hex(32))")
export GRT_SECRET_ACCESS_CODE="your-own-secret-code"
```

### 3.5 Run the application
```bash
python app.py
```
The site is served at `http://localhost:5000/`.

## 4. Deployment Notes

- Run behind a production WSGI server (e.g. `gunicorn app:app`) and a reverse proxy (Nginx) with HTTPS.
- Set `GRT_COOKIE_SECURE=True` once served over HTTPS so session cookies require TLS.
- Never deploy with the default admin password or default `SECRET_ACCESS_CODE` — rotate both immediately.
- Back up the MySQL database regularly; RSVP and activity-log data lives there only.
- Uploaded images are saved to the project root; ensure that directory is writable by the app process and is excluded from version control.

## 5. Admin Manual

### 5.1 Hidden Access Flow
1. Navigate directly to `/admin-portal-x7q9` (this URL is not linked anywhere on the public site).
2. Enter the **Secret Access Code** configured in `config.py`. An incorrect code shows only a generic "Access Denied" message.
3. Once the code is accepted, the Administrator **Login** form appears — enter the username and password.
4. On success, the full dashboard loads. Sessions time out after 30 minutes of inactivity (configurable in `config.py`).

### 5.2 Dashboard Sections
- **Dashboard** — at-a-glance stats (students, photos, announcements, RSVP breakdown).
- **Students** — create, edit, and delete student profiles; upload/replace profile photos; assign Boys/Girls group.
- **Gallery** — upload new gallery photos with captions and dates; delete photos.
- **Announcements** — publish, edit, and delete announcements; view aggregate like counts per announcement.
- **RSVP Responses** — read-only list of every RSVP submission (name, contact, response, message, timestamp).
- **Site Settings** — edit hero text, event date/venue, and contact details shown on the public site.
- **Activity Log** — a timestamped audit trail of every admin write action.
- **Logout** — fully destroys the session.

### 5.3 Security Notes
- Passwords are hashed with Werkzeug's `generate_password_hash` / `check_password_hash` (never stored in plaintext).
- All admin write requests require a valid CSRF token (sent automatically by the dashboard JS).
- All SQL queries are parameterized — no string concatenation of user input.
- Uploaded files are validated by extension and MIME type before being saved.
- Every admin create/update/delete action is recorded in `activity_logs`.

## 6. Participant Features (Public Site)

- **Home** — animated hero, live countdown to the event, quick navigation.
- **Invitation** — event date, venue, dress code, and program details.
- **Directory** — search by name, filter by first letter, filter by Boys/Girls.
- **Gallery** — responsive grid with lightbox viewer and lazy-loaded images.
- **Announcements** — read announcements and like them once per browser (no login required).
- **RSVP** — submit Accept / Decline / Maybe with an optional message.
- **Contact** — event contact email and phone.

Participants have no login, no registration, and no write access anywhere on the public site — all content is managed solely by the Administrator.
