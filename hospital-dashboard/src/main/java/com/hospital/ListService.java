package com.hospital;

import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Generic searchable/filterable table data for the sidebar pages (Patients, Doctors, ...).
 * Every definition below only uses tables and columns that already exist in hospital_db.
 * SQL fragments are constants defined here; user input is only ever bound as a parameter.
 */
public final class ListService {
    private record Def(String select, String from, String search, String filter, String order) {}

    private static final Map<String, Def> DEFS = new LinkedHashMap<>();

    static {
        DEFS.put("patients", new Def(
                "p.patient_id, CONCAT(p.first_name,' ',p.last_name) AS name, p.gender, p.blood_group, "
                        + "p.date_of_birth, p.phone, p.email, p.address, p.registered_on",
                "patients p",
                "CONCAT_WS(' ', p.patient_id, p.first_name, p.last_name, p.phone, p.blood_group)",
                "p.gender",
                "p.patient_id"));

        DEFS.put("doctors", new Def(
                "d.doctor_id, CONCAT('Dr. ',d.first_name,' ',d.last_name) AS name, d.specialization, "
                        + "dept.dept_name AS department, d.phone, d.email, d.joining_date, d.salary",
                "doctors d LEFT JOIN departments dept ON d.department_id = dept.department_id",
                "CONCAT_WS(' ', d.first_name, d.last_name, d.specialization, dept.dept_name)",
                "dept.dept_name",
                "d.doctor_id"));

        DEFS.put("departments", new Def(
                "dept.department_id, dept.dept_name, dept.location, "
                        + "CONCAT('Dr. ',hd.first_name,' ',hd.last_name) AS head_doctor, "
                        + "(SELECT COUNT(*) FROM doctors dd WHERE dd.department_id = dept.department_id) AS doctors, "
                        + "(SELECT COUNT(*) FROM nurses  n  WHERE n.department_id  = dept.department_id) AS nurses",
                "departments dept LEFT JOIN doctors hd ON dept.head_doctor_id = hd.doctor_id",
                "CONCAT_WS(' ', dept.dept_name, dept.location)",
                null,
                "dept.department_id"));

        DEFS.put("appointments", new Def(
                "a.appointment_id, CONCAT(p.first_name,' ',p.last_name) AS patient_name, "
                        + "CONCAT('Dr. ',d.first_name,' ',d.last_name) AS doctor_name, dept.dept_name AS department, "
                        + "a.appointment_date, a.appointment_time, a.reason, a.status",
                "appointments a JOIN patients p ON a.patient_id = p.patient_id "
                        + "JOIN doctors d ON a.doctor_id = d.doctor_id "
                        + "LEFT JOIN departments dept ON d.department_id = dept.department_id",
                "CONCAT_WS(' ', p.first_name, p.last_name, d.first_name, d.last_name, dept.dept_name, a.reason)",
                "a.status",
                "a.appointment_date DESC, a.appointment_time DESC"));

        DEFS.put("records", new Def(
                "mr.record_id, CONCAT(p.first_name,' ',p.last_name) AS patient_name, "
                        + "CONCAT('Dr. ',d.first_name,' ',d.last_name) AS doctor_name, "
                        + "mr.visit_date, mr.diagnosis, mr.treatment, mr.notes",
                "medical_records mr JOIN patients p ON mr.patient_id = p.patient_id "
                        + "JOIN doctors d ON mr.doctor_id = d.doctor_id",
                "CONCAT_WS(' ', p.first_name, p.last_name, d.first_name, d.last_name, mr.diagnosis, mr.treatment)",
                null,
                "mr.visit_date DESC, mr.record_id DESC"));

        DEFS.put("prescriptions", new Def(
                "pr.prescription_id, CONCAT(p.first_name,' ',p.last_name) AS patient_name, "
                        + "CONCAT('Dr. ',d.first_name,' ',d.last_name) AS doctor_name, m.med_name, "
                        + "pr.dosage, pr.duration_days, pr.prescribed_date",
                "prescriptions pr JOIN medical_records mr ON pr.record_id = mr.record_id "
                        + "JOIN patients p ON mr.patient_id = p.patient_id "
                        + "JOIN doctors d ON mr.doctor_id = d.doctor_id "
                        + "JOIN medications m ON pr.medication_id = m.medication_id",
                "CONCAT_WS(' ', p.first_name, p.last_name, d.first_name, d.last_name, m.med_name)",
                "m.category",
                "pr.prescribed_date DESC, pr.prescription_id DESC"));

        DEFS.put("pharmacy", new Def(
                "m.medication_id, m.med_name, m.category, m.manufacturer, m.unit_price, m.stock_qty, "
                        + "CASE WHEN m.stock_qty < " + DashboardService.LOW_STOCK_THRESHOLD
                        + " THEN 'Low' ELSE 'OK' END AS stock_status",
                "medications m",
                "CONCAT_WS(' ', m.med_name, m.category, m.manufacturer)",
                "m.category",
                "m.stock_qty ASC, m.med_name"));

        DEFS.put("rooms", new Def(
                "r.room_id, r.room_number, r.room_type, dept.dept_name AS department, "
                        + "CASE WHEN r.is_available THEN 'Available' ELSE 'Occupied' END AS availability, "
                        + "r.price_per_day",
                "rooms r LEFT JOIN departments dept ON r.department_id = dept.department_id",
                "CONCAT_WS(' ', r.room_number, r.room_type, dept.dept_name)",
                "r.room_type",
                "r.room_number"));

        DEFS.put("admissions", new Def(
                "ra.assignment_id, CONCAT(p.first_name,' ',p.last_name) AS patient_name, r.room_number, "
                        + "r.room_type, ra.admitted_on, ra.discharged_on, "
                        + "CASE WHEN ra.discharged_on IS NULL THEN 'Admitted' ELSE 'Discharged' END AS status",
                "room_assignments ra JOIN patients p ON ra.patient_id = p.patient_id "
                        + "JOIN rooms r ON ra.room_id = r.room_id",
                "CONCAT_WS(' ', p.first_name, p.last_name, r.room_number, r.room_type)",
                "CASE WHEN ra.discharged_on IS NULL THEN 'Admitted' ELSE 'Discharged' END",
                "ra.admitted_on DESC, ra.assignment_id DESC"));

        DEFS.put("billing", new Def(
                "b.bill_id, CONCAT(p.first_name,' ',p.last_name) AS patient_name, b.bill_date, "
                        + "b.room_charges, b.doctor_fees, b.medication_cost, b.other_charges, "
                        + "b.total_amount, b.payment_status",
                "billing b JOIN patients p ON b.patient_id = p.patient_id",
                "CONCAT_WS(' ', b.bill_id, p.first_name, p.last_name)",
                "b.payment_status",
                "b.bill_date DESC, b.bill_id DESC"));
    }

    private ListService() {}

    private static Def def(String name) {
        Def d = DEFS.get(name);
        if (d == null) throw new IllegalArgumentException("Unknown list: " + name);
        return d;
    }

    /** Escapes LIKE wildcards so user text is matched literally. */
    static String like(String q) {
        return "%" + q.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%";
    }

    public static List<Map<String, Object>> list(String name, String q, String filter, int limit) throws SQLException {
        Def d = def(name);
        List<String> where = new ArrayList<>();
        List<Object> params = new ArrayList<>();

        if (q != null && !q.isBlank()) {
            where.add(d.search() + " LIKE ?");
            params.add(like(q.trim()));
        }
        if (d.filter() != null && filter != null && !filter.isBlank() && !filter.equals("All")) {
            if (filter.equals("Unpaid")) { // Pending + Partial, like your vw_pending_bills view
                where.add(d.filter() + " IN ('Pending','Partial')");
            } else {
                where.add(d.filter() + " = ?");
                params.add(filter);
            }
        }

        String sql = "SELECT " + d.select() + " FROM " + d.from()
                + (where.isEmpty() ? "" : " WHERE " + String.join(" AND ", where))
                + " ORDER BY " + d.order() + " LIMIT " + limit;
        return Dao.query(sql, params);
    }

    /** Distinct values for the filter drop-down of a list. */
    public static List<Object> filters(String name) throws SQLException {
        Def d = def(name);
        List<Object> out = new ArrayList<>();
        if (d.filter() == null) return out;
        String sql = "SELECT DISTINCT " + d.filter() + " AS v FROM " + d.from()
                + " WHERE " + d.filter() + " IS NOT NULL ORDER BY v";
        for (Map<String, Object> row : Dao.query(sql)) out.add(row.get("v"));
        return out;
    }
}
