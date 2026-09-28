import psycopg2
import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

_AUDIT_READY = False


def _ensure_audit_triggers(conn):
    global _AUDIT_READY
    if _AUDIT_READY:
        return

    audit_sql = Path(__file__).resolve().parent.parent / "sql" / "audit_all_actions.sql"

    with audit_sql.open("r", encoding="utf-8") as file:
        sql = file.read()

    try:
        with conn.cursor() as cursor:
            cursor.execute(sql)
        conn.commit()
    except psycopg2.Error:
        conn.rollback()

    _AUDIT_READY = True


def get_connection():
    conn = psycopg2.connect(
        host=os.getenv("CLUBSPHERE_DB_HOST", "localhost"),
        database=os.getenv("CLUBSPHERE_DB_NAME", "postgres"),
        user=os.getenv("CLUBSPHERE_DB_USER", "postgres"),
        password=os.getenv("CLUBSPHERE_DB_PASSWORD", "")
    )

    _ensure_audit_triggers(conn)
    return conn