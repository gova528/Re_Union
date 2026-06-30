"""
config.py — GRT 2006-2007 Grand Reunion Tour
Central configuration: secrets, DB credentials, security parameters.

IMPORTANT: Change every default value below before deploying to production.
Never commit a populated config.py with real secrets to public source control.
"""

import os
import secrets

# -----------------------------------------------------------------------
# FLASK CORE CONFIG
# -----------------------------------------------------------------------
SECRET_KEY = os.environ.get("GRT_SECRET_KEY", "change-this-flask-secret-key-1947ab")
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = "Lax"
SESSION_COOKIE_SECURE = os.environ.get("GRT_COOKIE_SECURE", "False") == "True"  # set True behind HTTPS
PERMANENT_SESSION_LIFETIME_MINUTES = 30

# -----------------------------------------------------------------------
# DATABASE CONFIG (MySQL)
# -----------------------------------------------------------------------
DB_HOST = os.environ.get("GRT_DB_HOST", "localhost")
DB_PORT = int(os.environ.get("GRT_DB_PORT", "3306"))
DB_USER = os.environ.get("GRT_DB_USER", "root")
DB_PASSWORD = os.environ.get("GRT_DB_PASSWORD", "Rajesh@123")
DB_NAME = os.environ.get("GRT_DB_NAME", "grt_reunion")

# -----------------------------------------------------------------------
# ADMIN ACCESS SECURITY
# -----------------------------------------------------------------------
# Stage 1 gate: a Secret Access Code required before the admin login form
# is even shown. This is NOT the admin password — it is a separate,
# rarely-shared "is this even the admin" check.
SECRET_ACCESS_CODE = os.environ.get("GRT_SECRET_ACCESS_CODE", "GRT-2007-REUNION-ALPHA")

# Default admin bootstrap credentials are seeded (hashed) in schema.sql.
# Default seeded login: username "admin", password "ReunionAdmin@2007"
# CHANGE THE PASSWORD IMMEDIATELY AFTER FIRST LOGIN via the database.

# -----------------------------------------------------------------------
# UPLOADS
# -----------------------------------------------------------------------
UPLOAD_FOLDER = os.path.dirname(os.path.abspath(__file__))
ALLOWED_IMAGE_EXTENSIONS = {"jpg", "jpeg", "png", "webp", "gif"}
ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
MAX_CONTENT_LENGTH_MB = 8
MAX_CONTENT_LENGTH = MAX_CONTENT_LENGTH_MB * 1024 * 1024

# -----------------------------------------------------------------------
# CSRF
# -----------------------------------------------------------------------
WTF_CSRF_ENABLED = True
WTF_CSRF_TIME_LIMIT = 3600

# -----------------------------------------------------------------------
# MISC
# -----------------------------------------------------------------------
SITE_NAME = "GRT 2006-2007 Grand Reunion Tour"


def generate_random_secret():
    """Utility for operators who want to rotate the Flask secret key."""
    return secrets.token_hex(32)
