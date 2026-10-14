package com.hospital;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;

import java.io.IOException;
import java.io.OutputStream;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

/** Routes GET /api/... requests to the services and returns JSON. */
public class ApiHandler implements HttpHandler {

    @Override
    public void handle(HttpExchange ex) throws IOException {
        try {
            if (!"GET".equals(ex.getRequestMethod())) {
                send(ex, 405, Map.of("error", "Only GET is supported"));
                return;
            }
            String path = ex.getRequestURI().getPath();
            Map<String, String> q = parseQuery(ex.getRequestURI().getRawQuery());
            Object body = route(path, q);
            if (body == null) {
                send(ex, 404, Map.of("error", "Unknown endpoint: " + path));
            } else {
                send(ex, 200, body);
            }
        } catch (IllegalArgumentException e) {
            send(ex, 400, Map.of("error", e.getMessage()));
        } catch (SQLException e) {
            e.printStackTrace();
            send(ex, 500, Map.of("error", "Database error: " + e.getMessage()));
        } catch (Exception e) {
            e.printStackTrace();
            send(ex, 500, Map.of("error", "Server error: " + e.getMessage()));
        }
    }

    private Object route(String path, Map<String, String> q) throws SQLException {
        switch (path) {
            case "/api/summary":                    return DashboardService.summary();
            case "/api/appointments/recent":        return DashboardService.recentAppointments(limit(q, 6), q.get("status"));
            case "/api/patients/recent":            return DashboardService.recentPatients(limit(q, 6));
            case "/api/billing/summary":            return DashboardService.billingSummary();
            case "/api/charts/monthly-appointments": return DashboardService.monthlyAppointments();
            case "/api/charts/department-revenue":  return DashboardService.departmentRevenue();
            case "/api/charts/appointment-status":  return DashboardService.appointmentStatus();
            case "/api/rooms/availability":         return DashboardService.roomAvailability();
            case "/api/pharmacy/low-stock":         return DashboardService.lowStock(limit(q, 10));
            case "/api/notifications":              return NotificationService.all();
            case "/api/search":                     return SearchService.search(q.getOrDefault("q", ""));
            default: break;
        }
        String prefix = "/api/list/";
        if (path.startsWith(prefix)) {
            String rest = path.substring(prefix.length());
            if (rest.endsWith("/filters")) {
                return ListService.filters(rest.substring(0, rest.length() - "/filters".length()));
            }
            return ListService.list(rest, q.get("q"), q.get("filter"), limit(q, 500));
        }
        return null;
    }

    private static int limit(Map<String, String> q, int def) {
        try {
            int n = Integer.parseInt(q.getOrDefault("limit", String.valueOf(def)));
            return Math.max(1, Math.min(n, 1000));
        } catch (NumberFormatException e) {
            return def;
        }
    }

    static Map<String, String> parseQuery(String raw) {
        Map<String, String> out = new HashMap<>();
        if (raw == null || raw.isEmpty()) return out;
        for (String pair : raw.split("&")) {
            int i = pair.indexOf('=');
            String k = i < 0 ? pair : pair.substring(0, i);
            String v = i < 0 ? "" : pair.substring(i + 1);
            out.put(URLDecoder.decode(k, StandardCharsets.UTF_8), URLDecoder.decode(v, StandardCharsets.UTF_8));
        }
        return out;
    }

    private static void send(HttpExchange ex, int status, Object body) throws IOException {
        byte[] bytes = Json.stringify(body).getBytes(StandardCharsets.UTF_8);
        ex.getResponseHeaders().set("Content-Type", "application/json; charset=utf-8");
        ex.getResponseHeaders().set("Cache-Control", "no-store");
        ex.sendResponseHeaders(status, bytes.length);
        try (OutputStream os = ex.getResponseBody()) {
            os.write(bytes);
        }
    }
}
