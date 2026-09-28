import os
from contextlib import contextmanager
from datetime import date
from functools import wraps

import psycopg2
from flask import (
    Flask,
    flash,
    redirect,
    render_template,
    request,
    session,
    url_for,
)
from psycopg2.extras import RealDictCursor
from werkzeug.security import check_password_hash, generate_password_hash

from database.connection import get_connection


app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET_KEY", "clubsphere-dev-secret")

CLUB_ADMIN_ROLES = {
    "president",
    "vice president",
    "treasurer",
    "secretary",
    "club admin",
}

MANAGE_ALL_ROLES = {"president", "vice president"}
MANAGE_EVENTS_ROLES = {"president", "vice president", "secretary"}
VIEW_FINANCE_ROLES = {"treasurer", "president", "vice president"}
MANAGE_VENUE_ROLES = {"secretary", "president", "vice president"}

# Budget Health Indicator thresholds (simple % remaining, no AI/ML involved)
BUDGET_HEALTHY_MIN = 50   # >= 50% remaining -> Healthy
BUDGET_WARNING_MIN = 20   # 20-49% remaining -> Warning, below -> Critical


def compute_budget_health(allocated, spent):
    """Return a combined health label + score for a budget, e.g. '🟢 Healthy (72%)'.

    Percentage = remaining budget percentage. Band is based on predefined
    thresholds: Healthy >= 50%, Warning 20-49%, Critical < 20%.
    Returns score=None when there's no allocated budget to measure against,
    so callers can render a neutral state instead of a false "critical" bar.
    """
    allocated = float(allocated or 0)
    spent = float(spent or 0)
    if allocated <= 0:
        return "⚪ N/A", None

    remaining_pct = ((allocated - spent) / allocated) * 100
    score = max(0, min(100, round(remaining_pct)))

    if remaining_pct >= BUDGET_HEALTHY_MIN:
        label = "🟢 Healthy"
    elif remaining_pct >= BUDGET_WARNING_MIN:
        label = "🟡 Warning"
    else:
        label = "🔴 Critical"

    return f"{label} ({score}%)", score

# Available AUI majors (used for registration and profile dropdowns)
MAJORS = [
    "Business Administration",
    "Computer Science",
    "General Engineering",
    "Engineering & Management Science",
    "Renewable Energy Systems Engineering",
    "International studies",
    "Communication studies",
    "Environmental Studies & Sustainability",
    "Territorial Planning & Management",
    "Digital Humanities & Cultural Production",
    "Psychology",
  
]

TABLES = {
    "students": {
        "label": "Student Users",
        "table": "app_user",
        "pk": "user_id",
        "search_column": "user_id",
        "columns": [
            "user_id",
            "user_fname",
            "user_lname",
            "user_email",
            "user_phone",
        ],
        "fields": [
            ("User ID", "user_id"),
            ("First Name", "user_fname"),
            ("Last Name", "user_lname"),
            ("Email", "user_email"),
            ("Phone", "user_phone"),
        ],
    },
    "clubs": {
        "label": "Clubs",
        "table": "club",
        "pk": "club_id",
        "search_column": "club_name",
        "columns": [
            "club_id",
            "club_name",
            "category_id",
            "club_found_date",
            "club_description",
        ],
        "fields": [
            ("Club ID", "club_id"),
            ("Name", "club_name"),
            ("Category ID", "category_id"),
            ("Founded Date", "club_found_date"),
            ("Description", "club_description"),
        ],
    },
    "roles": {
        "label": "Roles",
        "table": "role",
        "pk": "role_id",
        "search_column": "role_name",
        "columns": ["role_id", "role_name", "role_description"],
        "fields": [
            ("Role Name", "role_name"),
            ("Description", "role_description"),
        ],
    },
    "venues": {
        "label": "Venues",
        "table": "venue",
        "pk": "venue_id",
        "search_column": "venue_name",
        "columns": ["venue_id", "venue_name", "venue_capacity", "venue_location"],
        "fields": [
            ("Venue Name", "venue_name"),
            ("Capacity", "venue_capacity"),
            ("Location", "venue_location"),
        ],
    },
    "sponsors": {
        "label": "Sponsors",
        "table": "sponsor",
        "pk": "sponsor_id",
        "search_column": "sponsor_name",
        "columns": [
            "sponsor_id",
            "sponsor_name",
            "sponsor_type",
            "sponsor_email",
            "sponsor_phone",
        ],
        "fields": [
            ("Name", "sponsor_name"),
            ("Type", "sponsor_type"),
            ("Email", "sponsor_email"),
            ("Phone", "sponsor_phone"),
        ],
        "dropdowns": {
            "sponsor_type": ["Corporate", "Individual", "Institutional"],
        },
    },
    "events": {
        "label": "Events",
        "table": "event",
        "pk": "event_id",
        "search_column": "event_name",
        "columns": [
            "event_id",
            "club_id",
            "venue_id",
            "event_name",
            "event_date",
            "event_status",
            "event_description",
        ],
        "fields": [
            ("Club ID", "club_id"),
            ("Venue ID", "venue_id"),
            ("Event Name", "event_name"),
            ("Event Date", "event_date"),
            ("Status", "event_status"),
            ("Description", "event_description"),
        ],
        "select_query": "SELECT event_id, club_id, venue_id, event_name, event_date, event_status, event_description FROM event ORDER BY event_id ASC",
        "dropdowns": {
            "event_status": ["Planned", "Ongoing", "Completed", "Cancelled"],
        },
    },
    "budgets": {
        "label": "Budgets",
        "table": "budget",
        "pk": "budget_id",
        "search_column": "club_id",
        "columns": [
            "budget_id",
            "club_id",
            "budget_year",
            "budget_allocated",
            "budget_spent",
            "budget_status",
            "budget_remaining",
            "health",
        ],
        "select_query": """
            SELECT budget_id, club_id, budget_year, budget_allocated, budget_spent,
                   budget_status,
                   (budget_allocated - budget_spent) AS budget_remaining,
                   CASE
                       WHEN budget_allocated <= 0 THEN '⚪ N/A'
                       WHEN ((budget_allocated - budget_spent) / budget_allocated) * 100 >= 50
                           THEN '🟢 Healthy (' || GREATEST(0, ROUND(((budget_allocated - budget_spent) / budget_allocated) * 100)) || '%%)'
                       WHEN ((budget_allocated - budget_spent) / budget_allocated) * 100 >= 20
                           THEN '🟡 Warning (' || GREATEST(0, ROUND(((budget_allocated - budget_spent) / budget_allocated) * 100)) || '%%)'
                       ELSE '🔴 Critical (' || GREATEST(0, ROUND(((budget_allocated - budget_spent) / budget_allocated) * 100)) || '%%)'
                   END AS health
            FROM budget
        """,
        "fields": [
            ("Club ID", "club_id"),
            ("Year", "budget_year"),
            ("Allocated", "budget_allocated"),
            ("Spent", "budget_spent"),
        ],
    },
    "budget-transactions": {
        "label": "Budget Transactions",
        "table": "budget_transaction",
        "pk": "transaction_id",
        "search_column": "club_id",
        "columns": [
            "transaction_id",
            "club_id",
            "budget_id",
            "transaction_date",
            "transaction_desc",
            "transaction_amount",
            "transaction_type",
            "recorded_by",
        ],
        "fields": [
            ("Club ID", "club_id"),
            ("Budget ID", "budget_id"),
            ("Date", "transaction_date"),
            ("Description", "transaction_desc"),
            ("Amount", "transaction_amount"),
            ("Type", "transaction_type"),
            ("Recorded By", "recorded_by"),
        ],
        "dropdowns": {
            "transaction_type": ["Expense", "Income", "Adjustment"],
        },
    },
    "memberships": {
        "label": "Memberships",
        "table": "membership",
        "pk": "memb_id",
        "search_column": "user_id",
        "columns": [
            "memb_id",
            "user_id",
            "club_id",
            "role_id",
            "memb_join_date",
            "memb_status",
        ],
        "fields": [
            ("User ID", "user_id"),
            ("Club ID", "club_id"),
            ("Role ID", "role_id"),
            ("Join Date", "memb_join_date"),
            ("Status", "memb_status"),
        ],
        "dropdowns": {
            "memb_status": ["Active", "Inactive", "Suspended"],
        },
        "select_query": "SELECT memb_id, user_id, club_id, role_id, memb_join_date, memb_status FROM membership ORDER BY memb_id ASC",
    },
    "attendance": {
        "label": "Attendance",
        "table": "attendance",
        "pk": "att_id",
        "search_column": "user_id",
        "columns": [
            "att_id",
            "user_id",
            "student_name",
            "event_id",
            "att_status",
            "att_timestamp",
        ],
        "fields": [
            ("User ID", "user_id"),
            ("Event ID", "event_id"),
            ("Status", "att_status"),
            ("Timestamp", "att_timestamp"),
        ],
        "dropdowns": {
            "att_status": ["Present", "Absent", "Excused"],
        },
        "select_query": "SELECT a.att_id, a.user_id, u.user_fname || ' ' || u.user_lname AS student_name, a.event_id, a.att_status, a.att_timestamp FROM attendance a LEFT JOIN app_user u ON u.user_id = a.user_id ORDER BY a.att_timestamp ASC, a.att_id ASC",
    },
    "sponsorships": {
        "label": "Sponsorships",
        "table": "sponsorship",
        "pk": "sponsor_record_id",
        "search_column": "club_id",
        "columns": [
            "sponsor_record_id",
            "sponsor_id",
            "club_id",
            "club_name",
            "spons_amount",
            "spons_date",
            "spons_type",
        ],
        "select_query": "SELECT sp.sponsor_record_id, sp.sponsor_id, sp.club_id, c.club_name, sp.spons_amount, sp.spons_date, sp.spons_type FROM sponsorship sp JOIN club c ON c.club_id = sp.club_id ORDER BY sp.sponsor_record_id ASC",
        "fields": [
            ("Sponsor ID", "sponsor_id"),
            ("Club ID", "club_id"),
            ("Amount", "spons_amount"),
            ("Date", "spons_date"),
            ("Type", "spons_type"),
        ],
    },
}


VIEWS = {
    "membership": {
        "label": "Membership View",
        "view": "v_membership_details",
        "search_column": "student_name",
        "columns": [
            "memb_id",
            "stu_id",
            "student_name",
            "user_email",
            "club_id",
            "club_name",
            "role_name",
            "memb_join_date",
            "memb_status",
        ],
    },
    "events": {
        "label": "Event View",
        "view": "v_event_details",
        "search_column": "event_name",
        "columns": [
            "event_id",
            "event_name",
            "club_name",
            "venue_name",
            "venue_location",
            "event_date",
            "event_status",
            "event_description",
        ],
    },
    "attendance": {
        "label": "Attendance View",
        "view": "v_attendance_report",
        "search_column": "student_name",
        "columns": [
            "att_id",
            "stu_id",
            "student_name",
            "event_name",
            "event_date",
            "att_status",
            "att_timestamp",
        ],
    },
    "sponsorship": {
        "label": "Sponsorship View",
        "view": "v_sponsorship_report",
        "search_column": "sponsor_name",
        "columns": [
            "sponsor_record_id",
            "sponsor_name",
            "sponsor_type",
            "club_name",
            "spons_amount",
            "spons_date",
            "spons_type",
        ],
    },
    "club-summary": {
        "label": "Club Summary",
        "view": "v_club_activity_summary",
        "search_column": "club_name",
        "columns": [
            "club_id",
            "club_name",
            "active_members",
            "total_events",
            "total_sponsorship",
            "latest_budget_allocated",
            "latest_budget_spent",
            "budget_remaining",
        ],
        "create_sql": """
            CREATE OR REPLACE VIEW v_club_activity_summary AS
            SELECT
                c.club_id,
                c.club_name,
                COUNT(DISTINCT m.memb_id) FILTER (WHERE m.memb_status = 'Active') AS active_members,
                COUNT(DISTINCT e.event_id) AS total_events,
                COALESCE(SUM(DISTINCT sp.spons_amount), 0) AS total_sponsorship,
                COALESCE(MAX(b.budget_allocated), 0) AS latest_budget_allocated,
                COALESCE(MAX(b.budget_spent), 0) AS latest_budget_spent,
                COALESCE(MAX(b.budget_allocated), 0) - COALESCE(MAX(b.budget_spent), 0) AS budget_remaining
            FROM club c
            LEFT JOIN membership m ON m.club_id = c.club_id
            LEFT JOIN event e ON e.club_id = c.club_id
            LEFT JOIN sponsorship sp ON sp.club_id = c.club_id
            LEFT JOIN budget b ON b.club_id = c.club_id
            GROUP BY c.club_id, c.club_name
        """,
    },
    "active-directory": {
        "label": "Active Directory",
        "view": "v_active_student_directory",
        "search_column": "student_name",
        "columns": ["stu_id", "student_name", "user_email", "stu_major"],
        "create_sql": """
            CREATE OR REPLACE VIEW v_active_student_directory AS
            SELECT DISTINCT
                u.user_id AS stu_id,
                u.user_fname || ' ' || u.user_lname AS student_name,
                u.user_email,
                s.stu_major
            FROM student s
            JOIN app_user u ON u.user_id = s.user_id
            JOIN membership m ON m.user_id = s.user_id
            WHERE m.memb_status = 'Active'
        """,
    },
    "advanced-audit-log": {
        "label": "Advanced Audit Log",
        "view": "advanced_audit_log",
        "search_column": "table_name",
        "columns": [
            "audit_id",
            "table_name",
            "operation_type",
            "record_pk",
            "changed_by",
            "changed_at",
            "old_data",
            "new_data",
            "note",
        ],
        "select_query": """
            SELECT audit_id, table_name, operation_type, record_pk, changed_by,
                   changed_at, old_data, new_data, note
            FROM advanced_audit_log
            ORDER BY audit_id DESC
        """,
    },
    "budget-alerts": {
        "label": "Budget Alerts",
        "view": "budget_alert",
        "search_column": "club_id",
        "columns": [
            "alert_id",
            "club_id",
            "budget_year",
            "alert_message",
            "created_at",
            "resolved",
        ],
    },
}


def admin_nav():
    return {
        "tables": TABLES,
        "views": VIEWS,
    }


@app.context_processor
def inject_nav():
    return {
        "admin_nav": admin_nav(),
        "is_admin": session.get("admin") is True,
        "is_club_admin": session.get("club_admin") is True,
        "student_email": session.get("student_email"),
        "today": date.today().isoformat(),
    }


@contextmanager
def db_cursor(commit=False):
    conn = get_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        yield cursor
        if commit:
            conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        cursor.close()
        conn.close()


def clean_value(value):
    value = value.strip() if isinstance(value, str) else value
    return None if value == "" else value


def form_values(keys):
    return [clean_value(request.form.get(key, "")) for key in keys]


def hash_password(password):
    return generate_password_hash(password, method="pbkdf2:sha256")


def verify_password(password, password_hash):
    return bool(password_hash) and check_password_hash(password_hash, password)


def login_required(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if not session.get("admin"):
            flash("Please sign in as admin first.", "warning")
            return redirect(url_for("admin_login"))
        return view(*args, **kwargs)

    return wrapped


def student_required(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if not session.get("student_email"):
            flash("Please sign in to the student portal first.", "warning")
            return redirect(url_for("student_access"))
        return view(*args, **kwargs)

    return wrapped

def club_admin_required(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if not session.get("student_email"):
            flash("Please sign in to the student portal first.", "warning")
            return redirect(url_for("student_access"))
        if not session.get("club_admin"):
            flash("Club administrator access required.", "error")
            return redirect(url_for("student_portal"))
        return view(*args, **kwargs)
    return wrapped


def has_club_role(cursor, user_id, club_id, allowed_roles):
    """Check whether user_id holds one of allowed_roles in the given club.

    Replaces the old (nonexistent) `club_admin` table lookup with a real
    membership + role check, same as the rest of the club admin portal uses.
    """
    cursor.execute(
        "SELECT lower(r.role_name) AS role_name "
        "FROM membership m "
        "JOIN role r ON r.role_id = m.role_id "
        "WHERE m.user_id = %s AND m.club_id = %s",
        (user_id, club_id),
    )
    roles = {row["role_name"] for row in cursor.fetchall()}
    return bool(roles & allowed_roles)


def get_config(mapping, slug):
    config = mapping.get(slug)
    if config is None:
        flash("That page does not exist.", "error")
        return None
    return config


def build_search_query(config, source_key):
    search = request.args.get("q", "").strip()
    columns = config["columns"]
    source = config[source_key]
    base_query = config.get("select_query") or f"SELECT {', '.join(columns)} FROM {source}"
    query = f"SELECT * FROM ({base_query}) AS search_source"
    params = []
    if search:
        search_clauses = [f"CAST({column} AS TEXT) ILIKE %s" for column in columns]
        query += " WHERE " + " OR ".join(search_clauses)
        params = [f"%{search}%"] * len(columns)
    return query, params, search


def load_rows(config, source_key):
    query, params, search = build_search_query(config, source_key)

    with db_cursor() as cursor:
        if config.get("create_sql"):
            cursor.execute(config["create_sql"])
            cursor.connection.commit()
        cursor.execute(query, params)
        rows = cursor.fetchall()
    return rows, search


def load_table_record(config, pk_value):
    if not pk_value:
        return None
    with db_cursor() as cursor:
        cursor.execute(
            f"SELECT * FROM {config['table']} WHERE {config['pk']} = %s",
            (pk_value,),
        )
        return cursor.fetchone()


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/admin/login", methods=["GET", "POST"])
def admin_login():
    if request.method == "POST":
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "")
        if username == "admin" and password == "nimda":
            session.pop("student_email", None)
            session.pop("club_admin", None)
            session["admin"] = True
            flash("Signed in to the admin dashboard.", "success")
            return redirect(url_for("admin_home"))
        flash("Invalid admin credentials.", "error")
    return render_template("admin_login.html")


@app.route("/admin/logout")
def admin_logout():
    session.pop("admin", None)
    session.pop("student_email", None)
    session.pop("club_admin", None)
    flash("Signed out of admin.", "success")
    return redirect(url_for("index"))


@app.route("/admin")
@login_required
def admin_home():
    return redirect(url_for("table_page", slug="students"))


@app.route("/admin/role-assignments", methods=["GET", "POST"])
@login_required
def role_assignments():
    """Manage the role a student holds in each club membership."""
    if request.method == "POST":
        action = request.form.get("action", "")
        try:
            with db_cursor(commit=True) as cursor:
                if action == "assign":
                    user_id = clean_value(request.form.get("user_id", ""))
                    club_id = clean_value(request.form.get("club_id", ""))
                    role_id = clean_value(request.form.get("role_id", ""))
                    if not user_id or not club_id or not role_id:
                        raise ValueError("Choose a student, club, and role.")

                    # A membership must reference a student, not merely any app user.
                    cursor.execute(
                        "SELECT 1 FROM student WHERE user_id = %s", (user_id,)
                    )
                    if not cursor.fetchone():
                        raise ValueError("The selected user is not a student.")

                    cursor.execute(
                        "SELECT memb_id, role_id, memb_status FROM membership "
                        "WHERE user_id = %s AND club_id = %s",
                        (user_id, club_id),
                    )
                    existing_membership = cursor.fetchone()

                    if existing_membership:
                        cursor.execute(
                            "UPDATE membership "
                            "SET role_id = %s, memb_status = 'Active' "
                            "WHERE memb_id = %s",
                            (role_id, existing_membership["memb_id"]),
                        )
                        flash("Role updated for the existing membership.", "success")
                    else:
                        cursor.execute(
                            "INSERT INTO membership "
                            "(user_id, club_id, role_id, memb_join_date, memb_status) "
                            "VALUES (%s, %s, %s, CURRENT_DATE, 'Active')",
                            (user_id, club_id, role_id),
                        )
                        flash("Role assigned.", "success")
                elif action == "remove":
                    memb_id = clean_value(request.form.get("memb_id", ""))
                    if not memb_id:
                        raise ValueError("Choose a role assignment to remove.")
                    cursor.execute(
                        "UPDATE membership SET role_id = NULL WHERE memb_id = %s",
                        (memb_id,),
                    )
                    if cursor.rowcount == 0:
                        raise ValueError("That role assignment no longer exists.")
                    flash("Role removed. The student remains a member of the club.", "success")
                else:
                    raise ValueError("Unknown role action.")
        except (ValueError, psycopg2.Error) as exc:
            flash(str(exc).strip(), "error")
        return redirect(url_for("role_assignments"))

    search = request.args.get("q", "").strip()
    query = """
        SELECT
            m.memb_id,
            u.user_id,
            u.user_fname || ' ' || u.user_lname AS student_name,
            c.club_id,
            c.club_name,
            r.role_id,
            COALESCE(r.role_name, 'No role assigned') AS role_name,
            m.memb_status
        FROM student s
        JOIN app_user u ON u.user_id = s.user_id
        LEFT JOIN membership m ON m.user_id = s.user_id
        LEFT JOIN club c ON c.club_id = m.club_id
        LEFT JOIN role r ON r.role_id = m.role_id
    """
    params = []
    if search:
        query += """
            WHERE u.user_id ILIKE %s
               OR COALESCE(c.club_id, '') ILIKE %s
               OR COALESCE(CAST(r.role_id AS TEXT), '') ILIKE %s
               OR CONCAT_WS(' ', u.user_fname, u.user_lname) ILIKE %s
               OR u.user_fname ILIKE %s
               OR u.user_lname ILIKE %s
               OR COALESCE(c.club_name, '') ILIKE %s
               OR COALESCE(r.role_name, '') ILIKE %s
               OR COALESCE(m.memb_status, '') ILIKE %s
        """
        params = [f"%{search}%"] * 9
    query += " ORDER BY u.user_id, c.club_name NULLS FIRST"

    with db_cursor() as cursor:
        cursor.execute(query, params)
        assignments = cursor.fetchall()
        cursor.execute(
            "SELECT u.user_id, u.user_fname, u.user_lname "
            "FROM student s JOIN app_user u ON u.user_id = s.user_id "
            "ORDER BY u.user_id"
        )
        students = cursor.fetchall()
        cursor.execute("SELECT club_id, club_name FROM club ORDER BY club_name")
        clubs = cursor.fetchall()
        cursor.execute("SELECT role_id, role_name FROM role ORDER BY role_name")
        roles = cursor.fetchall()

    return render_template(
        "role_assignments.html",
        assignments=assignments,
        students=students,
        clubs=clubs,
        roles=roles,
        search=search,
    )


@app.route("/admin/table/<slug>", methods=["GET", "POST"])
@login_required
def table_page(slug):
    config = get_config(TABLES, slug)
    if config is None:
        return redirect(url_for("admin_home"))

    if request.method == "POST":
        action = request.form.get("action")
        fields = [field for _, field in config["fields"]]
        try:
            with db_cursor(commit=True) as cursor:
                if action == "insert":
                    values = form_values(fields)
                    placeholders = ", ".join(["%s"] * len(fields))
                    cursor.execute(
                        f"INSERT INTO {config['table']} ({', '.join(fields)}) "
                        f"VALUES ({placeholders})",
                        values,
                    )
                    flash("Record inserted.", "success")
                elif action == "update":
                    pk_value = clean_value(request.form.get("pk_value", ""))
                    values = form_values(fields)
                    set_clause = ", ".join([f"{field} = %s" for field in fields])
                    cursor.execute(
                        f"UPDATE {config['table']} SET {set_clause} "
                        f"WHERE {config['pk']} = %s",
                        values + [pk_value],
                    )
                    flash("Record updated.", "success")
                elif action == "delete":
                    pk_value = clean_value(request.form.get("pk_value", ""))
                    cursor.execute(
                        f"DELETE FROM {config['table']} WHERE {config['pk']} = %s",
                        (pk_value,),
                    )
                    flash("Record deleted.", "success")
                else:
                    flash("Unknown action.", "error")
        except psycopg2.Error as exc:
            flash(str(exc).strip(), "error")
        return redirect(url_for("table_page", slug=slug))

    rows, search = load_rows(config, "table")
    edit_value = request.args.get("edit", "")
    edit_record = load_table_record(config, edit_value)
    return render_template(
        "table_page.html",
        slug=slug,
        config=config,
        rows=rows,
        search=search,
        edit_record=edit_record,
    )


@app.route("/admin/view/<slug>")
@login_required
def view_page(slug):
    config = get_config(VIEWS, slug)
    if config is None:
        return redirect(url_for("admin_home"))

    try:
        rows, search = load_rows(config, "view")
    except psycopg2.Error as exc:
        flash(str(exc).strip(), "error")
        rows, search = [], request.args.get("q", "").strip()

    return render_template(
        "view_page.html",
        slug=slug,
        config=config,
        rows=rows,
        search=search,
    )


@app.route("/student", methods=["GET", "POST"])
def student_access():
    if session.get("student_email"):
        return redirect(url_for("student_portal"))

    session.pop("admin", None)
    session.pop("club_admin", None)

    if request.method == "POST":
        # login-only on this page; registration has its own interface
        email = request.form.get("stu_email", "").strip().lower()
        password = request.form.get("stu_password", "")

        if "@" not in email or "." not in email:
            flash("Enter a valid email address.", "warning")
            return redirect(url_for("student_access"))

        if not password:
            flash("Password is required to sign in.", "warning")
            return redirect(url_for("student_access"))

        student = get_student_by_email(email)
        if not student or not verify_password(password, student.get("stu_password")):
            flash("Invalid email or password.", "error")
            return redirect(url_for("student_access"))

        session.pop("admin", None)
        session["student_email"] = email
        session["club_admin"] = False

        try:
            conn = get_connection()
            cursor = conn.cursor()

            cursor.execute("""
                SELECT 1
                FROM membership m
                JOIN role r ON r.role_id = m.role_id
                WHERE lower(r.role_name) = ANY(%s)
                  AND m.user_id = (
                        SELECT user_id
                        FROM app_user
                        WHERE lower(user_email) = %s
                  )
                LIMIT 1
            """, (list(CLUB_ADMIN_ROLES), email,))

            session["club_admin"] = cursor.fetchone() is not None

            cursor.close()
            conn.close()

        except Exception:
            pass

        return redirect(url_for("student_portal"))

    return render_template("student_access.html")


@app.route("/student/register", methods=["GET", "POST"])
def student_register():
    if session.get("student_email"):
        return redirect(url_for("student_portal"))

    if request.method == "POST":
        email = request.form.get("stu_email", "").strip().lower()
        password = request.form.get("stu_password", "")

        data = {
            "stu_fname": request.form.get("stu_fname", "").strip(),
            "stu_lname": request.form.get("stu_lname", "").strip(),
            "stu_email": email,
            "stu_major": request.form.get("stu_major", "").strip(),
            "stu_year": request.form.get("stu_year", "").strip(),
            "stu_phone": request.form.get("stu_phone", "").strip(),
            "stu_password": password,
            "stu_password_confirm": request.form.get("stu_password_confirm", ""),
        }

        if "@" not in email or "." not in email:
            flash("Enter a valid email address.", "warning")
            return redirect(url_for("student_register"))

        if not data["stu_fname"] or not data["stu_lname"]:
            flash("First name and last name are required.", "warning")
            return redirect(url_for("student_register"))
        if not data["stu_password"] or len(data["stu_password"]) < 6:
            flash("Password must be at least 6 characters.", "warning")
            return redirect(url_for("student_register"))
        if data["stu_password"] != data["stu_password_confirm"]:
            flash("Passwords do not match.", "warning")
            return redirect(url_for("student_register"))

        try:
            auto_register_student(data)
        except (ValueError, psycopg2.Error) as exc:
            flash(str(exc).strip(), "error")
            return redirect(url_for("student_register"))

        # auto-login after successful registration
        session.pop("admin", None)
        session["student_email"] = email
        session["club_admin"] = False
        return redirect(url_for("student_portal"))

    return render_template("student_register.html", majors=MAJORS)


@app.route("/student/logout")
def student_logout():
    session.pop("student_email", None)
    session.pop("club_admin", None)
    flash("Signed out of the student portal.", "success")
    return redirect(url_for("index"))


def auto_register_student(data):
    year = parse_year(data.get("stu_year"))
    with db_cursor(commit=True) as cursor:
        cursor.execute(
            "SELECT 1 FROM app_user WHERE lower(user_email) = %s",
            (data["stu_email"],),
        )
        if cursor.fetchone():
            raise ValueError("An account with that email already exists.")

        cursor.execute(
            "SELECT COALESCE(MAX(CAST(SUBSTRING(user_id FROM 2) AS INT)), 0) + 1 "
            "AS next_id FROM app_user WHERE user_id ~ '^S[0-9]+$'"
        )
        user_id = f"S{cursor.fetchone()['next_id']:03d}"

        password_hash = hash_password(data["stu_password"])
        cursor.execute(
            "INSERT INTO app_user "
            "(user_id, user_fname, user_lname, user_email, user_phone) "
            "VALUES (%s, %s, %s, %s, %s)",
            (
                user_id,
                data["stu_fname"],
                data["stu_lname"],
                data["stu_email"],
                clean_value(data.get("stu_phone", "")),
            ),
        )
        cursor.execute(
            "INSERT INTO login (user_id, user_password) VALUES (%s, %s)",
            (user_id, password_hash),
        )
        cursor.execute(
            "INSERT INTO student (user_id, stu_major, stu_year) VALUES (%s, %s, %s)",
            (
                user_id,
                clean_value(data.get("stu_major", "")),
                year,
            ),
        )


def parse_year(value):
    value = clean_value(value)
    if value is None:
        return None
    try:
        year = int(value)
    except ValueError as exc:
        raise ValueError("Year must be a number from 1 to 6.") from exc
    if year < 1 or year > 6:
        raise ValueError("Year must be between 1 and 6.")
    return year


def get_student_by_email(email):
    with db_cursor() as cursor:
        cursor.execute(
            "SELECT u.user_id AS stu_id, u.user_fname AS stu_fname, u.user_lname AS stu_lname, u.user_email AS stu_email, "
            "u.user_phone AS stu_phone, s.stu_major, s.stu_year, l.user_password AS stu_password "
            "FROM app_user u "
            "LEFT JOIN student s ON s.user_id = u.user_id "
            "LEFT JOIN login l ON l.user_id = u.user_id "
            "WHERE lower(u.user_email) = %s",
            (email,),
        )
        return cursor.fetchone()


@app.route("/student/portal")
@student_required
def student_portal():
    email = session["student_email"]
    student = get_student_by_email(email)
    clubs = []
    memberships = []
    events = []
    attendance_records = []

    with db_cursor() as cursor:
        if student:
            cursor.execute(
                "SELECT c.club_id, c.club_name, cat.category_name AS club_category, "
                "(SELECT COUNT(*) FROM membership m "
                " WHERE m.club_id = c.club_id AND m.memb_status = 'Active') "
                "AS active_members, c.club_description "
                "FROM club c "
                "JOIN club_category cat ON cat.category_id = c.category_id "
                "WHERE NOT EXISTS ("
                "    SELECT 1 FROM membership m_self "
                "    WHERE m_self.club_id = c.club_id AND m_self.user_id = %s"
                ") "
                "ORDER BY c.club_id ASC",
                (student["stu_id"],),
            )
            clubs = cursor.fetchall()

            cursor.execute(
                "SELECT m.memb_id, c.club_name, r.role_name, "
                "m.memb_join_date, m.memb_status "
                "FROM membership m "
                "JOIN club c ON c.club_id = m.club_id "
                "JOIN role r ON r.role_id = m.role_id "
                "WHERE m.user_id = %s "
                "ORDER BY c.club_id ASC, m.memb_id ASC",
                (student["stu_id"],),
            )
            memberships = cursor.fetchall()
        else:
            cursor.execute(
                "SELECT c.club_id, c.club_name, cat.category_name AS club_category, "
                "(SELECT COUNT(*) FROM membership m "
                " WHERE m.club_id = c.club_id AND m.memb_status = 'Active') "
                "AS active_members, c.club_description "
                "FROM club c "
                "JOIN club_category cat ON cat.category_id = c.category_id "
                "ORDER BY c.club_id ASC"
            )
            clubs = cursor.fetchall()

        if student:
            cursor.execute(
                "SELECT DISTINCT e.event_id, e.event_name, e.event_date, e.event_status, c.club_name, v.venue_name "
                "FROM event e "
                "JOIN club c ON c.club_id = e.club_id "
                "JOIN venue v ON v.venue_id = e.venue_id "
                "JOIN membership m ON m.club_id = e.club_id "
                "WHERE m.user_id = %s "
                "ORDER BY e.event_date DESC",
                (student["stu_id"],),
            )
            events = cursor.fetchall()

            cursor.execute(
                "SELECT a.att_id, a.event_id, e.event_name, e.event_date, c.club_name, a.att_status, a.att_timestamp "
                "FROM attendance a "
                "JOIN event e ON e.event_id = a.event_id "
                "JOIN club c ON c.club_id = e.club_id "
                "WHERE a.user_id = %s "
                "ORDER BY a.att_timestamp ASC",
                (student["stu_id"],),
            )
            attendance_records = cursor.fetchall()

    return render_template(
        "student_portal.html",
        student=student,
        clubs=clubs,
        memberships=memberships,
        events=events,
        attendance_records=attendance_records,
        majors=MAJORS,
    )


@app.route("/student/club_admin", methods=["GET", "POST"])
@club_admin_required
def club_admin_portal():
    email = session["student_email"]
    student = get_student_by_email(email)
    clubs = []
    selected_club_id = request.values.get("club_id")
    # allow focused single-section views via ?section=events|budgets|members|attendance|sponsorships
    active_section = request.values.get("section")
    if active_section == "venues":
        active_section = None
    club_members = []
    club_budgets = []
    club_transactions = []
    club_events = []
    club_sponsorships = []
    venues = []
    club_roles = []
    all_students = []
    can_manage_all = False
    can_manage_events = False
    can_view_finance = False
    can_manage_venues = False

    if request.method == "POST":
        action = request.form.get("action", "")
        selected_club_id = request.form.get("club_id") or selected_club_id
        try:
            with db_cursor(commit=True) as cursor:
                cursor.execute(
                    "SELECT lower(r.role_name) AS role_name "
                    "FROM membership m "
                    "JOIN role r ON r.role_id = m.role_id "
                    "WHERE m.user_id = %s AND m.club_id = %s",
                    (student["stu_id"], selected_club_id),
                )
                club_roles = [row["role_name"] for row in cursor.fetchall()]
                can_manage_all = any(role in MANAGE_ALL_ROLES for role in club_roles)
                can_manage_events = any(role in MANAGE_EVENTS_ROLES for role in club_roles)
                can_view_finance = any(role in VIEW_FINANCE_ROLES for role in club_roles)
                can_manage_venues = any(role in MANAGE_VENUE_ROLES for role in club_roles)

                if action == "create_event":
                    if not can_manage_events:
                        raise psycopg2.Error("Not authorized to create events for this club.")
                    # gather form values and check for existing identical event first
                    ev_name = request.form.get("event_name", "").strip()
                    ev_date = request.form.get("event_date", "").strip()
                    ev_venue = request.form.get("venue_id")
                    ev_status = request.form.get("event_status", "Planned").strip()
                    ev_desc = request.form.get("event_description", "").strip()

                    cursor.execute(
                        "SELECT 1 FROM event WHERE club_id = %s AND event_name = %s AND event_date = %s LIMIT 1",
                        (selected_club_id, ev_name, ev_date),
                    )
                    if cursor.fetchone():
                        flash("An event with the same name and date already exists for this club.", "error")
                    else:
                        cursor.execute(
                            "INSERT INTO event (club_id, venue_id, event_name, event_date, event_status, event_description) "
                            "VALUES (%s, %s, %s, %s, %s, %s)",
                            (selected_club_id, ev_venue, ev_name, ev_date, ev_status, ev_desc),
                        )
                        flash("Event created for the selected club.", "success")
                elif action == "update_event_status":
                    if not can_manage_events:
                        raise psycopg2.Error("Not authorized to update events for this club.")
                    event_id = request.form.get("event_id", "").strip()
                    event_status = request.form.get("event_status", "Planned").strip()
                    if not event_id:
                        raise ValueError("Choose an event to update.")
                    cursor.execute(
                        "UPDATE event SET event_status = %s "
                        "WHERE event_id = %s AND club_id = %s",
                        (event_status, event_id, selected_club_id),
                    )
                    if cursor.rowcount == 0:
                        raise psycopg2.Error("Event not found for the selected club.")
                    flash("Event status updated.", "success")
                elif action == "record_attendance":
                    if not can_manage_all:
                        raise psycopg2.Error("Not authorized to record attendance for this club.")
                    cursor.execute(
                        "CALL sp_record_attendance(%s, %s, %s)",
                        (
                            request.form.get("stu_id", "").strip(),
                            request.form.get("event_id", ""),
                            request.form.get("att_status", "Present").strip(),
                        ),
                    )
                    flash("Attendance recorded.", "success")
                elif action == "update_venue":
                    if not can_manage_venues:
                        raise psycopg2.Error("Not authorized to update venues for this club.")
                    cursor.execute(
                        "UPDATE venue SET venue_name = %s, venue_capacity = %s, venue_location = %s "
                        "WHERE venue_id = %s",
                        (
                            request.form.get("venue_name", "").strip(),
                            request.form.get("venue_capacity", ""),
                            request.form.get("venue_location", "").strip(),
                            request.form.get("venue_id", ""),
                        ),
                    )
                    flash("Venue updated.", "success")
        except psycopg2.IntegrityError as ie:
            # handle unique violations with a friendlier message
            pgcode = getattr(ie, 'pgcode', None)
            if pgcode == '23505':
                flash('A record with the same unique fields already exists.', 'error')
            else:
                flash(str(ie).strip(), 'error')
        except psycopg2.Error as exc:
            flash(str(exc).strip(), 'error')
        return redirect(url_for("club_admin_portal", club_id=selected_club_id))

    with db_cursor() as cursor:
        cursor.execute(
            "SELECT c.club_id, c.club_name, c.category_id, cat.category_name AS club_category, "
            "c.club_found_date, c.club_description, "
            "COUNT(*) FILTER (WHERE m_all.memb_status = 'Active') AS active_members "
            "FROM club c "
            "JOIN membership m ON m.club_id = c.club_id "
            "JOIN role r ON r.role_id = m.role_id "
            "JOIN club_category cat ON cat.category_id = c.category_id "
            "LEFT JOIN membership m_all ON m_all.club_id = c.club_id "
            "WHERE m.user_id = %s AND lower(r.role_name) = ANY(%s) "
            "GROUP BY c.club_id, c.club_name, c.category_id, cat.category_name, c.club_found_date, c.club_description "
            "ORDER BY c.club_name",
            (student["stu_id"], list(CLUB_ADMIN_ROLES)),
        )
        clubs = cursor.fetchall()
        
        # Fetch all students for member selection in club admin
        cursor.execute(
            "SELECT u.user_id, u.user_fname, u.user_lname "
            "FROM app_user u "
            "ORDER BY u.user_id ASC"
        )
        all_students = cursor.fetchall()

        if not selected_club_id and clubs:
            selected_club_id = clubs[0]["club_id"]

        if selected_club_id:
            cursor.execute(
                "SELECT m.memb_id, u.user_id AS stu_id, u.user_fname AS stu_fname, u.user_lname AS stu_lname, r.role_name, m.memb_status "
                "FROM membership m "
                "JOIN app_user u ON u.user_id = m.user_id "
                "JOIN role r ON r.role_id = m.role_id "
                "WHERE m.club_id = %s "
                "ORDER BY m.memb_id ASC",
                (selected_club_id,),
            )
            club_members = cursor.fetchall()

            cursor.execute(
                "SELECT lower(r.role_name) AS role_name "
                "FROM membership m "
                "JOIN role r ON r.role_id = m.role_id "
                "WHERE m.user_id = %s AND m.club_id = %s",
                (student["stu_id"], selected_club_id),
            )
            club_roles = [row["role_name"] for row in cursor.fetchall()]
            can_manage_all = any(role in MANAGE_ALL_ROLES for role in club_roles)
            can_manage_events = any(role in MANAGE_EVENTS_ROLES for role in club_roles)
            can_view_finance = any(role in VIEW_FINANCE_ROLES for role in club_roles)
            can_manage_venues = any(role in MANAGE_VENUE_ROLES for role in club_roles)

            cursor.execute(
                "SELECT b.budget_id, b.club_id, c.club_name, b.budget_year, b.budget_allocated, b.budget_spent, b.budget_status, "
                "(budget_allocated - budget_spent) AS budget_remaining "
                "FROM budget b "
                "JOIN club c ON c.club_id = b.club_id "
                "WHERE b.club_id = %s "
                "ORDER BY b.budget_year DESC",
                (selected_club_id,),
            )
            club_budgets = cursor.fetchall()
            for budget in club_budgets:
                label, score = compute_budget_health(
                    budget["budget_allocated"], budget["budget_spent"]
                )
                budget["health"] = label
                budget["health_score"] = score

            club_transactions = []
            if can_view_finance:
                cursor.execute(
                    "SELECT transaction_id, transaction_date, transaction_desc, "
                    "transaction_amount, transaction_type, recorded_by "
                    "FROM budget_transaction "
                    "WHERE club_id = %s "
                    "ORDER BY transaction_date DESC, transaction_id DESC",
                    (selected_club_id,),
                )
                club_transactions = cursor.fetchall()

            cursor.execute(
                "SELECT e.event_id, e.event_name, e.event_date, e.event_status, e.event_description, v.venue_name "
                "FROM event e "
                "JOIN venue v ON v.venue_id = e.venue_id "
                "WHERE e.club_id = %s "
                "ORDER BY e.event_id ASC",
                (selected_club_id,),
            )
            club_events = cursor.fetchall()

            cursor.execute(
                "SELECT sp.sponsor_record_id, s.sponsor_name, sp.club_id, sp.spons_amount, sp.spons_date, sp.spons_type "
                "FROM sponsorship sp "
                "JOIN sponsor s ON s.sponsor_id = sp.sponsor_id "
                "WHERE sp.club_id = %s "
                "ORDER BY sp.sponsor_record_id ASC",
                (selected_club_id,),
            )
            club_sponsorships = cursor.fetchall()

            cursor.execute(
                "SELECT a.att_id, a.user_id AS stu_id, u.user_fname AS stu_fname, u.user_lname AS stu_lname, e.event_name, a.att_status, a.att_timestamp "
                "FROM attendance a "
                "JOIN event e ON e.event_id = a.event_id "
                "JOIN app_user u ON u.user_id = a.user_id "
                "WHERE e.club_id = %s "
                "ORDER BY a.att_timestamp ASC, a.att_id ASC",
                (selected_club_id,),
            )
            attendance_records = cursor.fetchall()
        else:
            attendance_records = []

        cursor.execute(
            "SELECT venue_id, venue_name, venue_capacity, venue_location "
            "FROM venue "
            "ORDER BY venue_name"
        )
        venues = cursor.fetchall()
        
        # Clean venue locations of UTF-8 encoding issues
        for venue in venues:
            if venue['venue_location']:
                location = str(venue['venue_location'])
                
                # Try to fix double-encoded UTF-8 by re-encoding
                for attempt in range(3):
                    try:
                        location = location.encode('iso-8859-1').decode('utf-8')
                    except:
                        break
                
                # Handle mojibake em dash (â€") - the problematic character
                # This is UTF-8 em dash (U+2014) misread as Latin-1
                # Try multiple encoding byte sequences for em dash
                location = location.replace('â€"', ', ')     # Most common mojibake em dash
                location = location.replace('â\x80\x94', ', ')  # Byte sequence for em dash
                location = location.replace('â€\x94', ', ')     # Another variant
                
                # Handle other common mojibake patterns
                location = location.replace('â€"', ', ')      # Variant 1
                location = location.replace('â€˜', '')        # Left single quote
                location = location.replace('â€™', '')        # Right single quote
                location = location.replace('â€œ', '"')       # Left double quote
                location = location.replace('â€\x9d', '"')    # Right double quote
                location = location.replace('â\x80\x93', '-')  # en dash
                location = location.replace('â\x80\x98', '')   # left single quote
                location = location.replace('â\x80\x99', '')   # right single quote
                location = location.replace('â\x80\x9c', '"')  # left double quote
                location = location.replace('â\x80\x9d', '"')  # right double quote
                
                # Unicode character replacements (if some are stored correctly)
                location = location.replace('\u2013', '-')
                location = location.replace('\u2014', ', ')
                location = location.replace('\u2018', '')
                location = location.replace('\u2019', '')
                location = location.replace('\u201c', '"')
                location = location.replace('\u201d', '"')
                
                # Catch any remaining â€ sequences and replace with comma
                import re
                location = re.sub(r'â€["\'\-–—]', ', ', location, flags=re.IGNORECASE)
                location = re.sub(r'â\s*€\s*["\'\-–—]', ', ', location, flags=re.IGNORECASE)
                
                # Clean up whitespace
                while '  ' in location:
                    location = location.replace('  ', ' ')
                
                venue['venue_location'] = location.strip()

    return render_template(
        "club_admin_portal.html",
        student=student,
        clubs=clubs,
        selected_club_id=selected_club_id,
        club_members=club_members,
        club_budgets=club_budgets,
        club_transactions=club_transactions,
        club_events=club_events,
        club_sponsorships=club_sponsorships,
        venues=venues,
        attendance_records=attendance_records,
        can_manage_all=can_manage_all,
        can_manage_events=can_manage_events,
        can_view_finance=can_view_finance,
        can_manage_venues=can_manage_venues,
        club_roles=club_roles,
        active_section=active_section,
        all_students=all_students,
    )


@app.route("/student/profile", methods=["POST"])
@student_required
def save_student_profile():
    email = session["student_email"]
    student = get_student_by_email(email)
    data = {
        "stu_id": request.form.get("stu_id", "").strip(),
        "stu_fname": request.form.get("stu_fname", "").strip(),
        "stu_lname": request.form.get("stu_lname", "").strip(),
        "stu_email": request.form.get("stu_email", "").strip().lower(),
        "stu_major": request.form.get("stu_major", "").strip(),
        "stu_year": request.form.get("stu_year", "").strip(),
        "stu_phone": request.form.get("stu_phone", "").strip(),
    }
    if not data["stu_id"] or not data["stu_fname"] or not data["stu_lname"] or not data["stu_email"]:
        flash("Student ID, first name, last name, and email are required.", "warning")
        return redirect(url_for("student_portal"))

    try:
        year = parse_year(data["stu_year"])
        with db_cursor(commit=True) as cursor:
            cursor.execute(
                "UPDATE app_user SET user_fname=%s, user_lname=%s, user_email=%s, user_phone=%s WHERE user_id=%s",
                (
                    data["stu_fname"],
                    data["stu_lname"],
                    data["stu_email"],
                    clean_value(data["stu_phone"]),
                    student["stu_id"],
                ),
            )
            cursor.execute(
                "INSERT INTO student (user_id, stu_major, stu_year) "
                "VALUES (%s, %s, %s) "
                "ON CONFLICT (user_id) DO UPDATE SET stu_major = EXCLUDED.stu_major, stu_year = EXCLUDED.stu_year",
                (
                    student["stu_id"],
                    clean_value(data["stu_major"]),
                    year,
                ),
            )
        session["student_email"] = data["stu_email"]
        flash("Profile saved.", "success")
    except (ValueError, psycopg2.Error) as exc:
        flash(str(exc).strip(), "error")

    return redirect(url_for("student_portal"))


@app.route("/student/join", methods=["POST"])
@student_required
def join_club():
    student = get_student_by_email(session["student_email"])
    club_id = clean_value(request.form.get("club_id", ""))
    if not student:
        flash("Save your profile before joining a club.", "warning")
        return redirect(url_for("student_portal"))
    if not club_id:
        flash("Choose a club first.", "warning")
        return redirect(url_for("student_portal"))

    try:
        with db_cursor(commit=True) as cursor:
            cursor.execute(
                "SELECT 1 FROM membership WHERE user_id = %s AND club_id = %s",
                (student["stu_id"], club_id),
            )
            if cursor.fetchone():
                flash("You have already joined this club.", "warning")
                return redirect(url_for("student_portal"))

            cursor.execute(
                "SELECT role_id FROM role WHERE lower(role_name) = 'member' LIMIT 1"
            )
            role = cursor.fetchone()
            if role:
                role_id = role["role_id"]
            else:
                cursor.execute(
                    "INSERT INTO role (role_name, role_description) "
                    "VALUES ('Member', 'Regular club member') RETURNING role_id"
                )
                role_id = cursor.fetchone()["role_id"]

            cursor.execute(
                "CALL sp_enroll_student(%s, %s, %s)",
                (student["stu_id"], club_id, role_id),
            )
        flash("Club joined.", "success")
    except psycopg2.Error as exc:
        flash(str(exc).strip(), "error")

    return redirect(url_for("student_portal"))


@app.route("/student/leave", methods=["POST"])
@student_required
def leave_club():
    memb_id = clean_value(request.form.get("memb_id", ""))
    student = get_student_by_email(session["student_email"])
    if not memb_id or not student:
        flash("Choose a membership first.", "warning")
        return redirect(url_for("student_portal"))

    try:
        with db_cursor(commit=True) as cursor:
            cursor.execute(
                "DELETE FROM membership WHERE memb_id = %s AND user_id = %s",
                (memb_id, student["stu_id"]),
            )
        flash("Membership removed.", "success")
    except psycopg2.Error as exc:
        flash(str(exc).strip(), "error")

    return redirect(url_for("student_portal"))


@app.route("/admin/add_member", methods=["POST"])
@club_admin_required
def admin_add_member():
    """Add a member to a club from admin portal"""
    email = session["student_email"]
    student = get_student_by_email(email)
    
    club_id = clean_value(request.form.get("club_id", ""))
    student_id = clean_value(request.form.get("student_id", ""))
    
    if not club_id or not student_id:
        flash("Please select both a club and a student.", "warning")
        return redirect(url_for("club_admin_portal", club_id=club_id))
    
    try:
        with db_cursor(commit=True) as cursor:
            # Check if user is admin of this club
            if not has_club_role(cursor, student["stu_id"], club_id, MANAGE_ALL_ROLES):
                flash("You don't have permission to manage this club.", "error")
                return redirect(url_for("club_admin_portal"))
            
            # Check if student already exists in club (duplicate prevention)
            cursor.execute(
                "SELECT 1 FROM membership WHERE club_id = %s AND user_id = %s",
                (club_id, student_id),
            )
            if cursor.fetchone():
                flash("This student is already a member of this club.", "warning")
                return redirect(url_for("club_admin_portal", club_id=club_id))
            
            # Get Member role
            cursor.execute(
                "SELECT role_id FROM role WHERE lower(role_name) = 'member' LIMIT 1"
            )
            role = cursor.fetchone()
            if role:
                role_id = role["role_id"]
            else:
                cursor.execute(
                    "INSERT INTO role (role_name, role_description) "
                    "VALUES ('Member', 'Regular club member') RETURNING role_id"
                )
                role_id = cursor.fetchone()["role_id"]
            
            # Add member
            cursor.execute(
                "CALL sp_enroll_student(%s, %s, %s)",
                (student_id, club_id, role_id),
            )
        flash("Member added successfully.", "success")
    except psycopg2.Error as exc:
        flash(str(exc).strip(), "error")
    
    return redirect(url_for("club_admin_portal", club_id=club_id))


@app.route("/admin/remove_member", methods=["POST"])
@club_admin_required
def admin_remove_member():
    """Remove a member from a club from admin portal"""
    email = session["student_email"]
    student = get_student_by_email(email)
    
    club_id = clean_value(request.form.get("club_id", ""))
    memb_id = clean_value(request.form.get("memb_id", ""))
    
    if not club_id or not memb_id:
        flash("Missing required information.", "warning")
        return redirect(url_for("club_admin_portal", club_id=club_id))
    
    try:
        with db_cursor(commit=True) as cursor:
            # Check if user is admin of this club
            if not has_club_role(cursor, student["stu_id"], club_id, MANAGE_ALL_ROLES):
                flash("You don't have permission to manage this club.", "error")
                return redirect(url_for("club_admin_portal"))
            
            # Verify membership belongs to this club
            cursor.execute(
                "SELECT 1 FROM membership WHERE memb_id = %s AND club_id = %s",
                (memb_id, club_id),
            )
            if not cursor.fetchone():
                flash("Membership not found.", "error")
                return redirect(url_for("club_admin_portal", club_id=club_id))
            
            # Delete membership
            cursor.execute(
                "DELETE FROM membership WHERE memb_id = %s",
                (memb_id,),
            )
        flash("Member removed successfully.", "success")
    except psycopg2.Error as exc:
        flash(str(exc).strip(), "error")
    
    return redirect(url_for("club_admin_portal", club_id=club_id))


if __name__ == "__main__":
    port = int(os.getenv("PORT", "5002"))
    debug = os.getenv("FLASK_DEBUG", "1") == "1"
    app.run(host="127.0.0.1", port=5002, debug=debug)
