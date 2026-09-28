# ClubSphere

Flask web app backed by PostgreSQL.

## Requirements

- Python
- PostgreSQL
- Python packages from `requirements.txt`

## Setup

Install Python dependencies:

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

Configure the PostgreSQL credentials for your local machine:

```powershell
$env:CLUBSPHERE_DB_HOST = "localhost"
$env:CLUBSPHERE_DB_NAME = "postgres"
$env:CLUBSPHERE_DB_USER = "postgres"
$env:CLUBSPHERE_DB_PASSWORD = "your_postgres_password"
```

Create the database tables and advanced database objects:

```powershell
$env:PGPASSWORD = $env:CLUBSPHERE_DB_PASSWORD
psql -h $env:CLUBSPHERE_DB_HOST -U $env:CLUBSPHERE_DB_USER -d $env:CLUBSPHERE_DB_NAME -f .\sql\create_tables.sql
psql -h $env:CLUBSPHERE_DB_HOST -U $env:CLUBSPHERE_DB_USER -d $env:CLUBSPHERE_DB_NAME -f .\sql\advanced.sql
psql -h $env:CLUBSPHERE_DB_HOST -U $env:CLUBSPHERE_DB_USER -d $env:CLUBSPHERE_DB_NAME -f .\sql\audit_all_actions.sql
```

Run the app:

```powershell
python .\main.py
```

Then open:

```text
http://127.0.0.1:5002
```

The helper scripts ask for your PostgreSQL password if `CLUBSPHERE_DB_PASSWORD` is not already set.

## Test logins

Admin dashboard:

```text
username: admin
password: nimda
```

Student accounts now require a password. New students can create an account from
the Student Access page. If you load `sql/seed_extra.sql`, the extra seeded
students `S011` through `S030` use:

```text
password: password123
```
