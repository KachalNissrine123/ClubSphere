DROP TRIGGER IF EXISTS trg_membership_delete_audit ON membership;
DROP TRIGGER IF EXISTS trg_sponsorship_after_insert_budget ON sponsorship;
DROP TRIGGER IF EXISTS trg_student_statement_update_guard ON student;

DROP TRIGGER IF EXISTS trg_audit_student_changes ON student;
DROP TRIGGER IF EXISTS trg_audit_club_changes ON club;
DROP TRIGGER IF EXISTS trg_audit_role_changes ON role;
DROP TRIGGER IF EXISTS trg_audit_venue_changes ON venue;
DROP TRIGGER IF EXISTS trg_audit_sponsor_changes ON sponsor;
DROP TRIGGER IF EXISTS trg_audit_event_changes ON event;
DROP TRIGGER IF EXISTS trg_audit_budget_changes ON budget;
DROP TRIGGER IF EXISTS trg_audit_membership_changes ON membership;
DROP TRIGGER IF EXISTS trg_audit_attendance_changes ON attendance;
DROP TRIGGER IF EXISTS trg_audit_sponsorship_changes ON sponsorship;

DROP FUNCTION IF EXISTS fn_trg_audit_all_table_changes() CASCADE;

DROP TABLE IF EXISTS advanced_audit_log CASCADE;
CREATE TABLE advanced_audit_log (
    audit_id        SERIAL PRIMARY KEY,
    table_name      VARCHAR(50) NOT NULL,
    trigger_name    VARCHAR(80) NOT NULL,
    operation_type  VARCHAR(20) NOT NULL,
    trigger_timing  VARCHAR(20) NOT NULL,
    trigger_level   VARCHAR(20) NOT NULL,
    record_pk       VARCHAR(100),
    changed_by      VARCHAR(100) DEFAULT CURRENT_USER,
    changed_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    old_data        JSONB,
    new_data        JSONB,
    note            TEXT
);

CREATE OR REPLACE FUNCTION fn_trg_audit_all_table_changes()
RETURNS TRIGGER AS $$
DECLARE
    v_pk_column TEXT := TG_ARGV[0];
    v_old_row JSONB;
    v_new_row JSONB;
    v_record_pk TEXT;
BEGIN
    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        v_old_row := to_jsonb(OLD);
    END IF;

    IF TG_OP IN ('INSERT', 'UPDATE') THEN
        v_new_row := to_jsonb(NEW);
    END IF;

    v_record_pk := COALESCE(v_new_row ->> v_pk_column, v_old_row ->> v_pk_column);

    INSERT INTO advanced_audit_log (
        table_name,
        trigger_name,
        operation_type,
        trigger_timing,
        trigger_level,
        record_pk,
        old_data,
        new_data,
        note
    )
    VALUES (
        TG_TABLE_NAME,
        TG_NAME,
        TG_OP,
        TG_WHEN,
        TG_LEVEL,
        v_record_pk,
        v_old_row,
        v_new_row,
        CASE TG_OP
            WHEN 'INSERT' THEN 'Inserted row'
            WHEN 'UPDATE' THEN 'Updated row'
            WHEN 'DELETE' THEN 'Deleted row'
        END
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit_student_changes
    AFTER INSERT OR UPDATE OR DELETE ON student
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_audit_all_table_changes('user_id');

CREATE TRIGGER trg_audit_club_changes
    AFTER INSERT OR UPDATE OR DELETE ON club
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_audit_all_table_changes('club_id');

CREATE TRIGGER trg_audit_role_changes
    AFTER INSERT OR UPDATE OR DELETE ON role
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_audit_all_table_changes('role_id');

CREATE TRIGGER trg_audit_venue_changes
    AFTER INSERT OR UPDATE OR DELETE ON venue
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_audit_all_table_changes('venue_id');

CREATE TRIGGER trg_audit_sponsor_changes
    AFTER INSERT OR UPDATE OR DELETE ON sponsor
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_audit_all_table_changes('sponsor_id');

CREATE TRIGGER trg_audit_event_changes
    AFTER INSERT OR UPDATE OR DELETE ON event
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_audit_all_table_changes('event_id');

CREATE TRIGGER trg_audit_budget_changes
    AFTER INSERT OR UPDATE OR DELETE ON budget
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_audit_all_table_changes('budget_id');

CREATE TRIGGER trg_audit_membership_changes
    AFTER INSERT OR UPDATE OR DELETE ON membership
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_audit_all_table_changes('memb_id');

CREATE TRIGGER trg_audit_attendance_changes
    AFTER INSERT OR UPDATE OR DELETE ON attendance
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_audit_all_table_changes('att_id');

CREATE TRIGGER trg_audit_sponsorship_changes
    AFTER INSERT OR UPDATE OR DELETE ON sponsorship
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_audit_all_table_changes('sponsor_record_id');

