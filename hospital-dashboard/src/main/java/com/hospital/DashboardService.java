package com.hospital;

import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** SQL behind every widget of the dashboard front page. All numbers come from hospital_db. */
public final class DashboardService {
    /** Same threshold your Q5 uses ("stock less than 250"). */
    public static final int LOW_STOCK_THRESHOLD = 250;

    private DashboardService() {}

    /** Summary cards. */
    public static Map<String, Object> summary() throws SQLException {
        return Dao.one("""
                SELECT
                  (SELECT COUNT(*) FROM patients)                                         AS total_patients,
                  (SELECT COUNT(*) FROM doctors)                                          AS total_doctors,
                  (SELECT COUNT(*) FROM departments)                                      AS total_departments,
                  (SELECT COUNT(*) FROM appointments)                                     AS total_appointments,
                  (SELECT COUNT(*) FROM appointments WHERE status = 'Scheduled')          AS scheduled_appointments,
                  (SELECT COUNT(*) FROM rooms)                                            AS total_rooms,
                  (SELECT COUNT(*) FROM rooms WHERE is_available = TRUE)                  AS available_rooms,
                  (SELECT COUNT(*) FROM billing WHERE payment_status IN ('Pending','Partial'))  AS pending_payments,
                  (SELECT COALESCE(SUM(total_amount),0) FROM billing
                     WHERE payment_status IN ('Pending','Partial'))                       AS pending_amount
                """);
    }

    /** Recent appointments with patient, doctor, department, date and status. */
    public static List<Map<String, Object>> recentAppointments(int limit, String status) throws SQLException {
        StringBuilder sql = new StringBuilder("""
                SELECT a.appointment_id,
                       CONCAT(p.first_name, ' ', p.last_name)        AS patient_name,
                       CONCAT('Dr. ', d.first_name, ' ', d.last_name) AS doctor_name,
                       dept.dept_name                                 AS department,
                       a.appointment_date, a.appointment_time, a.reason, a.status
                FROM appointments a
                JOIN patients p ON a.patient_id = p.patient_id
                JOIN doctors  d ON a.doctor_id  = d.doctor_id
                LEFT JOIN departments dept ON d.department_id = dept.department_id
                """);
        List<Object> params = new ArrayList<>();
        if (status != null && !status.isBlank() && !status.equals("All")) {
            sql.append(" WHERE a.status = ? ");
            params.add(status);
        }
        sql.append(" ORDER BY a.appointment_date DESC, a.appointment_time DESC, a.appointment_id DESC LIMIT ?");
        params.add(limit);
        return Dao.query(sql.toString(), params);
    }

    /** Recently registered patients. */
    public static List<Map<String, Object>> recentPatients(int limit) throws SQLException {
        return Dao.query("""
                SELECT patient_id, CONCAT(first_name, ' ', last_name) AS name,
                       gender, blood_group, registered_on
                FROM patients
                ORDER BY registered_on DESC, patient_id DESC
                LIMIT ?
                """, List.of(limit));
    }

    /** Billing summary: revenue and bills per payment status. */
    public static Map<String, Object> billingSummary() throws SQLException {
        return Dao.one("""
                SELECT
                  COALESCE(SUM(total_amount),0)                                               AS total_revenue,
                  COUNT(*)                                                                    AS total_bills,
                  COUNT(CASE WHEN payment_status = 'Paid'    THEN 1 END)                      AS paid_count,
                  COALESCE(SUM(CASE WHEN payment_status = 'Paid'    THEN total_amount END),0) AS paid_amount,
                  COUNT(CASE WHEN payment_status = 'Pending' THEN 1 END)                      AS pending_count,
                  COALESCE(SUM(CASE WHEN payment_status = 'Pending' THEN total_amount END),0) AS pending_amount,
                  COUNT(CASE WHEN payment_status = 'Partial' THEN 1 END)                      AS partial_count,
                  COALESCE(SUM(CASE WHEN payment_status = 'Partial' THEN total_amount END),0) AS partial_amount
                FROM billing
                """);
    }

    /** Chart 1: appointments per month. */
    public static List<Map<String, Object>> monthlyAppointments() throws SQLException {
        return Dao.query("""
                SELECT DATE_FORMAT(appointment_date, '%Y-%m') AS ym,
                       DATE_FORMAT(appointment_date, '%b %Y') AS label,
                       COUNT(*) AS total
                FROM appointments
                GROUP BY ym, label
                ORDER BY ym
                """);
    }

    /** Chart 2: revenue per department (same joins as your Q17). */
    public static List<Map<String, Object>> departmentRevenue() throws SQLException {
        return Dao.query("""
                SELECT dept.dept_name, SUM(b.total_amount) AS revenue, COUNT(b.bill_id) AS bills
                FROM billing b
                JOIN appointments a   ON b.appointment_id = a.appointment_id
                JOIN doctors      d   ON a.doctor_id      = d.doctor_id
                JOIN departments  dept ON d.department_id = dept.department_id
                GROUP BY dept.dept_name
                ORDER BY revenue DESC
                """);
    }

    /** Chart 3: appointment status distribution. */
    public static List<Map<String, Object>> appointmentStatus() throws SQLException {
        return Dao.query("""
                SELECT status, COUNT(*) AS total
                FROM appointments
                GROUP BY status
                ORDER BY total DESC
                """);
    }

    /** Room availability: totals, ICU and a per-type breakdown. */
    public static Map<String, Object> roomAvailability() throws SQLException {
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("summary", Dao.one("""
                SELECT COUNT(*)                                                     AS total_rooms,
                       COUNT(CASE WHEN is_available = TRUE  THEN 1 END)             AS available_rooms,
                       COUNT(CASE WHEN is_available = FALSE THEN 1 END)             AS occupied_rooms,
                       COUNT(CASE WHEN room_type = 'ICU' THEN 1 END)                AS icu_total,
                       COUNT(CASE WHEN room_type = 'ICU' AND is_available = TRUE THEN 1 END) AS icu_available
                FROM rooms
                """));
        out.put("by_type", Dao.query("""
                SELECT room_type, COUNT(*) AS total,
                       COUNT(CASE WHEN is_available = TRUE THEN 1 END) AS available
                FROM rooms
                GROUP BY room_type
                ORDER BY FIELD(room_type, 'General', 'Semi-Private', 'Private', 'ICU')
                """));
        return out;
    }

    /** Medicines below the stock threshold. */
    public static Map<String, Object> lowStock(int limit) throws SQLException {
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("threshold", LOW_STOCK_THRESHOLD);
        out.put("items", Dao.query("""
                SELECT medication_id, med_name, category, stock_qty, unit_price
                FROM medications
                WHERE stock_qty < ?
                ORDER BY stock_qty ASC, med_name
                LIMIT ?
                """, List.of(LOW_STOCK_THRESHOLD, limit)));
        return out;
    }
}
