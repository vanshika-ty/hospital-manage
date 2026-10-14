package com.hospital;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

/** Database connection settings (db.properties, overridable with environment variables). */
public final class Db {
    private static final Properties PROPS = load();

    private Db() {}

    private static Properties load() {
        Properties p = new Properties();
        Path file = Paths.get("db.properties");
        if (Files.exists(file)) {
            try (var in = Files.newBufferedReader(file)) {
                p.load(in);
            } catch (IOException e) {
                System.err.println("Could not read db.properties: " + e.getMessage());
            }
        }
        return p;
    }

    private static String cfg(String envKey, String propKey, String def) {
        String v = System.getenv(envKey);
        if (v != null && !v.isEmpty()) return v;
        return PROPS.getProperty(propKey, def);
    }

    public static Connection get() throws SQLException {
        String url = cfg("DB_URL", "db.url",
                "jdbc:mysql://localhost:3306/hospital_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC");
        String user = cfg("DB_USER", "db.user", "root");
        String pass = cfg("DB_PASSWORD", "db.password", "");
        return DriverManager.getConnection(url, user, pass);
    }
}
