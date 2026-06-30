"""
database.py — GRT 2006-2007 Grand Reunion Tour
All MySQL connection handling and CRUD functions live here.
Every query is parameterized; no raw string concatenation of user input.
"""

import mysql.connector
from mysql.connector import pooling
import config

_pool = None


def init_pool():
    """Initialize a MySQL connection pool. Call once at app startup."""
    global _pool
    if _pool is None:
        _pool = pooling.MySQLConnectionPool(
            pool_name="grt_pool",
            pool_size=8,
            host=config.DB_HOST,
            port=config.DB_PORT,
            user=config.DB_USER,
            password=config.DB_PASSWORD,
            database=config.DB_NAME,
            autocommit=True,
        )
    return _pool


def get_connection():
    """Return a pooled MySQL connection. Initializes the pool lazily."""
    global _pool
    if _pool is None:
        init_pool()
    return _pool.get_connection()


def run_query(query, params=None, fetchone=False, fetchall=False, commit=False):
    """Generic safe query runner using parameterized statements."""
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(query, params or ())
        result = None
        if fetchone:
            result = cursor.fetchone()
        elif fetchall:
            result = cursor.fetchall()
        if commit:
            conn.commit()
            result = cursor.lastrowid
        return result
    finally:
        cursor.close()
        conn.close()


# =========================================================================
# ADMINISTRATORS
# =========================================================================
def get_admin_by_username(username):
    return run_query(
        "SELECT * FROM administrators WHERE username = %s LIMIT 1",
        (username,), fetchone=True
    )


def update_admin_last_login(admin_id):
    run_query(
        "UPDATE administrators SET last_login = NOW() WHERE id = %s",
        (admin_id,), commit=True
    )


# =========================================================================
# STUDENTS
# =========================================================================
def get_all_students(gender=None, search=None, letter=None):
    query = "SELECT * FROM students WHERE 1=1"
    params = []
    if gender in ("Male", "Female"):
        query += " AND gender = %s"
        params.append(gender)
    if search:
        query += " AND full_name LIKE %s"
        params.append(f"%{search}%")
    if letter:
        query += " AND full_name LIKE %s"
        params.append(f"{letter}%")
    query += " ORDER BY full_name ASC"
    return run_query(query, tuple(params), fetchall=True)


def get_student_by_id(student_id):
    return run_query("SELECT * FROM students WHERE id = %s", (student_id,), fetchone=True)


def create_student(full_name, gender, occupation, current_city, biography, contact_info, photo_path):
    return run_query(
        """INSERT INTO students (full_name, gender, occupation, current_city, biography, contact_info, photo_path)
           VALUES (%s, %s, %s, %s, %s, %s, %s)""",
        (full_name, gender, occupation, current_city, biography, contact_info, photo_path),
        commit=True
    )


def update_student(student_id, full_name, gender, occupation, current_city, biography, contact_info, photo_path=None):
    if photo_path:
        run_query(
            """UPDATE students SET full_name=%s, gender=%s, occupation=%s, current_city=%s,
               biography=%s, contact_info=%s, photo_path=%s WHERE id=%s""",
            (full_name, gender, occupation, current_city, biography, contact_info, photo_path, student_id),
            commit=True
        )
    else:
        run_query(
            """UPDATE students SET full_name=%s, gender=%s, occupation=%s, current_city=%s,
               biography=%s, contact_info=%s WHERE id=%s""",
            (full_name, gender, occupation, current_city, biography, contact_info, student_id),
            commit=True
        )


def delete_student(student_id):
    run_query("DELETE FROM students WHERE id = %s", (student_id,), commit=True)


# =========================================================================
# PHOTOS (GALLERY)
# =========================================================================
def get_all_photos():
    return run_query("SELECT * FROM photos ORDER BY photo_date DESC, id DESC", fetchall=True)


def create_photo(file_path, caption, photo_date):
    return run_query(
        "INSERT INTO photos (file_path, caption, photo_date) VALUES (%s, %s, %s)",
        (file_path, caption, photo_date), commit=True
    )


def update_photo(photo_id, caption, photo_date):
    run_query(
        "UPDATE photos SET caption = %s, photo_date = %s WHERE id = %s",
        (caption, photo_date, photo_id), commit=True
    )


def delete_photo(photo_id):
    run_query("DELETE FROM photos WHERE id = %s", (photo_id,), commit=True)


def get_photo_by_id(photo_id):
    return run_query("SELECT * FROM photos WHERE id = %s", (photo_id,), fetchone=True)


# =========================================================================
# ANNOUNCEMENTS
# =========================================================================
def get_all_announcements():
    return run_query(
        """SELECT a.*, (SELECT COUNT(*) FROM likes l WHERE l.announcement_id = a.id) AS like_count
           FROM announcements a ORDER BY published_at DESC""",
        fetchall=True
    )


def get_latest_announcement():
    rows = get_all_announcements()
    return rows[0] if rows else None


def get_announcement_by_id(announcement_id):
    return run_query("SELECT * FROM announcements WHERE id = %s", (announcement_id,), fetchone=True)


def create_announcement(title, body):
    return run_query(
        "INSERT INTO announcements (title, body) VALUES (%s, %s)",
        (title, body), commit=True
    )


def update_announcement(announcement_id, title, body):
    run_query(
        "UPDATE announcements SET title = %s, body = %s WHERE id = %s",
        (title, body, announcement_id), commit=True
    )


def delete_announcement(announcement_id):
    run_query("DELETE FROM announcements WHERE id = %s", (announcement_id,), commit=True)


# =========================================================================
# LIKES
# =========================================================================
def has_liked(announcement_id, visitor_token):
    row = run_query(
        "SELECT id FROM likes WHERE announcement_id = %s AND visitor_token = %s",
        (announcement_id, visitor_token), fetchone=True
    )
    return row is not None


def add_like(announcement_id, visitor_token):
    if has_liked(announcement_id, visitor_token):
        return False
    run_query(
        "INSERT INTO likes (announcement_id, visitor_token) VALUES (%s, %s)",
        (announcement_id, visitor_token), commit=True
    )
    return True


def count_likes(announcement_id):
    row = run_query(
        "SELECT COUNT(*) AS c FROM likes WHERE announcement_id = %s",
        (announcement_id,), fetchone=True
    )
    return row["c"] if row else 0


# =========================================================================
# RSVP
# =========================================================================
def create_rsvp(full_name, email, phone, response, message):
    return run_query(
        """INSERT INTO rsvp (full_name, email, phone, response, message)
           VALUES (%s, %s, %s, %s, %s)""",
        (full_name, email, phone, response, message), commit=True
    )


def get_all_rsvps():
    return run_query("SELECT * FROM rsvp ORDER BY submitted_at DESC", fetchall=True)


def get_rsvp_stats():
    rows = run_query(
        "SELECT response, COUNT(*) AS total FROM rsvp GROUP BY response", fetchall=True
    )
    stats = {"Accept": 0, "Decline": 0, "Maybe": 0}
    for r in rows:
        stats[r["response"]] = r["total"]
    return stats


# =========================================================================
# SETTINGS
# =========================================================================
def get_all_settings():
    rows = run_query("SELECT * FROM settings", fetchall=True)
    return {r["setting_key"]: r["setting_value"] for r in rows}


def get_setting(key, default=None):
    row = run_query("SELECT setting_value FROM settings WHERE setting_key = %s", (key,), fetchone=True)
    return row["setting_value"] if row else default


def update_setting(key, value):
    run_query(
        """INSERT INTO settings (setting_key, setting_value) VALUES (%s, %s)
           ON DUPLICATE KEY UPDATE setting_value = %s""",
        (key, value, value), commit=True
    )


# =========================================================================
# ACTIVITY LOGS
# =========================================================================
def log_activity(admin_id, action, details=""):
    run_query(
        "INSERT INTO activity_logs (admin_id, action, details) VALUES (%s, %s, %s)",
        (admin_id, action, details), commit=True
    )


def get_activity_logs(limit=100):
    return run_query(
        "SELECT al.*, ad.username FROM activity_logs al LEFT JOIN administrators ad ON al.admin_id = ad.id "
        "ORDER BY al.created_at DESC LIMIT %s",
        (limit,), fetchall=True
    )


# =========================================================================
# DASHBOARD STATS
# =========================================================================
def get_dashboard_stats():
    students = run_query("SELECT COUNT(*) AS c FROM students", fetchone=True)["c"]
    boys = run_query("SELECT COUNT(*) AS c FROM students WHERE gender='Male'", fetchone=True)["c"]
    girls = run_query("SELECT COUNT(*) AS c FROM students WHERE gender='Female'", fetchone=True)["c"]
    photos = run_query("SELECT COUNT(*) AS c FROM photos", fetchone=True)["c"]
    announcements = run_query("SELECT COUNT(*) AS c FROM announcements", fetchone=True)["c"]
    rsvps = run_query("SELECT COUNT(*) AS c FROM rsvp", fetchone=True)["c"]
    return {
        "total_students": students,
        "boys": boys,
        "girls": girls,
        "total_photos": photos,
        "total_announcements": announcements,
        "total_rsvps": rsvps,
        "rsvp_breakdown": get_rsvp_stats(),
    }
