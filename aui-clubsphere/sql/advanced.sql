-- ============================================================
--  ClubSphere — Advanced SQL
--  Views | Functions | Procedures | Triggers
-- ============================================================


-- ============================================================
--  AUDIT TABLE (needed by the budget trigger)
-- ============================================================
DROP TABLE IF EXISTS budget_audit;
CREATE TABLE budget_audit (
    audit_id        SERIAL PRIMARY KEY,
    club_id         VARCHAR(20),
    budget_year     INT,
    old_spent       NUMERIC(10,2),
    new_spent       NUMERIC(10,2),
    changed_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================
--  VIEWS
-- ============================================================

-- 1. Membership Details
--    Joins MEMBERSHIP + STUDENT + CLUB + ROLE
DROP VIEW IF EXISTS v_membership_details;
CREATE VIEW v_membership_details AS
SELECT
    m.memb_id,
    u.user_id AS stu_id,
    u.user_fname || ' ' || u.user_lname   AS student_name,
    u.user_email,
    c.club_id,
    c.club_name,
    r.role_name,
    m.memb_join_date,
    m.memb_status
FROM membership m
JOIN student    s ON m.user_id   = s.user_id
JOIN app_user   u ON u.user_id   = s.user_id
JOIN club       c ON m.club_id  = c.club_id
JOIN role       r ON m.role_id  = r.role_id;


-- 2. Event Details
--    Joins EVENT + CLUB + VENUE
DROP VIEW IF EXISTS v_event_details;
CREATE VIEW v_event_details AS
SELECT
    e.event_id,
    e.event_name,
    c.club_name,
    v.venue_name,
    v.venue_location,
    e.event_date,
    e.event_status,
    e.event_description
FROM event  e
JOIN club   c ON e.club_id  = c.club_id
JOIN venue  v ON e.venue_id = v.venue_id;


-- 3. Attendance Report
--    Joins ATTENDANCE + STUDENT + EVENT
DROP VIEW IF EXISTS v_attendance_report;
CREATE VIEW v_attendance_report AS
SELECT
    a.att_id,
    u.user_id AS stu_id,
    u.user_fname || ' ' || u.user_lname   AS student_name,
    e.event_name,
    e.event_date,
    a.att_status,
    a.att_timestamp
FROM attendance a
JOIN student    s ON a.user_id   = s.user_id
JOIN app_user   u ON u.user_id   = s.user_id
JOIN event      e ON a.event_id  = e.event_id;


-- 4. Sponsorship Report
--    Joins SPONSORSHIP + SPONSOR + CLUB
DROP VIEW IF EXISTS v_sponsorship_report;
CREATE VIEW v_sponsorship_report AS
SELECT
    sp.sponsor_record_id,
    s.sponsor_name,
    s.sponsor_type,
    c.club_name,
    sp.spons_amount,
    sp.spons_date,
    sp.spons_type
FROM sponsorship sp
JOIN sponsor     s ON sp.sponsor_id = s.sponsor_id
JOIN club        c ON sp.club_id    = c.club_id;


-- ============================================================
--  STORED FUNCTIONS
-- ============================================================

-- 1. fn_get_budget_remaining(p_club_id)
--    Returns allocated - spent for the latest budget year of a club
DROP FUNCTION IF EXISTS fn_get_budget_remaining(VARCHAR);
CREATE OR REPLACE FUNCTION fn_get_budget_remaining(p_club_id VARCHAR)
RETURNS NUMERIC AS $$
DECLARE
    v_allocated NUMERIC(10,2);
    v_spent     NUMERIC(10,2);
    v_remaining NUMERIC(10,2);
BEGIN
    SELECT budget_allocated, budget_spent
    INTO   v_allocated, v_spent
    FROM   budget
    WHERE  club_id = p_club_id
    ORDER  BY budget_year DESC
    LIMIT  1;

    IF NOT FOUND THEN
        RETURN 0;
    END IF;

    v_remaining := v_allocated - v_spent;
    RETURN v_remaining;
END;
$$ LANGUAGE plpgsql;


-- 2. fn_count_club_members(p_club_id)
--    Returns the number of ACTIVE members in a club
DROP FUNCTION IF EXISTS fn_count_club_members(VARCHAR);
CREATE OR REPLACE FUNCTION fn_count_club_members(p_club_id VARCHAR)
RETURNS INT AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*)
    INTO   v_count
    FROM   membership
    WHERE  club_id    = p_club_id
    AND    memb_status = 'Active';

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;


-- 3. fn_count_event_attendance(p_event_id)
--    Returns the number of students who attended (status = Present) an event
DROP FUNCTION IF EXISTS fn_count_event_attendance(INT);
CREATE OR REPLACE FUNCTION fn_count_event_attendance(p_event_id INT)
RETURNS INT AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*)
    INTO   v_count
    FROM   attendance
    WHERE  event_id   = p_event_id
    AND    att_status  = 'Present';

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;


-- ============================================================
--  STORED PROCEDURES
-- ============================================================

-- 1. sp_enroll_student(p_stu_id, p_club_id, p_role_id)
--    Inserts a new membership with today's date and Active status
--    Raises an error if the student is already an active member
DROP PROCEDURE IF EXISTS sp_enroll_student(VARCHAR, VARCHAR, INT);
CREATE OR REPLACE PROCEDURE sp_enroll_student(
    p_stu_id  VARCHAR,
    p_club_id VARCHAR,
    p_role_id INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_existing INT;
BEGIN
    -- Check if membership already exists
    SELECT COUNT(*)
    INTO   v_existing
    FROM   membership
    WHERE  user_id  = p_stu_id
    AND    club_id = p_club_id
    AND    memb_status = 'Active';

    IF v_existing > 0 THEN
        RAISE EXCEPTION 'Student % is already an active member of club %.', p_stu_id, p_club_id;
    END IF;

    -- Insert the new membership
    INSERT INTO membership (user_id, club_id, role_id, memb_join_date, memb_status)
    VALUES (p_stu_id, p_club_id, p_role_id, CURRENT_DATE, 'Active');

    RAISE NOTICE 'Student % successfully enrolled in club %.', p_stu_id, p_club_id;
END;
$$;


-- 2. sp_record_attendance(p_stu_id, p_event_id, p_status)
--    Inserts an attendance record with the current timestamp
--    Raises an error if attendance already recorded for same student+event
DROP PROCEDURE IF EXISTS sp_record_attendance(VARCHAR, INT, VARCHAR);
CREATE OR REPLACE PROCEDURE sp_record_attendance(
    p_stu_id   VARCHAR,
    p_event_id INT,
    p_status   VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_existing INT;
BEGIN
    -- Check for duplicate attendance
    SELECT COUNT(*)
    INTO   v_existing
    FROM   attendance
    WHERE  user_id    = p_stu_id
    AND    event_id  = p_event_id;

    IF v_existing > 0 THEN
        RAISE EXCEPTION 'Attendance for student % at event % is already recorded.', p_stu_id, p_event_id;
    END IF;

    INSERT INTO attendance (user_id, event_id, att_status, att_timestamp)
    VALUES (p_stu_id, p_event_id, p_status, CURRENT_TIMESTAMP);

    RAISE NOTICE 'Attendance recorded for student % at event %.', p_stu_id, p_event_id;
END;
$$;


-- 3. sp_update_budget_spent(p_club_id, p_amount)
--    Adds p_amount to BUDGET_SPENT for the latest budget year of a club
--    Raises a warning if the new spent would exceed allocated
DROP PROCEDURE IF EXISTS sp_update_budget_spent(VARCHAR, NUMERIC);
CREATE OR REPLACE PROCEDURE sp_update_budget_spent(
    p_club_id VARCHAR,
    p_amount  NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_budget_id  INT;
    v_allocated  NUMERIC(10,2);
    v_spent      NUMERIC(10,2);
BEGIN
    SELECT budget_id, budget_allocated, budget_spent
    INTO   v_budget_id, v_allocated, v_spent
    FROM   budget
    WHERE  club_id = p_club_id
    ORDER  BY budget_year DESC
    LIMIT  1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No budget record found for club %.', p_club_id;
    END IF;

    IF (v_spent + p_amount) > v_allocated THEN
        RAISE EXCEPTION 'Cannot spend %.2f — only %.2f remaining in budget for club %.',
            p_amount, (v_allocated - v_spent), p_club_id;
    END IF;

    UPDATE budget
    SET    budget_spent = budget_spent + p_amount
    WHERE  budget_id = v_budget_id;

    RAISE NOTICE 'Budget updated for club %. New spent: %.', p_club_id, (v_spent + p_amount);
END;
$$;


-- ============================================================
--  TRIGGERS
-- ============================================================

-- ── TRIGGER 1 ──────────────────────────────────────────────
-- trg_prevent_duplicate_membership
-- BEFORE INSERT on MEMBERSHIP
-- Prevents a student from being enrolled in the same club twice
-- Concept: BEFORE trigger, validation check, row-level, NEW values

DROP FUNCTION IF EXISTS fn_trg_prevent_duplicate_membership() CASCADE;
CREATE OR REPLACE FUNCTION fn_trg_prevent_duplicate_membership()
RETURNS TRIGGER AS $$
DECLARE
    v_existing INT;
BEGIN
    SELECT COUNT(*)
    INTO   v_existing
    FROM   membership
    WHERE  user_id      = NEW.user_id
    AND    club_id     = NEW.club_id
    AND    memb_status = 'Active';

    IF v_existing > 0 THEN
        RAISE EXCEPTION
            'Duplicate membership: student % is already an active member of club %.',
            NEW.user_id, NEW.club_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_duplicate_membership ON membership;
CREATE TRIGGER trg_prevent_duplicate_membership
    BEFORE INSERT ON membership
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_prevent_duplicate_membership();


-- ── TRIGGER 2 ──────────────────────────────────────────────
-- trg_auto_timestamp_attendance
-- BEFORE INSERT on ATTENDANCE
-- Automatically sets ATT_TIMESTAMP to NOW() if the value is NULL
-- Concept: BEFORE trigger, modifying NEW value before save, row-level

DROP FUNCTION IF EXISTS fn_trg_auto_timestamp_attendance() CASCADE;
CREATE OR REPLACE FUNCTION fn_trg_auto_timestamp_attendance()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.att_timestamp IS NULL THEN
        NEW.att_timestamp := CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_auto_timestamp_attendance ON attendance;
CREATE TRIGGER trg_auto_timestamp_attendance
    BEFORE INSERT ON attendance
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_auto_timestamp_attendance();


-- ── TRIGGER 3 ──────────────────────────────────────────────
-- trg_log_budget_changes
-- AFTER UPDATE on BUDGET
-- Logs every change to BUDGET_SPENT into the budget_audit table
-- Concept: AFTER trigger, OLD and NEW values, writing to a DIFFERENT table, row-level

DROP FUNCTION IF EXISTS fn_trg_log_budget_changes() CASCADE;
CREATE OR REPLACE FUNCTION fn_trg_log_budget_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- Only log if BUDGET_SPENT actually changed
    IF OLD.budget_spent IS DISTINCT FROM NEW.budget_spent THEN
        INSERT INTO budget_audit (club_id, budget_year, old_spent, new_spent, changed_at)
        VALUES (NEW.club_id, NEW.budget_year, OLD.budget_spent, NEW.budget_spent, CURRENT_TIMESTAMP);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_log_budget_changes ON budget;
CREATE TRIGGER trg_log_budget_changes
    AFTER UPDATE ON budget
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_log_budget_changes();


-- Extra support tables for trigger demonstrations.
CREATE TABLE IF NOT EXISTS advanced_audit_log (
    audit_id        SERIAL PRIMARY KEY,
    table_name      VARCHAR(50) NOT NULL,
    trigger_name    VARCHAR(80) NOT NULL,
    event_type      VARCHAR(20) NOT NULL,
    trigger_timing  VARCHAR(20) NOT NULL,
    trigger_level   VARCHAR(20) NOT NULL,
    old_key         VARCHAR(100),
    new_key         VARCHAR(100),
    changed_by      VARCHAR(100) DEFAULT CURRENT_USER,
    changed_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details         TEXT
);

CREATE TABLE IF NOT EXISTS budget_alert (
    alert_id        SERIAL PRIMARY KEY,
    club_id         VARCHAR(20),
    budget_year     INT,
    alert_message   TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved        BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS monthly_close_control (
    control_id      INT PRIMARY KEY DEFAULT 1,
    block_updates   BOOLEAN NOT NULL DEFAULT FALSE,
    note            TEXT,
    CONSTRAINT one_monthly_close_row CHECK (control_id = 1)
);

INSERT INTO monthly_close_control (control_id, block_updates, note)
VALUES (1, FALSE, 'Set block_updates to TRUE to demonstrate the statement-level update trigger.')
ON CONFLICT (control_id) DO NOTHING;

ALTER TABLE budget
    ADD COLUMN IF NOT EXISTS budget_status VARCHAR(20) DEFAULT 'OK';


-- Aggregate/computed-column view.
DROP VIEW IF EXISTS v_club_activity_summary;
CREATE VIEW v_club_activity_summary AS
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
GROUP BY c.club_id, c.club_name;


-- Security view: row/column restriction plus SELECT grant on the view.
DROP VIEW IF EXISTS v_active_student_directory;
CREATE VIEW v_active_student_directory AS
SELECT DISTINCT
    u.user_id AS stu_id,
    u.user_fname || ' ' || u.user_lname AS student_name,
    u.user_email,
    s.stu_major
FROM student s
JOIN app_user u ON u.user_id = s.user_id
JOIN membership m ON m.user_id = s.user_id
WHERE m.memb_status = 'Active';

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'clubsphere_readonly') THEN
        BEGIN
            CREATE ROLE clubsphere_readonly;
        EXCEPTION
            WHEN insufficient_privilege THEN
                RAISE NOTICE 'Skipping clubsphere_readonly role creation because current user lacks CREATEROLE.';
        END;
    END IF;
END;
$$;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'clubsphere_readonly') THEN
        GRANT SELECT ON v_active_student_directory TO clubsphere_readonly;
    ELSE
        RAISE NOTICE 'Skipping GRANT on v_active_student_directory because clubsphere_readonly does not exist.';
    END IF;
END;
$$;


-- Aggregate function similar to the invoice-total practice problem.
DROP FUNCTION IF EXISTS fn_total_sponsorship_amount(VARCHAR);
CREATE OR REPLACE FUNCTION fn_total_sponsorship_amount(p_club_id VARCHAR)
RETURNS NUMERIC AS $$
DECLARE
    v_total sponsorship.spons_amount%TYPE;
BEGIN
    SELECT COALESCE(SUM(spons_amount), 0)
    INTO   v_total
    FROM   sponsorship
    WHERE  club_id = p_club_id;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;


-- Function demonstrating %TYPE, SELECT INTO, IF, FOR loop, := assignment, RETURN.
DROP FUNCTION IF EXISTS fn_get_club_activity_summary(VARCHAR);
CREATE OR REPLACE FUNCTION fn_get_club_activity_summary(p_club_id VARCHAR)
RETURNS TEXT AS $$
DECLARE
    v_club_name club.club_name%TYPE;
    v_event_count INT := 0;
    v_summary TEXT := '';
    v_event RECORD;
BEGIN
    SELECT club_name
    INTO   v_club_name
    FROM   club
    WHERE  club_id = p_club_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Club % does not exist.', p_club_id;
    END IF;

    FOR v_event IN
        SELECT event_name, event_status
        FROM event
        WHERE club_id = p_club_id
        ORDER BY event_date
    LOOP
        v_event_count := v_event_count + 1;
        v_summary := v_summary || v_event.event_name || ' [' || v_event.event_status || ']; ';
    END LOOP;

    IF v_event_count = 0 THEN
        RETURN v_club_name || ' has no events yet.';
    END IF;

    RETURN v_club_name || ' has ' || v_event_count || ' event(s): ' || v_summary;
END;
$$ LANGUAGE plpgsql;


-- Procedure that updates a related table after a sponsorship transaction.
DROP PROCEDURE IF EXISTS sp_apply_sponsorship_to_budget(INT);
CREATE OR REPLACE PROCEDURE sp_apply_sponsorship_to_budget(
    p_sponsor_record_id INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_club_id sponsorship.club_id%TYPE;
    v_amount sponsorship.spons_amount%TYPE;
    v_spons_date sponsorship.spons_date%TYPE;
    v_budget_year budget.budget_year%TYPE;
    v_budget_id budget.budget_id%TYPE;
    v_note TEXT;
BEGIN
    SELECT club_id, spons_amount, spons_date
    INTO   v_club_id, v_amount, v_spons_date
    FROM   sponsorship
    WHERE  sponsor_record_id = p_sponsor_record_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sponsorship record % does not exist.', p_sponsor_record_id;
    END IF;

    v_budget_year := EXTRACT(YEAR FROM v_spons_date);

    SELECT note
    INTO   v_note
    FROM   advanced_audit_log
    WHERE  table_name = 'sponsorship'
      AND  operation_type = 'UPDATE'
      AND  record_pk = p_sponsor_record_id::TEXT
      AND  note = 'Sponsorship applied to budget'
    ORDER BY audit_id DESC
    LIMIT 1;

    IF v_note IS NOT NULL THEN
        RAISE EXCEPTION 'Sponsorship record % has already been applied to a budget.', p_sponsor_record_id;
    END IF;

    SELECT budget_id
    INTO   v_budget_id
    FROM   budget
    WHERE  club_id = v_club_id
      AND  budget_year = v_budget_year
    LIMIT  1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No budget exists for club % in year %.', v_club_id, v_budget_year;
    END IF;

    UPDATE budget
    SET    budget_allocated = budget_allocated + v_amount
    WHERE  budget_id = v_budget_id;

    INSERT INTO advanced_audit_log (
        table_name,
        trigger_name,
        operation_type,
        trigger_timing,
        trigger_level,
        record_pk,
        note
    )
    VALUES (
        'sponsorship',
        'sp_apply_sponsorship_to_budget',
        'UPDATE',
        'MANUAL',
        'PROCEDURE',
        p_sponsor_record_id::TEXT,
        'Sponsorship applied to budget'
    );

    RAISE NOTICE 'Applied sponsorship % to club % budget for year %.', p_sponsor_record_id, v_club_id, v_budget_year;
END;
$$;


-- BEFORE INSERT/UPDATE row trigger: validates and modifies NEW in the same table.
DROP FUNCTION IF EXISTS fn_trg_set_budget_status() CASCADE;
CREATE OR REPLACE FUNCTION fn_trg_set_budget_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.budget_allocated IS NULL OR NEW.budget_allocated < 0 THEN
        RAISE EXCEPTION 'Budget allocated must be zero or greater.';
    END IF;

    IF NEW.budget_spent IS NULL OR NEW.budget_spent < 0 THEN
        RAISE EXCEPTION 'Budget spent must be zero or greater.';
    END IF;

    IF NEW.budget_spent > NEW.budget_allocated THEN
        NEW.budget_status := 'OVER';
    ELSIF NEW.budget_spent >= (NEW.budget_allocated * 0.80) THEN
        NEW.budget_status := 'WATCH';
    ELSE
        NEW.budget_status := 'OK';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_budget_status ON budget;
CREATE TRIGGER trg_set_budget_status
    BEFORE INSERT OR UPDATE ON budget
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_set_budget_status();


-- AFTER UPDATE row trigger: writes to a different table.
DROP FUNCTION IF EXISTS fn_trg_budget_alert_after_update() CASCADE;
CREATE OR REPLACE FUNCTION fn_trg_budget_alert_after_update()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.budget_status IN ('WATCH', 'OVER')
       AND OLD.budget_status IS DISTINCT FROM NEW.budget_status THEN
        INSERT INTO budget_alert (club_id, budget_year, alert_message)
        VALUES (
            NEW.club_id,
            NEW.budget_year,
            'Budget status changed from ' || COALESCE(OLD.budget_status, 'NULL') ||
            ' to ' || NEW.budget_status || '.'
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_budget_alert_after_update ON budget;
CREATE TRIGGER trg_budget_alert_after_update
    AFTER UPDATE ON budget
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_budget_alert_after_update();


-- AFTER DELETE row trigger: demonstrates DELETE and OLD values.
DROP FUNCTION IF EXISTS fn_trg_membership_delete_audit() CASCADE;
CREATE OR REPLACE FUNCTION fn_trg_membership_delete_audit()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO advanced_audit_log (
        table_name, trigger_name, event_type, trigger_timing, trigger_level,
        old_key, details
    )
    VALUES (
        'membership',
        'trg_membership_delete_audit',
        'DELETE',
        'AFTER',
        'ROW',
        OLD.memb_id::TEXT,
        'Deleted membership for student ' || OLD.user_id || ' in club ' || OLD.club_id
    );

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_membership_delete_audit ON membership;
CREATE TRIGGER trg_membership_delete_audit
    AFTER DELETE ON membership
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_membership_delete_audit();


-- BEFORE UPDATE statement trigger: fires once per statement and can block updates.
DROP FUNCTION IF EXISTS fn_trg_student_statement_update_guard() CASCADE;
CREATE OR REPLACE FUNCTION fn_trg_student_statement_update_guard()
RETURNS TRIGGER AS $$
DECLARE
    v_block_updates BOOLEAN;
BEGIN
    SELECT block_updates
    INTO   v_block_updates
    FROM   monthly_close_control
    WHERE  control_id = 1;

    IF COALESCE(v_block_updates, FALSE) THEN
        RAISE EXCEPTION 'Student updates are blocked during the monthly close window.';
    END IF;

    INSERT INTO advanced_audit_log (
        table_name, trigger_name, event_type, trigger_timing, trigger_level, details
    )
    VALUES (
        'student',
        'trg_student_statement_update_guard',
        'UPDATE',
        'BEFORE',
        'STATEMENT',
        'Statement-level trigger fired once for the UPDATE statement.'
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_student_statement_update_guard ON student;
CREATE TRIGGER trg_student_statement_update_guard
    BEFORE UPDATE ON student
    FOR EACH STATEMENT
    EXECUTE FUNCTION fn_trg_student_statement_update_guard();


DROP FUNCTION IF EXISTS fn_trg_sponsorship_after_insert_budget() CASCADE;
CREATE OR REPLACE FUNCTION fn_trg_sponsorship_after_insert_budget()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO advanced_audit_log (
        table_name, trigger_name, event_type, trigger_timing, trigger_level,
        new_key, details
    )
    VALUES (
        'sponsorship',
        'trg_sponsorship_after_insert_budget',
        'INSERT',
        'AFTER',
        'ROW',
        NEW.sponsor_record_id::TEXT,
        'New sponsorship of ' || NEW.spons_amount || ' recorded for club ' || NEW.club_id ||
        '. Run Apply Sponsorship to credit the budget.'
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sponsorship_after_insert_budget ON sponsorship;
CREATE TRIGGER trg_sponsorship_after_insert_budget
    AFTER INSERT ON sponsorship
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_sponsorship_after_insert_budget();

