import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'models.dart';

/// DatabaseService handles local SQLite storage for damage reports,
/// active hazard alerts, and user application settings.
class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();

  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'amar_path.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Damage Reports Table
    await db.execute('''
      CREATE TABLE damage_reports (
        id TEXT PRIMARY KEY,
        damageType TEXT NOT NULL,
        severity TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        address TEXT,
        timestamp TEXT NOT NULL,
        status TEXT NOT NULL,
        confidenceScore REAL,
        reportedBy TEXT,
        damageAreaSqM REAL,
        notes TEXT,
        imagePath TEXT,
        crackWidthMm REAL,
        estimatedDepthCm REAL,
        detections TEXT,
        bbox_left REAL,
        bbox_top REAL,
        bbox_right REAL,
        bbox_bottom REAL,
        imageWidth INTEGER,
        imageHeight INTEGER
      )
    ''');

    // Index on timestamp for fast chronology ordering
    await db.execute('''
      CREATE INDEX idx_reports_timestamp ON damage_reports (timestamp DESC)
    ''');

    // 2. Hazard Alerts Table
    await db.execute('''
      CREATE TABLE hazard_alerts (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        severity TEXT NOT NULL,
        distanceMeters REAL,
        address TEXT,
        damageType TEXT,
        lastReported TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 3. Key-Value Settings Table
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    debugPrint('[DatabaseService] Database schema v$version initialized.');
  }

  // ==================== Damage Reports CRUD ====================

  Future<void> insertReport(DamageReport report) async {
    try {
      final db = await database;
      await db.insert(
        'damage_reports',
        report.toDatabaseMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[DatabaseService] Error inserting report: $e');
    }
  }

  Future<List<DamageReport>> getAllReports() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'damage_reports',
        orderBy: 'timestamp DESC',
      );
      return maps.map((m) => DamageReport.fromMap(m)).toList();
    } catch (e) {
      debugPrint('[DatabaseService] Error loading reports: $e');
      return [];
    }
  }

  Future<void> updateReportStatus(String reportId, String newStatus) async {
    try {
      final db = await database;
      await db.update(
        'damage_reports',
        {'status': newStatus},
        where: 'id = ?',
        whereArgs: [reportId],
      );
    } catch (e) {
      debugPrint('[DatabaseService] Error updating report status: $e');
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      final db = await database;
      await db.delete(
        'damage_reports',
        where: 'id = ?',
        whereArgs: [reportId],
      );
    } catch (e) {
      debugPrint('[DatabaseService] Error deleting report: $e');
    }
  }

  Future<void> clearAllReports() async {
    try {
      final db = await database;
      await db.delete('damage_reports');
    } catch (e) {
      debugPrint('[DatabaseService] Error clearing reports: $e');
    }
  }

  // ==================== Hazard Alerts CRUD ====================

  Future<void> insertAlert(HazardAlert alert) async {
    try {
      final db = await database;
      await db.insert(
        'hazard_alerts',
        alert.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[DatabaseService] Error inserting alert: $e');
    }
  }

  Future<List<HazardAlert>> getAllAlerts() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'hazard_alerts',
        orderBy: 'lastReported DESC',
      );
      return maps.map((m) => HazardAlert.fromMap(m)).toList();
    } catch (e) {
      debugPrint('[DatabaseService] Error loading alerts: $e');
      return [];
    }
  }

  Future<void> updateAlertActive(String alertId, bool isActive) async {
    try {
      final db = await database;
      await db.update(
        'hazard_alerts',
        {'isActive': isActive ? 1 : 0},
        where: 'id = ?',
        whereArgs: [alertId],
      );
    } catch (e) {
      debugPrint('[DatabaseService] Error updating alert active: $e');
    }
  }

  Future<void> deleteAlert(String alertId) async {
    try {
      final db = await database;
      await db.delete(
        'hazard_alerts',
        where: 'id = ?',
        whereArgs: [alertId],
      );
    } catch (e) {
      debugPrint('[DatabaseService] Error deleting alert: $e');
    }
  }

  Future<void> clearAllAlerts() async {
    try {
      final db = await database;
      await db.delete('hazard_alerts');
    } catch (e) {
      debugPrint('[DatabaseService] Error clearing alerts: $e');
    }
  }

  // ==================== App Settings CRUD ====================

  Future<void> saveSetting(String key, String value) async {
    try {
      final db = await database;
      await db.insert(
        'app_settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[DatabaseService] Error saving setting: $e');
    }
  }

  Future<String?> getSetting(String key) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'app_settings',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return maps.first['value'] as String?;
      }
    } catch (e) {
      debugPrint('[DatabaseService] Error getting setting: $e');
    }
    return null;
  }

  Future<Map<String, String>> getAllSettings() async {
    final result = <String, String>{};
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('app_settings');
      for (final row in maps) {
        final k = row['key'] as String?;
        final v = row['value'] as String?;
        if (k != null && v != null) {
          result[k] = v;
        }
      }
    } catch (e) {
      debugPrint('[DatabaseService] Error getting all settings: $e');
    }
    return result;
  }
}
