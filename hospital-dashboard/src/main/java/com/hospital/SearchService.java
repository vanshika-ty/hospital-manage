package com.hospital;

import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Global search box in the top navbar: patients, doctors and medicines. */
public final class SearchService {
    private SearchService() {}

    public static Map<String, Object> search(String q) throws SQLException {
        Map<String, Object> out = new LinkedHashMap<>();
        if (q == null || q.trim().length() < 2) {
            out.put("patients", List.of());
            out.put("doctors", List.of());
            out.put("medicines", List.of());
            return out;
        }
        String like = ListService.like(q.trim());

        out.put("patients", Dao.query("""
                SELECT patient_id AS id, CONCAT(first_name,' ',last_name) AS name,
                       CONCAT_WS(' · ', blood_group, phone) AS detail
                FROM patients
                WHERE CONCAT_WS(' ', patient_id, first_name, last_name, phone) LIKE ?
                ORDER BY first_name LIMIT 5
                """, List.of(like)));

        out.put("doctors", Dao.query("""
                SELECT doctor_id AS id, CONCAT('Dr. ',first_name,' ',last_name) AS name,
                       specialization AS detail
                FROM doctors
                WHERE CONCAT_WS(' ', first_name, last_name, specialization) LIKE ?
                ORDER BY first_name LIMIT 5
                """, List.of(like)));

        out.put("medicines", Dao.query("""
                SELECT medication_id AS id, med_name AS name,
                       CONCAT(category, ' · stock ', stock_qty) AS detail
                FROM medications
                WHERE CONCAT_WS(' ', med_name, category) LIKE ?
                ORDER BY med_name LIMIT 5
                """, List.of(like)));
        return out;
    }
}
