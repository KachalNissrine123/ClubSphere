-- ============================================================
--  ClubSphere — AUI Extra Seed Data
--  Run this in pgAdmin AFTER seed_data.sql
--  Adds 10 AUI clubs, 20 students, budgets, memberships, events
-- ============================================================


-- ============================================================
--  NEW CLUB CATEGORIES
-- ============================================================
INSERT INTO club_category (category_name) VALUES
('Community Service'),
('Volunteer'),
('Leadership'),
('Environment');


-- ============================================================
--  NEW CLUBS
-- ============================================================
INSERT INTO club (club_id, club_name, category_id, club_found_date, club_description) VALUES
('C006', 'Rotaract AUI',
         6, '2016-10-01',
         'AUI chapter of Rotaract International — community service, leadership, and professional development for students.'),
('C007', 'Lions Club AUI',
         6, '2019-03-15',
         'Student humanitarian chapter focused on service projects and community development across the Ifrane-Azrou region.'),
('C008', 'Rhythm Unity',
         5, '2020-02-20',
         'Music and dance club celebrating diverse musical genres and performing arts at AUI — open to all skill levels.'),
('C009', 'Astronomy Club AUI',
         2, '2021-09-01',
         'Stargazing sessions, telescope nights, and space science education for AUI students and the Ifrane community.'),
('C010', 'Al Qalb Kbir',
         7, '2018-11-05',
         'Humanitarian club organising charity drives, food distributions, and volunteer outreach across the Ifrane region.'),
('C011', 'JLM — Jeunes Leaders Marocains',
         8, '2017-04-01',
         'Platform for developing the next generation of Moroccan leaders through workshops, mentoring, and national competitions.'),
('C012', 'AUI Photography Club',
         5, '2020-09-01',
         'Capturing AUI campus life and Moroccan landscapes — photography workshops, photo walks, and annual exhibitions.'),
('C013', 'Model United Nations AUI',
         2, '2014-09-01',
         'Simulates UN committees to foster diplomacy, research, and global awareness among AUI students.'),
('C014', 'Green Campus AUI',
         9, '2022-03-22',
         'Promoting environmental sustainability through eco-initiatives, clean-up campaigns, and awareness events on campus.'),
('C015', 'ACM Student Chapter AUI',
         1, '2019-10-15',
         'AUI chapter of the Association for Computing Machinery — competitive programming, tech talks, and industry networking.');


-- ============================================================
--  NEW STUDENTS (S011–S030)
-- ============================================================
INSERT INTO app_user (user_id, user_fname, user_lname, user_email, user_phone) VALUES
('S011', 'Karim',    'Benjelloun', 'k.benjelloun@aui.ma',  '0612345611'),
('S012', 'Meryem',   'Alaoui',     'm.alaoui@aui.ma',      '0612345612'),
('S013', 'Amine',    'Bakkali',    'a.bakkali@aui.ma',     '0612345613'),
('S014', 'Sara',     'Hakimi',     's.hakimi@aui.ma',      '0612345614'),
('S015', 'Mehdi',    'Zouheir',    'm.zouheir@aui.ma',     '0612345615'),
('S016', 'Kenza',    'Berrada',    'k.berrada@aui.ma',     '0612345616'),
('S017', 'Ismail',   'Mansouri',   'i.mansouri@aui.ma',    '0612345617'),
('S018', 'Rim',      'Cherkaoui',  'r.cherkaoui@aui.ma',   '0612345618'),
('S019', 'Tariq',    'Filali',     't.filali@aui.ma',      '0612345619'),
('S020', 'Zineb',    'Slaoui',     'z.slaoui@aui.ma',      '0612345620'),
('S021', 'Houssam',  'Belkacem',   'h.belkacem@aui.ma',    '0612345621'),
('S022', 'Asmae',    'Tahiri',     'a.tahiri@aui.ma',      '0612345622'),
('S023', 'Soufiane', 'Naciri',     's.naciri@aui.ma',      '0612345623'),
('S024', 'Ghita',    'Bennani',    'g.bennani@aui.ma',     '0612345624'),
('S025', 'Anas',     'Kettani',    'a.kettani@aui.ma',     '0612345625'),
('S026', 'Hajar',    'Amrani',     'h.amrani@aui.ma',      '0612345626'),
('S027', 'Yassine',  'Lamrani',    'y.lamrani@aui.ma',     '0612345627'),
('S028', 'Dounia',   'Sqalli',     'd.sqalli@aui.ma',      '0612345628'),
('S029', 'Othmane',  'Bensouda',   'o.bensouda@aui.ma',    '0612345629'),
('S030', 'Nour',     'El Fassi',   'n.elfassi@aui.ma',     '0612345630');

INSERT INTO login (user_id, user_password) VALUES
('S011', 'pbkdf2:sha256:1000000$a0E3qBGdbXMdkpRq$20f52bd7f2023fbf4e0892a1bfb56962d953cf027eb89ee2240385f5bdf126e5'),
('S012', 'pbkdf2:sha256:1000000$a0E3qBGdbXMdkpRq$20f52bd7f2023fbf4e0892a1bfb56962d953cf027eb89ee2240385f5bdf126e5'),
('S013', 'pbkdf2:sha256:1000000$a0E3qBGdbXMdkpRq$20f52bd7f2023fbf4e0892a1bfb56962d953cf027eb89ee2240385f5bdf126e5'),
('S014', 'pbkdf2:sha256:1000000$a0E3qBGdbXMdkpRq$20f52bd7f2023fbf4e0892a1bfb56962d953cf027eb89ee2240385f5bdf126e5'),
('S015', 'pbkdf2:sha256:1000000$a0E3qBGdbXMdkpRq$20f52bd7f2023fbf4e0892a1bfb56962d953cf027eb89ee2240385f5bdf126e5'),
('S016', 'pbkdf2:sha256:1000000$a0E3qBGdbXMdkpRq$20f52bd7f2023fbf4e0892a1bfb56962d953cf027eb89ee2240385f5bdf126e5'),
('S017', 'pbkdf2:sha256:1000000$a0E3qBGdbXMdkpRq$20f52bd7f2023fbf4e0892a1bfb56962d953cf027eb89ee2240385f5bdf126e5'),
('S018', 'pbkdf2:sha256:1000000$a0E3qBGdbXMdkpRq$20f52bd7f2023fbf4e0892a1bfb56962d953cf027eb89ee2240385f5bdf126e5'),
('S019', 'pbkdf2:sha256:1000000$a0E3qBGdbXMdkpRq$20f52bd7f2023fbf4e0892a1bfb56962d953cf027eb89ee2240385f5bdf126e5'),
('S020', 'pbkdf2:sha256:1000000$a0E3qBGdbXMdkpRq$20f52bd7f2023fbf4e0892a1bfb56962d953cf027eb89ee2240385f5bdf126e5'),
('S021', 'pbkdf2:sha256:1000000$a0E3qBGdbXMdkpRq$20f52bd7f2023fbf4e0892a1bfb56962d953cf027eb89ee2240385f5bdf126e5'),
('S022', 'pbkdf2:sha256:1000000$a0E3qBGdbXMdkpRq$20f52bd7f2023fbf4e0892a1bfb56962d953cf027eb89ee2240385f5bdf126e5'),
('S023', 'pbkdf2:sha256:1000000$a0E3qBGdbXMdkpRq$20f52bd7f2023fbf4e0892a1bfb56962d953cf027eb89ee2240385f5bdf126e5'),
('S024', 'pbkdf2:sha256:1000000$a0E3qBGdbXMdkpRq$20f52bd7f2023fbf4e0892a1bfb56962d953cf027eb89ee2240385f5bdf126e5'),
('S025', 'pbkdf2:sha256:1000000$a0E3qBGdbXMdkpRq$20f52bd7f2023fbf4e0892a1bfb56962d953cf027eb89ee2240385f5bdf126e5'),
('S026', 'pbkdf2:sha256:1000000$a0E3qBGdbXMdkpRq$20f52bd7f2023fbf4e0892a1bfb56962d953cf027eb89ee2240385f5bdf126e5'),
('S027', 'pbkdf2:sha256:1000000$a0E3qBGdbXMdkpRq$20f52bd7f2023fbf4e0892a1bfb56962d953cf027eb89ee2240385f5bdf126e5'),
('S028', 'pbkdf2:sha256:1000000$a0E3qBGdbXMdkpRq$20f52bd7f2023fbf4e0892a1bfb56962d953cf027eb89ee2240385f5bdf126e5'),
('S029', 'pbkdf2:sha256:1000000$a0E3qBGdbXMdkpRq$20f52bd7f2023fbf4e0892a1bfb56962d953cf027eb89ee2240385f5bdf126e5'),
('S030', 'pbkdf2:sha256:1000000$a0E3qBGdbXMdkpRq$20f52bd7f2023fbf4e0892a1bfb56962d953cf027eb89ee2240385f5bdf126e5');

INSERT INTO student (user_id, stu_major, stu_year) VALUES
('S011', 'Business Admin',          2),
('S012', 'International Relations',  3),
('S013', 'Computer Science',         1),
('S014', 'Engineering',              2),
('S015', 'Computer Science',         3),
('S016', 'Business Admin',           4),
('S017', 'Engineering',              2),
('S018', 'International Relations',  1),
('S019', 'Computer Science',         4),
('S020', 'Business Admin',           3),
('S021', 'Engineering',              1),
('S022', 'International Relations',  2),
('S023', 'Computer Science',         2),
('S024', 'Business Admin',           1),
('S025', 'Engineering',              3),
('S026', 'International Relations',  4),
('S027', 'Computer Science',         1),
('S028', 'Business Admin',           2),
('S029', 'Engineering',              3),
('S030', 'International Relations',  2);

-- ============================================================
--  BUDGETS FOR NEW CLUBS
--  (trg_set_budget_status trigger sets budget_status automatically)
-- ============================================================
INSERT INTO budget (club_id, budget_year, budget_allocated, budget_spent) VALUES
('C006', 2025, 14000.00,  5200.00),
('C007', 2025, 11000.00,  3800.00),
('C008', 2025,  9000.00,  4100.00),
('C009', 2025,  7500.00,  2200.00),
('C010', 2025, 16000.00,  7400.00),
('C011', 2025, 13000.00,  5900.00),
('C012', 2025,  6000.00,  1800.00),
('C013', 2025, 10500.00,  4600.00),
('C014', 2025,  8000.00,  2900.00),
('C015', 2025, 12000.00,  5100.00);


-- ============================================================
--  MEMBERSHIPS
--  Role IDs: 1=President  2=Vice President  3=Treasurer
--            4=Secretary  5=Member
-- ============================================================
INSERT INTO membership (user_id, club_id, role_id, memb_join_date, memb_status) VALUES

-- Rotaract AUI (C006)
('S016', 'C006', 1, '2023-09-05', 'Active'),
('S012', 'C006', 2, '2023-09-05', 'Active'),
('S022', 'C006', 3, '2023-09-10', 'Active'),
('S011', 'C006', 5, '2023-10-01', 'Active'),
('S018', 'C006', 5, '2024-01-10', 'Active'),
('S026', 'C006', 5, '2024-02-01', 'Active'),

-- Lions Club AUI (C007)
('S025', 'C007', 1, '2023-09-05', 'Active'),
('S020', 'C007', 2, '2023-09-05', 'Active'),
('S014', 'C007', 3, '2023-09-15', 'Active'),
('S021', 'C007', 5, '2023-10-05', 'Active'),
('S013', 'C007', 5, '2024-01-20', 'Active'),

-- Rhythm Unity (C008)
('S024', 'C008', 1, '2023-09-01', 'Active'),
('S028', 'C008', 2, '2023-09-01', 'Active'),
('S018', 'C008', 5, '2023-09-10', 'Active'),
('S012', 'C008', 5, '2023-10-01', 'Active'),
('S022', 'C008', 5, '2024-02-15', 'Active'),

-- Astronomy Club AUI (C009)
('S015', 'C009', 1, '2023-09-05', 'Active'),
('S023', 'C009', 2, '2023-09-05', 'Active'),
('S027', 'C009', 5, '2023-09-15', 'Active'),
('S013', 'C009', 5, '2023-10-01', 'Active'),

-- Al Qalb Kbir (C010)
('S030', 'C010', 1, '2022-11-01', 'Active'),
('S026', 'C010', 2, '2022-11-01', 'Active'),
('S016', 'C010', 4, '2022-11-10', 'Active'),
('S011', 'C010', 5, '2023-01-15', 'Active'),
('S020', 'C010', 5, '2023-02-01', 'Active'),
('S024', 'C010', 5, '2023-03-01', 'Active'),

-- JLM (C011)
('S019', 'C011', 1, '2023-09-01', 'Active'),
('S029', 'C011', 2, '2023-09-01', 'Active'),
('S017', 'C011', 3, '2023-09-10', 'Active'),
('S025', 'C011', 5, '2023-10-01', 'Active'),
('S015', 'C011', 5, '2023-10-15', 'Active'),

-- AUI Photography Club (C012)
('S028', 'C012', 1, '2023-09-01', 'Active'),
('S014', 'C012', 2, '2023-09-01', 'Active'),
('S030', 'C012', 5, '2023-09-15', 'Active'),
('S018', 'C012', 5, '2024-01-01', 'Active'),

-- Model United Nations AUI (C013)
('S012', 'C013', 1, '2022-09-01', 'Active'),
('S022', 'C013', 4, '2022-09-01', 'Active'),
('S026', 'C013', 5, '2022-09-15', 'Active'),
('S030', 'C013', 5, '2023-01-10', 'Active'),
('S011', 'C013', 5, '2023-02-01', 'Active'),

-- Green Campus AUI (C014)
('S020', 'C014', 1, '2023-03-22', 'Active'),
('S017', 'C014', 2, '2023-03-22', 'Active'),
('S021', 'C014', 5, '2023-04-01', 'Active'),
('S027', 'C014', 5, '2023-05-01', 'Active'),
('S029', 'C014', 5, '2024-01-01', 'Active'),

-- ACM Student Chapter AUI (C015)
('S015', 'C015', 1, '2023-09-05', 'Active'),
('S019', 'C015', 2, '2023-09-05', 'Active'),
('S023', 'C015', 3, '2023-09-10', 'Active'),
('S013', 'C015', 5, '2023-10-01', 'Active'),
('S027', 'C015', 5, '2024-01-15', 'Active');


-- ============================================================
--  EVENTS FOR NEW CLUBS
--  Venue IDs: 1=Main Auditorium  2=Conference Room A
--             3=Innovation Lab   4=Open Air Amphitheater
--             5=Library Seminar Room
-- ============================================================
INSERT INTO event (club_id, venue_id, event_name, event_date, event_status, event_description) VALUES
('C006', 1, 'Ifrane Community Clean-Up',    '2025-04-05', 'Completed', 'Rotaract volunteers cleaned Ifrane city centre in partnership with the local municipality.'),
('C006', 2, 'Leadership Summit AUI 2025',   '2025-05-12', 'Completed', 'One-day summit featuring alumni speakers on leadership, service, and career development.'),
('C006', 4, 'Charity Bazaar 2025',          '2025-11-15', 'Planned',   'Fundraising bazaar with student stalls, food, and live performances.'),
('C007', 4, 'Blood Drive Campaign',         '2025-03-20', 'Completed', 'Campus-wide blood donation drive in collaboration with the Moroccan Red Crescent.'),
('C007', 1, 'Lions Community Day',          '2025-10-18', 'Planned',   'Full-day service event combining a school supply drive and mentoring sessions in Ifrane.'),
('C008', 1, 'AUI Talent Show 2025',         '2025-04-18', 'Completed', 'Annual talent show featuring music, dance, and spoken word performances by AUI students.'),
('C008', 4, 'Open Mic Night',               '2025-09-26', 'Planned',   'Casual open mic evening for students to share original music, poetry, and comedy.'),
('C008', 1, 'End of Year Gala Night',       '2025-12-12', 'Planned',   'Celebratory gala with live music, dance performances, and annual club awards.'),
('C009', 4, 'Atlas Stargazing Night',       '2025-04-02', 'Completed', 'Telescope observation session in the Atlas mountains, open to the entire AUI community.'),
('C009', 2, 'Space Science Seminar',        '2025-10-15', 'Planned',   'Guest lecture series on astrophysics, space exploration, and aerospace career paths.'),
('C010', 1, 'Ramadan Charity Drive 2025',   '2025-03-01', 'Completed', 'Food basket and clothing distribution to families in Azrou and Ifrane during Ramadan.'),
('C010', 4, 'AUI Charity Run',              '2025-11-08', 'Planned',   'Fundraising 5K run around campus to support local orphanages and elderly care homes.'),
('C011', 1, 'JLM National Conference',      '2025-05-23', 'Completed', 'Annual leadership conference bringing together Moroccan student leaders from across the country.'),
('C011', 2, 'CV & Interview Workshop',      '2025-10-05', 'Planned',   'Professional development workshop on resume writing and mock interview techniques.'),
('C012', 4, 'Campus Photo Walk',            '2025-04-15', 'Completed', 'Guided photo walk around AUI campus and the Ifrane cedar forest with photography tips.'),
('C012', 5, 'Photography Exhibition',       '2025-11-20', 'Planned',   'Annual exhibition showcasing the best student photography from the academic year.'),
('C013', 1, 'AUI MUN 2025 Conference',      '2025-04-28', 'Completed', 'Two-day Model UN conference simulating UNSC, ECOSOC, and UNHCR committees.'),
('C013', 2, 'Delegate Training Workshop',   '2025-09-28', 'Planned',   'Internal training on position papers, resolution writing, and debate procedure.'),
('C014', 4, 'Earth Day Campus Clean-Up',    '2025-04-22', 'Completed', 'Campus-wide waste collection and tree-planting event in partnership with AUI facilities.'),
('C014', 4, 'Zero Waste Awareness Week',    '2025-11-03', 'Planned',   'Week-long awareness campaign on plastic reduction, composting, and sustainable living.'),
('C015', 3, 'ICPC Training Bootcamp',       '2025-09-20', 'Planned',   'Intensive competitive programming bootcamp preparing teams for ICPC regional qualifiers.'),
('C015', 2, 'Tech Career Fair AUI',         '2025-10-30', 'Planned',   'Connecting AUI CS and Engineering students with top tech recruiters and startups.');


-- ============================================================
--  VERIFY
-- ============================================================
SELECT 'Students'    AS entity, COUNT(*) AS total FROM student
UNION ALL
SELECT 'Clubs',       COUNT(*) FROM club
UNION ALL
SELECT 'Events',      COUNT(*) FROM event
UNION ALL
SELECT 'Memberships', COUNT(*) FROM membership
UNION ALL
SELECT 'Budgets',     COUNT(*) FROM budget;
