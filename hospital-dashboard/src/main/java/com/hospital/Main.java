package com.hospital;

import com.sun.net.httpserver.HttpServer;

import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.concurrent.Executors;

/** Starts the dashboard: JSON API under /api and the web pages from ./frontend. */
public class Main {
    public static void main(String[] args) throws Exception {
        int port = Integer.parseInt(System.getenv().getOrDefault("PORT", "8080"));
        Path web = Paths.get(System.getenv().getOrDefault("FRONTEND_DIR", "frontend")).toAbsolutePath().normalize();

        if (!Files.isDirectory(web)) {
            System.err.println("Frontend folder not found: " + web);
            System.err.println("Run the app from the project root (the folder that contains 'frontend' and 'pom.xml').");
            System.exit(1);
        }

        try (var c = Db.get()) {
            System.out.println("Connected to MySQL: " + c.getMetaData().getURL());
        } catch (Exception e) {
            System.err.println("WARNING: could not connect to MySQL -> " + e.getMessage());
            System.err.println("Check db.properties (URL, user, password) and that hospital_db exists.");
        }

        // Bound to localhost only: the dashboard shows patient data and has no login.
        HttpServer server = HttpServer.create(new InetSocketAddress(InetAddress.getLoopbackAddress(), port), 0);
        server.createContext("/api/", new ApiHandler());
        server.createContext("/", new StaticHandler(web));
        server.setExecutor(Executors.newFixedThreadPool(8));
        server.start();

        System.out.println("Hospital dashboard running at http://localhost:" + port);
    }
}
