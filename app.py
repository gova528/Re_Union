"""
app.py — GRT 2006-2007 Grand Reunion Tour
Single-file Flask application: config, routes, public APIs, admin auth,
admin CRUD, admin APIs, and error handlers.
"""

import os
import uuid
import datetime
from functools import wraps

from flask import (
    Flask, request, jsonify, session, send_from_directory,
    redirect, url_for, render_template_string, abort, make_response
)
from werkzeug.security import check_password_hash, generate_password_hash
from werkzeug.utils import secure_filename
from markupsafe import escape

import config
import database as db

# =========================================================================
# APP INIT / CONFIG
# =========================================================================
app = Flask(__name__, static_folder=None)
app.config["SECRET_KEY"] = config.SECRET_KEY
app.config["SESSION_COOKIE_HTTPONLY"] = config.SESSION_COOKIE_HTTPONLY
app.config["SESSION_COOKIE_SAMESITE"] = config.SESSION_COOKIE_SAMESITE
app.config["SESSION_COOKIE_SECURE"] = config.SESSION_COOKIE_SECURE
app.config["MAX_CONTENT_LENGTH"] = config.MAX_CONTENT_LENGTH
app.permanent_session_lifetime = datetime.timedelta(minutes=config.PERMANENT_SESSION_LIFETIME_MINUTES)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

db.init_pool()


# =========================================================================
# CSRF HELPERS (lightweight, no external session store needed)
# =========================================================================
def get_csrf_token():
    if "csrf_token" not in session:
        session["csrf_token"] = uuid.uuid4().hex
    return session["csrf_token"]


def csrf_protect():
    token = session.get("csrf_token")
    sent = request.headers.get("X-CSRF-Token")
    if not sent and request.is_json:
        json_body = request.get_json(silent=True) or {}
        sent = json_body.get("csrf_token")
    if not sent:
        sent = request.form.get("csrf_token")
    if not token or not sent or token != sent:
        abort(403, description="Invalid CSRF token.")


@app.context_processor
def inject_csrf():
    return {"csrf_token": get_csrf_token()}


# =========================================================================
# AUTH HELPERS / DECORATORS
# =========================================================================
def admin_required(view_func):
    @wraps(view_func)
    def wrapped(*args, **kwargs):
        if not session.get("admin_logged_in"):
            return jsonify({"success": False, "error": "Unauthorized"}), 401
        return view_func(*args, **kwargs)
    return wrapped


def gate_required(view_func):
    """Requires the stage-1 secret access code to already be validated."""
    @wraps(view_func)
    def wrapped(*args, **kwargs):
        if not session.get("gate_passed"):
            return jsonify({"success": False, "error": "Access Denied"}), 403
        return view_func(*args, **kwargs)
    return wrapped


def visitor_token():
    """Cookie-based anonymous identifier used for one-like-per-browser."""
    token = request.cookies.get("grt_visitor")
    if not token:
        token = uuid.uuid4().hex
    return token


def allowed_file(filename):
    ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else ""
    return ext in config.ALLOWED_IMAGE_EXTENSIONS


def save_upload(file_storage):
    """Validates and saves an uploaded image; returns the stored filename."""
    if not file_storage or file_storage.filename == "":
        return None
    if not allowed_file(file_storage.filename):
        abort(400, description="Invalid file type.")
    if file_storage.mimetype not in config.ALLOWED_MIME_TYPES:
        abort(400, description="Invalid MIME type.")
    ext = file_storage.filename.rsplit(".", 1)[-1].lower()
    safe_name = f"upload_{uuid.uuid4().hex}.{ext}"
    safe_name = secure_filename(safe_name)
    file_storage.save(os.path.join(BASE_DIR, safe_name))
    return safe_name


# =========================================================================
# STATIC FILE SERVING (flat project root — html/css/js/images)
# =========================================================================
@app.route("/style.css")
def serve_css():
    return send_from_directory(BASE_DIR, "style.css", mimetype="text/css")


@app.route("/script.js")
def serve_js():
    return send_from_directory(BASE_DIR, "script.js", mimetype="application/javascript")


@app.route("/<path:filename>")
def serve_image(filename):
    """Serves sample/uploaded images only (whitelisted extensions)."""
    if not allowed_file(filename):
        abort(404)
    full_path = os.path.join(BASE_DIR, filename)
    if not os.path.isfile(full_path):
        abort(404)
    return send_from_directory(BASE_DIR, filename)


# =========================================================================
# PUBLIC ROUTES
# =========================================================================
@app.route("/")
def index():
    with open(os.path.join(BASE_DIR, "index.html"), encoding="utf-8") as f:
        html = f.read()
    resp = make_response(render_template_string(html))
    if not request.cookies.get("grt_visitor"):
        resp.set_cookie("grt_visitor", uuid.uuid4().hex, max_age=60 * 60 * 24 * 365, httponly=True, samesite="Lax")
    return resp


@app.route("/admin-portal-x7q9")
def admin_portal():
    """Hidden admin entry point — not linked anywhere in public UI."""
    with open(os.path.join(BASE_DIR, "admin.html"), encoding="utf-8") as f:
        html = f.read()
    return render_template_string(html)


# =========================================================================
# PUBLIC APIs
# =========================================================================
@app.route("/api/settings", methods=["GET"])
def api_settings():
    return jsonify({"success": True, "data": db.get_all_settings()})


@app.route("/api/students", methods=["GET"])
def api_students():
    gender = request.args.get("gender")
    search = request.args.get("search")
    letter = request.args.get("letter")
    search = escape(search) if search else None
    letter = escape(letter) if letter else None
    students = db.get_all_students(gender=gender, search=search, letter=letter)
    return jsonify({"success": True, "data": students})


@app.route("/api/photos", methods=["GET"])
def api_photos():
    return jsonify({"success": True, "data": db.get_all_photos()})


@app.route("/api/announcements", methods=["GET"])
def api_announcements():
    return jsonify({"success": True, "data": db.get_all_announcements()})


@app.route("/api/announcements/<int:announcement_id>/like", methods=["POST"])
def api_like_announcement(announcement_id):
    if not db.get_announcement_by_id(announcement_id):
        return jsonify({"success": False, "error": "Announcement not found"}), 404
    token = visitor_token()
    liked = db.add_like(announcement_id, token)
    count = db.count_likes(announcement_id)
    resp = jsonify({"success": True, "liked_now": liked, "like_count": count})
    resp.set_cookie("grt_visitor", token, max_age=60 * 60 * 24 * 365, httponly=True, samesite="Lax")
    return resp


@app.route("/api/rsvp", methods=["POST"])
def api_rsvp_submit():
    payload = request.get_json(silent=True) or request.form
    full_name = (payload.get("full_name") or "").strip()
    email = (payload.get("email") or "").strip()
    phone = (payload.get("phone") or "").strip()
    response = (payload.get("response") or "").strip()
    message = (payload.get("message") or "").strip()

    if not full_name or len(full_name) > 150:
        return jsonify({"success": False, "error": "A valid name is required."}), 400
    if response not in ("Accept", "Decline", "Maybe"):
        return jsonify({"success": False, "error": "Invalid RSVP response."}), 400
    if email and ("@" not in email or len(email) > 150):
        return jsonify({"success": False, "error": "Invalid email address."}), 400
    if len(phone) > 30:
        return jsonify({"success": False, "error": "Invalid phone number."}), 400
    if len(message) > 2000:
        return jsonify({"success": False, "error": "Message too long."}), 400

    rsvp_id = db.create_rsvp(escape(full_name), escape(email), escape(phone), response, escape(message))
    return jsonify({"success": True, "id": rsvp_id})


@app.route("/api/contact", methods=["GET"])
def api_contact():
    settings = db.get_all_settings()
    return jsonify({
        "success": True,
        "data": {
            "email": settings.get("contact_email"),
            "phone": settings.get("contact_phone"),
            "venue": settings.get("event_venue"),
        }
    })


# =========================================================================
# ADMIN AUTH ROUTES
# =========================================================================
@app.route("/api/admin/verify-code", methods=["POST"])
def admin_verify_code():
    payload = request.get_json(silent=True) or request.form
    code = (payload.get("code") or "").strip()
    if code and code == config.SECRET_ACCESS_CODE:
        session.permanent = True
        session["gate_passed"] = True
        return jsonify({"success": True})
    return jsonify({"success": False, "error": "Access Denied"}), 403


@app.route("/api/admin/login", methods=["POST"])
@gate_required
def admin_login():
    payload = request.get_json(silent=True) or request.form
    username = (payload.get("username") or "").strip()
    password = payload.get("password") or ""

    admin = db.get_admin_by_username(username)
    if not admin or not check_password_hash(admin["password_hash"], password):
        return jsonify({"success": False, "error": "Access Denied"}), 401

    session.permanent = True
    session["admin_logged_in"] = True
    session["admin_id"] = admin["id"]
    session["admin_username"] = admin["username"]
    db.update_admin_last_login(admin["id"])
    db.log_activity(admin["id"], "LOGIN", "Administrator logged in.")
    return jsonify({"success": True, "username": admin["username"]})


@app.route("/api/admin/logout", methods=["POST"])
@admin_required
def admin_logout():
    db.log_activity(session.get("admin_id"), "LOGOUT", "Administrator logged out.")
    session.clear()
    return jsonify({"success": True})


@app.route("/api/admin/csrf-token", methods=["GET"])
def admin_csrf_token():
    return jsonify({"success": True, "csrf_token": get_csrf_token()})


@app.route("/api/admin/session", methods=["GET"])
def admin_session_check():
    return jsonify({
        "success": True,
        "gate_passed": bool(session.get("gate_passed")),
        "logged_in": bool(session.get("admin_logged_in")),
        "username": session.get("admin_username"),
    })


# =========================================================================
# ADMIN CRUD ROUTES — STUDENTS
# =========================================================================
@app.route("/api/admin/students", methods=["POST"])
@admin_required
def admin_create_student():
    csrf_protect()
    full_name = escape((request.form.get("full_name") or "").strip())
    gender = request.form.get("gender")
    occupation = escape((request.form.get("occupation") or "").strip())
    current_city = escape((request.form.get("current_city") or "").strip())
    biography = escape((request.form.get("biography") or "").strip())
    contact_info = escape((request.form.get("contact_info") or "").strip())

    if not full_name or gender not in ("Male", "Female"):
        return jsonify({"success": False, "error": "Name and gender are required."}), 400

    photo_path = save_upload(request.files.get("photo")) or "reunion_001.jpg"
    new_id = db.create_student(str(full_name), gender, str(occupation), str(current_city),
                                str(biography), str(contact_info), photo_path)
    db.log_activity(session["admin_id"], "CREATE_STUDENT", f"Created student #{new_id}: {full_name}")
    return jsonify({"success": True, "id": new_id})


@app.route("/api/admin/students/<int:student_id>", methods=["PUT", "POST"])
@admin_required
def admin_update_student(student_id):
    csrf_protect()
    if not db.get_student_by_id(student_id):
        return jsonify({"success": False, "error": "Student not found"}), 404

    full_name = escape((request.form.get("full_name") or "").strip())
    gender = request.form.get("gender")
    occupation = escape((request.form.get("occupation") or "").strip())
    current_city = escape((request.form.get("current_city") or "").strip())
    biography = escape((request.form.get("biography") or "").strip())
    contact_info = escape((request.form.get("contact_info") or "").strip())

    if not full_name or gender not in ("Male", "Female"):
        return jsonify({"success": False, "error": "Name and gender are required."}), 400

    photo_path = save_upload(request.files.get("photo"))
    db.update_student(student_id, str(full_name), gender, str(occupation), str(current_city),
                       str(biography), str(contact_info), photo_path)
    db.log_activity(session["admin_id"], "UPDATE_STUDENT", f"Updated student #{student_id}")
    return jsonify({"success": True})


@app.route("/api/admin/students/<int:student_id>", methods=["DELETE"])
@admin_required
def admin_delete_student(student_id):
    csrf_protect()
    if not db.get_student_by_id(student_id):
        return jsonify({"success": False, "error": "Student not found"}), 404
    db.delete_student(student_id)
    db.log_activity(session["admin_id"], "DELETE_STUDENT", f"Deleted student #{student_id}")
    return jsonify({"success": True})


# =========================================================================
# ADMIN CRUD ROUTES — PHOTOS / GALLERY
# =========================================================================
@app.route("/api/admin/photos", methods=["POST"])
@admin_required
def admin_create_photo():
    csrf_protect()
    caption = escape((request.form.get("caption") or "").strip())
    photo_date = request.form.get("photo_date") or None
    photo_path = save_upload(request.files.get("photo"))
    if not photo_path:
        return jsonify({"success": False, "error": "A valid image file is required."}), 400
    new_id = db.create_photo(photo_path, str(caption), photo_date)
    db.log_activity(session["admin_id"], "CREATE_PHOTO", f"Added gallery photo #{new_id}")
    return jsonify({"success": True, "id": new_id})


@app.route("/api/admin/photos/<int:photo_id>", methods=["PUT", "POST"])
@admin_required
def admin_update_photo(photo_id):
    csrf_protect()
    if not db.get_photo_by_id(photo_id):
        return jsonify({"success": False, "error": "Photo not found"}), 404
    caption = escape((request.form.get("caption") or "").strip())
    photo_date = request.form.get("photo_date") or None
    db.update_photo(photo_id, str(caption), photo_date)
    db.log_activity(session["admin_id"], "UPDATE_PHOTO", f"Updated gallery photo #{photo_id}")
    return jsonify({"success": True})


@app.route("/api/admin/photos/<int:photo_id>", methods=["DELETE"])
@admin_required
def admin_delete_photo(photo_id):
    csrf_protect()
    if not db.get_photo_by_id(photo_id):
        return jsonify({"success": False, "error": "Photo not found"}), 404
    db.delete_photo(photo_id)
    db.log_activity(session["admin_id"], "DELETE_PHOTO", f"Deleted gallery photo #{photo_id}")
    return jsonify({"success": True})


# =========================================================================
# ADMIN CRUD ROUTES — ANNOUNCEMENTS
# =========================================================================
@app.route("/api/admin/announcements", methods=["POST"])
@admin_required
def admin_create_announcement():
    csrf_protect()
    payload = request.get_json(silent=True) or request.form
    title = escape((payload.get("title") or "").strip())
    body = escape((payload.get("body") or "").strip())
    if not title or not body:
        return jsonify({"success": False, "error": "Title and body are required."}), 400
    new_id = db.create_announcement(str(title), str(body))
    db.log_activity(session["admin_id"], "CREATE_ANNOUNCEMENT", f"Created announcement #{new_id}")
    return jsonify({"success": True, "id": new_id})


@app.route("/api/admin/announcements/<int:announcement_id>", methods=["PUT"])
@admin_required
def admin_update_announcement(announcement_id):
    csrf_protect()
    if not db.get_announcement_by_id(announcement_id):
        return jsonify({"success": False, "error": "Announcement not found"}), 404
    payload = request.get_json(silent=True) or request.form
    title = escape((payload.get("title") or "").strip())
    body = escape((payload.get("body") or "").strip())
    if not title or not body:
        return jsonify({"success": False, "error": "Title and body are required."}), 400
    db.update_announcement(announcement_id, str(title), str(body))
    db.log_activity(session["admin_id"], "UPDATE_ANNOUNCEMENT", f"Updated announcement #{announcement_id}")
    return jsonify({"success": True})


@app.route("/api/admin/announcements/<int:announcement_id>", methods=["DELETE"])
@admin_required
def admin_delete_announcement(announcement_id):
    csrf_protect()
    if not db.get_announcement_by_id(announcement_id):
        return jsonify({"success": False, "error": "Announcement not found"}), 404
    db.delete_announcement(announcement_id)
    db.log_activity(session["admin_id"], "DELETE_ANNOUNCEMENT", f"Deleted announcement #{announcement_id}")
    return jsonify({"success": True})


# =========================================================================
# ADMIN APIs — RSVP / SETTINGS / LOGS / STATS
# =========================================================================
@app.route("/api/admin/rsvps", methods=["GET"])
@admin_required
def admin_get_rsvps():
    return jsonify({"success": True, "data": db.get_all_rsvps()})


@app.route("/api/admin/settings", methods=["PUT"])
@admin_required
def admin_update_settings():
    csrf_protect()
    payload = request.get_json(silent=True) or request.form
    updated = []
    allowed_keys = {"hero_title", "hero_subtitle", "event_date", "event_venue", "contact_email", "contact_phone"}
    for key, value in payload.items():
        if key in allowed_keys:
            db.update_setting(key, str(escape(str(value))))
            updated.append(key)
    db.log_activity(session["admin_id"], "UPDATE_SETTINGS", f"Updated: {', '.join(updated)}")
    return jsonify({"success": True, "updated": updated})


@app.route("/api/admin/logs", methods=["GET"])
@admin_required
def admin_get_logs():
    return jsonify({"success": True, "data": db.get_activity_logs()})


@app.route("/api/admin/stats", methods=["GET"])
@admin_required
def admin_get_stats():
    return jsonify({"success": True, "data": db.get_dashboard_stats()})


# =========================================================================
# ERROR HANDLERS
# =========================================================================
@app.errorhandler(400)
def handle_400(e):
    return jsonify({"success": False, "error": "Bad request."}), 400


@app.errorhandler(401)
def handle_401(e):
    return jsonify({"success": False, "error": "Unauthorized."}), 401


@app.errorhandler(403)
def handle_403(e):
    return jsonify({"success": False, "error": "Access Denied"}), 403


@app.errorhandler(404)
def handle_404(e):
    if request.path.startswith("/api/"):
        return jsonify({"success": False, "error": "Not found."}), 404
    return "Page not found.", 404


@app.errorhandler(413)
def handle_413(e):
    return jsonify({"success": False, "error": "File too large."}), 413


@app.errorhandler(500)
def handle_500(e):
    return jsonify({"success": False, "error": "Internal server error."}), 500


# =========================================================================
# ENTRY POINT
# =========================================================================
if __name__ == "__main__":
    app.run(debug=False, host="0.0.0.0", port=5000)
