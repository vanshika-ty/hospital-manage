package com.hospital;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Tiny JDBC helper: runs a SELECT and returns rows as ordered maps (column label -> value). */
public final class Dao {
    private Dao() {}

    public static List<Map<String, Object>> query(String sql, List<?> params) throws SQLException {
        try (Connection c = Db.get(); PreparedStatement ps = c.prepareStatement(sql)) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                ResultSetMetaData md = rs.getMetaData();
                int n = md.getColumnCount();
                List<Map<String, Object>> rows = new ArrayList<>();
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    for (int i = 1; i <= n; i++) {
                        row.put(md.getColumnLabel(i), rs.getObject(i));
                    }
                    rows.add(row);
                }
                return rows;
            }
        }
    }

    public static List<Map<String, Object>> query(String sql) throws SQLException {
        return query(sql, List.of());
    }

    /** First row of the result, or an empty map. */
    public static Map<String, Object> one(String sql) throws SQLException {
        List<Map<String, Object>> rows = query(sql);
        return rows.isEmpty() ? new LinkedHashMap<>() : rows.get(0);
    }
}
