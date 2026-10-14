# MediCare – Hospital Management Dashboard

Java (JDBC, built-in `HttpServer`) backend + HTML/CSS/JavaScript frontend on your existing `hospital_db`.
No new tables. Every number, table, filter and chart comes from SQL queries.

## Requirements
- JDK 25+ and Maven 3.9+
- MySQL 8 with `hospital_db` loaded
- VS Code with the "Extension Pack for Java" (optional but recommended)
- Internet once in the browser (Chart.js is loaded from a CDN)

## Setup
1. **Load the database** (skip if you already have it):
   `mysql -u root -p < database/hospital_db.sql`
   Note: the first line of your script is `--create database with functions`. MySQL needs a space after `--`,
   so change it to `-- create database with functions` (or delete the line), otherwise the import fails.
2. **Edit `db.properties`** – set `db.user` and `db.password` (or set env vars `DB_USER`, `DB_PASSWORD`, `DB_URL`).
3. **Run** from the project root (the folder containing `pom.xml` and `frontend/`):
   ```
   mvn compile exec:java
   ```
   Or in VS Code: open the folder, open `Main.java`, click **Run**.
4. Open **http://localhost:8080**

Change the port with `PORT=9090`.

## Structure
```
db.properties                    connection settings
src/main/java/com/hospital/
  Main.java                      starts server (API + static files, localhost only)
  Db.java / Dao.java             JDBC connection + query helper (prepared statements)
  DashboardService.java          SQL for cards, charts, billing, rooms, pharmacy
  ListService.java               SQL for the sidebar pages (search + filter)
  SearchService.java             navbar global search
  NotificationService.java       bell notifications (unpaid bills, low stock, ...)
  ApiHandler.java / Json.java    GET /api/* -> JSON
  StaticHandler.java             serves frontend/
frontend/
  index.html, css/styles.css
  js/app.js (shell, routing, search, bell)  js/dashboard.js (front page)
  js/views.js (list pages)  js/api.js  js/icons.js
```

## API
`/api/summary`, `/api/appointments/recent?status=`, `/api/patients/recent`, `/api/billing/summary`,
`/api/charts/{monthly-appointments|department-revenue|appointment-status}`, `/api/rooms/availability`,
`/api/pharmacy/low-stock`, `/api/notifications`, `/api/search?q=`,
`/api/list/{patients|doctors|departments|appointments|records|prescriptions|pharmacy|rooms|admissions|billing}?q=&filter=`

## Notes
- "Low stock" uses `stock_qty < 250` (same as your Q5).
- "Pending payments" = Pending + Partial bills (same as your `vw_pending_bills`).
- Settings / Logout are visual only – the schema has no user tables.
- The server listens on localhost only because there is no login.
