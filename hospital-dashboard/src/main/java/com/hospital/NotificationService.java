package com.hospital;

import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.StringJoiner;

/** Bell-icon notifications, derived live from existing tables (no extra tables needed). */
public final class NotificationService {
    private NotificationService() {}

    private static Map<String, Object> note(String level, String title, String detail, String view, String filter) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("level", level);
        m.put("title", title);
        m.put("detail", detail);
        m.put("view", view);
        m.put("filter", filter);
        return m;
    }

    public static List<Map<String, Object>> all() throws SQLException {
        List<Map<String, Object>> out = new ArrayList<>();

        Map<String, Object> bills = Dao.one("""
                SELECT COUNT(*) AS n, COALESCE(SUM(total_amount),0) AS amt
                FROM billing WHERE payment_status IN ('Pending','Partial')
                """);
        long unpaid = ((Number) bills.get("n")).longValue();
        if (unpaid > 0) {
            double amt = ((Number) bills.get("amt")).doubleValue();
            out.add(note("warning", unpaid + " unpaid bills",
                    String.format("₹%,.0f outstanding (pending + partial)", amt), "billing", "Unpaid"));
        }

        List<Map<String, Object>> low = Dao.query("""
                SELECT med_name, stock_qty FROM medications
                WHERE stock_qty < ? ORDER BY stock_qty LIMIT 3
                """, List.of(DashboardService.LOW_STOCK_THRESHOLD));
        if (!low.isEmpty()) {
            StringJoiner sj = new StringJoiner(", ");
            for (Map<String, Object> r : low) sj.add(r.get("med_name") + " (" + r.get("stock_qty") + ")");
            out.add(note("danger", "Low-stock medicines", sj.toString(), "pharmacy", null));
        }

        Map<String, Object> sched = Dao.one("""
                SELECT COUNT(*) AS n, MIN(appointment_date) AS next_date
                FROM appointments WHERE status = 'Scheduled'
                """);
        long scheduled = ((Number) sched.get("n")).longValue();
        if (scheduled > 0) {
            out.add(note("info", scheduled + " scheduled appointments",
                    "Earliest on " + sched.get("next_date"), "appointments", "Scheduled"));
        }

        Map<String, Object> adm = Dao.one("SELECT COUNT(*) AS n FROM room_assignments WHERE discharged_on IS NULL");
        long admitted = ((Number) adm.get("n")).longValue();
        if (admitted > 0) {
            out.add(note("info", admitted + " patient(s) currently admitted",
                    "Not yet discharged", "rooms", null));
        }
        return out;
    }
}
