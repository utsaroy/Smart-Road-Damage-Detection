<?php
/**
 * Authority Database Connection & Schema
 * Stores ONLY real/valid data submitted by Android app users
 */

require_once __DIR__ . '/config.php';

class Database {
    private static ?PDO $pdo = null;

    public static function getConnection(): PDO {
        if (self::$pdo !== null) {
            return self::$pdo;
        }

        try {
            self::$pdo = new PDO("sqlite:" . DB_FILE, null, null, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
            ]);

            self::initDatabase(self::$pdo);
            return self::$pdo;
        } catch (Throwable $e) {
            throw new Exception("Database Connection Error: " . $e->getMessage());
        }
    }

    private static function initDatabase(PDO $pdo): void {
        $sql = "
        CREATE TABLE IF NOT EXISTS pothole_reports (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            severity TEXT NOT NULL DEFAULT 'HIGH',
            status TEXT NOT NULL DEFAULT 'reported',
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            road_name TEXT,
            district TEXT,
            landmark TEXT,
            confidence REAL DEFAULT 0.0,
            defects_count INTEGER DEFAULT 1,
            hazards_breakdown TEXT,
            image_url TEXT,
            repair_image_url TEXT,
            model_name TEXT DEFAULT 'best.tflite',
            inference_time_ms INTEGER DEFAULT 0,
            detection_source TEXT DEFAULT 'android_ai_scanner',
            user_id TEXT DEFAULT 'app_user',
            user_name TEXT DEFAULT 'App User',
            user_phone TEXT,
            device_model TEXT DEFAULT 'Android Device',
            assigned_crew TEXT,
            scheduled_repair_date TEXT,
            repair_cost REAL DEFAULT 0.0,
            repair_notes TEXT,
            reported_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
        ";
        $pdo->exec($sql);

        // Safe column additions for sorok_surokkha Android Flutter app schema alignment
        $cols = [
            "damage_type TEXT DEFAULT 'Pothole'",
            "address TEXT",
            "damage_area_sqm REAL DEFAULT 0.0",
            "crack_width_mm REAL DEFAULT 0.0",
            "estimated_depth_cm REAL DEFAULT 0.0",
            "bbox_left REAL",
            "bbox_top REAL",
            "bbox_right REAL",
            "bbox_bottom REAL",
            "image_width INTEGER",
            "image_height INTEGER",
            "detections_json TEXT",
            "division TEXT",
            "upazilla TEXT",
            "user_name TEXT DEFAULT 'App User'",
            "device_model TEXT DEFAULT 'Android Device'"
        ];
        foreach ($cols as $col) {
            try { $pdo->exec("ALTER TABLE pothole_reports ADD COLUMN {$col}"); } catch (Throwable $e) {}
        }
    }
}
