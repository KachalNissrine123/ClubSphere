-- ============================================================
--  ClubSphere — Sample Data
--  Run this in pgAdmin after create_tables.sql and advanced.sql
--  Populates all 10 tables with realistic AUI data
-- ============================================================

-- Clear existing data (safe re-run)
TRUNCATE TABLE budget_audit           RESTART IDENTITY CASCADE;
TRUNCATE TABLE advanced_audit_log    RESTART IDENTITY CASCADE;
TRUNCATE TABLE budget_alert          RESTART IDENTITY CASCADE;
TRUNCATE TABLE sponsorship           RESTART IDENTITY CASCADE;
TRUNCATE TABLE attendance            RESTART IDENTITY CASCADE;
TRUNCATE TABLE membership            RESTART IDENTITY CASCADE;
TRUNCATE TABLE budget                RESTART IDENTITY CASCADE;
TRUNCATE TABLE event                 RESTART IDENTITY CASCADE;
TRUNCATE TABLE venue                 RESTART IDENTITY CASCADE;
TRUNCATE TABLE sponsor               RESTART IDENTITY CASCADE;
TRUNCATE TABLE role                  RESTART IDENTITY CASCADE;
TRUNCATE TABLE club                  RESTART IDENTITY CASCADE;
TRUNCATE TABLE club_category         RESTART IDENTITY CASCADE;
TRUNCATE TABLE login                 RESTART IDENTITY CASCADE;
TRUNCATE TABLE student               RESTART IDENTITY CASCADE;
TRUNCATE TABLE app_user              RESTART IDENTITY CASCADE;


-- ============================================================
--  0. CLUB CATEGORY
-- ============================================================
INSERT INTO club_category (category_name) VALUES
('Technology'),
('Academic'),
('Business'),
('Sports'),
('Arts');


-- ============================================================
--  1. STUDENT USERS
-- ============================================================
INSERT INTO app_user (user_id, user_fname, user_lname, user_email, user_phone) VALUES
('S001', 'Mohamed Amine', 'El Malki',    'm.elmalki@aui.ma',      '0612345601'),
('S002', 'Reda',          'Benhaimoud',  'r.benhaimoud@aui.ma',   '0612345602'),
('S003', 'Ryad',          'Stitou',      'r.stitou@aui.ma',       '0612345603'),
('S004', 'Fatima',        'Zahra',       'f.zahra@aui.ma',        '0612345604'),
('S005', 'Youssef',       'Benali',      'y.benali@aui.ma',       '0612345605'),
('S006', 'Salma',         'Idrissi',     's.idrissi@aui.ma',      '0612345606'),
('S007', 'Omar',          'Tazi',        'o.tazi@aui.ma',         '0612345607'),
('S008', 'Nadia',         'Chraibi',     'n.chraibi@aui.ma',      '0612345608'),
('S009', 'Hamza',         'Ouali',       'h.ouali@aui.ma',        '0612345609'),
('S010', 'Layla',         'Moussaoui',   'l.moussaoui@aui.ma',    '0612345610');

INSERT INTO login (user_id, user_password) VALUES
('S001', 'pbkdf2:sha256:1000000$h93G7tiyqoZIFLDM$c0b9d16e274e6802dd835300f23746b8ea0257e086c24d94992c95cb1959c50d'),
('S002', 'pbkdf2:sha256:1000000$O4rlVSiiDcI3tfd7$a2dda157ca6febab290a15d864766de558d2897a0bd98e8f4c5ffcbf4a48fe67'),
('S003', 'pbkdf2:sha256:1000000$behRnh2MI3oTNOPT$1b192dd83d740f41e1155c34497a0afa795baa26174865ec22139fa8abdb558d'),
('S004', 'pbkdf2:sha256:1000000$KGKqx3nFiEPQwC72$53aaa7358db2970534a53572214db51c9e7e79379a3cec06c6c8dcc749c06782'),
('S005', 'pbkdf2:sha256:1000000$rjEZ1EPM7ZkhQnJ1$e16f9533e86deddb34b235e15c9e3dc917bf50c65b3319521aae3ea9c83a330f'),
('S006', 'pbkdf2:sha256:1000000$KiVL7IzQWOHCwrzh$c80948aee08a140453f1146f8d38b09f7cd19223b4238dd49c6843bb11320293'),
('S007', 'pbkdf2:sha256:1000000$BjgByJzRh1sTqaxH$64a44ee6a1b26bdb199c685559aa31f0344a7f4e61688cf5e30cce8926d4f8c0'),
('S008', 'pbkdf2:sha256:1000000$twcLkAFp5OTaUJY0$d1b18b0e55bb5dc7df64f637632f23819078cdb2c60c95c50a68123067b77011'),
('S009', 'pbkdf2:sha256:1000000$L9jZ6HbamGnFA8sO$517d691c6f65be2ba1198c522c9e480a5781b5218a8ce31f83479db6e8f43794'),
('S010', 'pbkdf2:sha256:1000000$WAbBGihyflilew5a$9418d8a8b6999b4f9654e661d1bc24ed0f8b1c2a08db691f7bcf42e3cf5ff0e7');

INSERT INTO student (user_id, stu_major, stu_year) VALUES
('S001', 'Computer Science',    4),
('S002', 'Computer Science',    4),
('S003', 'Computer Science',    4),
('S004', 'Business Admin',      3),
('S005', 'International Relations', 3),
('S006', 'Business Admin',      2),
('S007', 'Engineering',         2),
('S008', 'Computer Science',    3),
('S009', 'Engineering',         1),
('S010', 'International Relations', 1);


-- ============================================================
--  2. CLUB
-- ============================================================
INSERT INTO club (club_id, club_name, category_id, club_found_date, club_description) VALUES
('C001', 'AUI Coding Club',        1, '2018-09-01', 'A community for students passionate about programming and software development.'),
('C002', 'AUI Debate Society',     2, '2015-03-15', 'Fosters critical thinking and public speaking through competitive debate.'),
('C003', 'AUI Entrepreneurs Club', 3, '2019-01-20', 'Connects aspiring entrepreneurs and supports startup ideas on campus.'),
('C004', 'AUI Sports Club',        4, '2010-09-01', 'Organizes sporting events and promotes physical wellness among students.'),
('C005', 'AUI Arts & Culture Club',5, '2017-04-10', 'Celebrates Moroccan and international culture through art, music, and events.');


-- ============================================================
--  3. ROLE
-- ============================================================
INSERT INTO role (role_name, role_description) VALUES
('President',      'Leads the club, chairs meetings, and represents the club officially.'),
('Vice President', 'Assists the president and takes over in their absence.'),
('Treasurer',      'Manages the club budget and tracks financial transactions.'),
('Secretary',      'Handles meeting minutes, communications, and administrative tasks.'),
('Member',         'Regular club member with full participation rights.');


-- ============================================================
--  4. VENUE
-- ============================================================
INSERT INTO venue (venue_name, venue_capacity, venue_location) VALUES
('Main Auditorium',     500, 'Student Life Building — Ground Floor'),
('Conference Room A',    40, 'Academic Building 1 — Room 101'),
('Innovation Lab',       30, 'Engineering Building — Room 205'),
('Open Air Amphitheater',300, 'Campus Center — Outdoor'),
('Library Seminar Room', 25, 'Library — 2nd Floor');


-- ============================================================
--  5. SPONSOR
-- ============================================================
INSERT INTO sponsor (sponsor_name, sponsor_type, sponsor_email, sponsor_phone) VALUES
('OCP Group',           'Corporate',      'sponsorship@ocp.ma',        '0522123456'),
('Maroc Telecom',       'Corporate',      'events@iam.ma',             '0522234567'),
('AUI Alumni Network',  'Institutional',  'alumni@aui.ma',             '0535862000'),
('Hassan Benali Foundation', 'Individual','h.benali@foundation.ma',    '0661234567'),
('Attijariwafa Bank',   'Corporate',      'corporate@attijariwafa.ma', '0522578900');


-- ============================================================
--  6. EVENT
-- ============================================================
INSERT INTO event (club_id, venue_id, event_name, event_date, event_status, event_description) VALUES
('C001', 3, 'Hackathon Spring 2025',        '2025-03-15', 'Completed',  '24-hour coding competition open to all AUI students.'),
('C001', 2, 'Python Workshop',              '2025-04-10', 'Completed',  'Hands-on introduction to Python for beginners.'),
('C002', 1, 'Inter-University Debate 2025', '2025-04-22', 'Completed',  'Annual debate competition hosted by AUI against 5 universities.'),
('C003', 2, 'Startup Pitch Night',          '2025-05-05', 'Completed',  'Students pitch their startup ideas to a panel of judges.'),
('C004', 4, 'AUI Sports Day',               '2025-05-20', 'Completed',  'Full-day sporting event with football, basketball, and athletics.'),
('C005', 1, 'Cultural Night 2025',          '2025-06-01', 'Completed',  'Annual celebration of Moroccan and international student cultures.'),
('C001', 3, 'AI & Machine Learning Talk',   '2025-09-18', 'Planned',    'Guest speaker session on AI trends and career opportunities.'),
('C002', 5, 'Debate Training Workshop',     '2025-09-25', 'Planned',    'Internal workshop to prepare members for upcoming competitions.'),
('C003', 2, 'Entrepreneurship Bootcamp',    '2025-10-10', 'Planned',    'Two-day intensive bootcamp on building and launching startups.'),
('C005', 4, 'International Food Festival',  '2025-10-25', 'Planned',    'Students showcase dishes from their home countries.');


-- ============================================================
--  7. BUDGET
-- ============================================================
INSERT INTO budget (club_id, budget_year, budget_allocated, budget_spent) VALUES
('C001', 2025, 15000.00,  8500.00),
('C002', 2025, 10000.00,  4200.00),
('C003', 2025, 12000.00,  6750.00),
('C004', 2025, 20000.00, 14300.00),
('C005', 2025, 18000.00,  9100.00);


-- ============================================================
--  8. MEMBERSHIP
-- ============================================================
INSERT INTO membership (user_id, club_id, role_id, memb_join_date, memb_status) VALUES
-- Coding Club
('S001', 'C001', 1, '2023-09-05', 'Active'),   -- Mohamed Amine = President
('S002', 'C001', 2, '2023-09-05', 'Active'),   -- Reda = Vice President
('S003', 'C001', 5, '2023-09-10', 'Active'),   -- Ryad = Member
('S008', 'C001', 3, '2023-10-01', 'Active'),   -- Nadia = Treasurer
('S009', 'C001', 5, '2024-01-15', 'Active'),   -- Hamza = Member
-- Debate Society
('S004', 'C002', 1, '2022-09-01', 'Active'),   -- Fatima = President
('S005', 'C002', 5, '2022-09-15', 'Active'),   -- Youssef = Member
('S010', 'C002', 4, '2023-02-10', 'Active'),   -- Layla = Secretary
-- Entrepreneurs Club
('S006', 'C003', 1, '2023-01-20', 'Active'),   -- Salma = President
('S005', 'C003', 5, '2023-03-01', 'Active'),   -- Youssef = Member
('S007', 'C003', 3, '2023-03-01', 'Active'),   -- Omar = Treasurer
-- Sports Club
('S007', 'C004', 2, '2021-09-01', 'Active'),   -- Omar = Vice President
('S009', 'C004', 5, '2022-02-01', 'Active'),   -- Hamza = Member
('S003', 'C004', 5, '2022-09-01', 'Inactive'), -- Ryad = Inactive
-- Arts Club
('S004', 'C005', 5, '2023-09-01', 'Active'),   -- Fatima = Member
('S010', 'C005', 2, '2023-09-01', 'Active'),   -- Layla = Vice President
('S006', 'C005', 5, '2024-01-10', 'Active');   -- Salma = Member


-- ============================================================
--  9. ATTENDANCE
-- ============================================================
INSERT INTO attendance (user_id, event_id, att_status, att_timestamp) VALUES
-- Hackathon Spring 2025 (event 1)
('S001', 1, 'Present', '2025-03-15 09:00:00'),
('S002', 1, 'Present', '2025-03-15 09:05:00'),
('S003', 1, 'Present', '2025-03-15 09:10:00'),
('S008', 1, 'Present', '2025-03-15 09:15:00'),
('S009', 1, 'Absent',  '2025-03-15 09:00:00'),
-- Python Workshop (event 2)
('S001', 2, 'Present', '2025-04-10 10:00:00'),
('S003', 2, 'Present', '2025-04-10 10:05:00'),
('S007', 2, 'Present', '2025-04-10 10:10:00'),
('S009', 2, 'Excused', '2025-04-10 10:00:00'),
-- Inter-University Debate (event 3)
('S004', 3, 'Present', '2025-04-22 14:00:00'),
('S005', 3, 'Present', '2025-04-22 14:05:00'),
('S010', 3, 'Present', '2025-04-22 14:10:00'),
('S006', 3, 'Absent',  '2025-04-22 14:00:00'),
-- Startup Pitch Night (event 4)
('S006', 4, 'Present', '2025-05-05 18:00:00'),
('S005', 4, 'Present', '2025-05-05 18:05:00'),
('S007', 4, 'Present', '2025-05-05 18:10:00'),
-- AUI Sports Day (event 5)
('S007', 5, 'Present', '2025-05-20 08:00:00'),
('S009', 5, 'Present', '2025-05-20 08:05:00'),
('S003', 5, 'Present', '2025-05-20 08:10:00'),
('S001', 5, 'Absent',  '2025-05-20 08:00:00'),
-- Cultural Night (event 6)
('S004', 6, 'Present', '2025-06-01 19:00:00'),
('S010', 6, 'Present', '2025-06-01 19:05:00'),
('S006', 6, 'Present', '2025-06-01 19:10:00'),
('S002', 6, 'Excused', '2025-06-01 19:00:00');


-- ============================================================
--  10. SPONSORSHIP
-- ============================================================
INSERT INTO sponsorship (sponsor_id, club_id, spons_amount, spons_date, spons_type) VALUES
(1, 'C001', 5000.00,  '2025-01-10', 'Annual Sponsorship'),
(2, 'C001', 3000.00,  '2025-02-01', 'Event Sponsorship'),
(3, 'C002', 4000.00,  '2025-01-15', 'Annual Sponsorship'),
(4, 'C003', 6000.00,  '2025-01-20', 'Annual Sponsorship'),
(5, 'C003', 2500.00,  '2025-03-01', 'Event Sponsorship'),
(1, 'C004', 8000.00,  '2025-01-05', 'Annual Sponsorship'),
(2, 'C005', 4500.00,  '2025-01-08', 'Annual Sponsorship'),
(3, 'C005', 3000.00,  '2025-04-01', 'Event Sponsorship');


-- ============================================================
--  11. BUDGET TRANSACTIONS
-- ============================================================
INSERT INTO budget_transaction (
    club_id, budget_id, transaction_date, transaction_desc,
    transaction_amount, transaction_type, recorded_by
) VALUES
('C001', 1, '2025-01-12', 'Hackathon supplies and prizes',     2200.00, 'Expense',   'Admin Office'),
('C001', 1, '2025-02-01', 'Corporate support received',        3000.00, 'Income',    'Admin Office'),
('C002', 2, '2025-02-18', 'Debate travel reimbursement',       1500.00, 'Expense',   'Admin Office'),
('C003', 3, '2025-03-03', 'Pitch night catering',              1750.00, 'Expense',   'Admin Office'),
('C004', 4, '2025-03-28', 'Sports equipment purchase',         4100.00, 'Expense',   'Admin Office'),
('C005', 5, '2025-04-04', 'Cultural night sponsor transfer',   2500.00, 'Income',    'Admin Office'),
('C005', 5, '2025-04-09', 'Stage decoration adjustment',        600.00, 'Adjustment','Admin Office');


-- ============================================================
--  VERIFY — run these to confirm everything loaded correctly
-- ============================================================
SELECT 'Students'     AS table_name, COUNT(*) AS total FROM student
UNION ALL
SELECT 'Clubs',        COUNT(*) FROM club
UNION ALL
SELECT 'Roles',        COUNT(*) FROM role
UNION ALL
SELECT 'Venues',       COUNT(*) FROM venue
UNION ALL
SELECT 'Sponsors',     COUNT(*) FROM sponsor
UNION ALL
SELECT 'Events',       COUNT(*) FROM event
UNION ALL
SELECT 'Budgets',      COUNT(*) FROM budget
UNION ALL
SELECT 'Budget Transactions', COUNT(*) FROM budget_transaction
UNION ALL
SELECT 'Memberships',  COUNT(*) FROM membership
UNION ALL
SELECT 'Attendance',   COUNT(*) FROM attendance
UNION ALL
SELECT 'Sponsorships', COUNT(*) FROM sponsorship;
