// api_logger_service.dart
import 'dart:convert';

import 'package:api_lens/src/models/api_log.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class ApiLoggerService {
  static final ApiLoggerService _instance = ApiLoggerService._internal();
  factory ApiLoggerService() => _instance;
  ApiLoggerService._internal();

  Database? _database;
  static const String _tableName = 'api_logs';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'api_lens.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            url TEXT NOT NULL,
            method TEXT NOT NULL,
            statusCode INTEGER NOT NULL,
            duration INTEGER NOT NULL,
            timestamp TEXT NOT NULL,
            requestHeaders TEXT NOT NULL,
            requestBody TEXT NOT NULL,
            responseHeaders TEXT NOT NULL,
            responseBody TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> logRequest(ApiLog log) async {
    final db = await database;
    return await db.insert(_tableName, log.toMap());
  }

  Future<List<ApiLog>> getAllLogs() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      orderBy: 'timestamp DESC',
      limit: 1000,
    );
    return maps.map((map) => ApiLog.fromMap(map)).toList();
  }

  Future<ApiLog?> getLogById(int id) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ApiLog.fromMap(maps.first);
  }

  Future<int> deleteLog(int id) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearAllLogs() async {
    final db = await database;
    return await db.delete(_tableName);
  }

  Future<void> cleanOldLogs(int days, {bool showLogs = false}) async {
    try {
      final logs = await getAllLogs();
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      int deletedCount = 0;
      for (final log in logs) {
        try {
          final logDate = DateTime.parse(log.timestamp);
          if (logDate.isBefore(cutoffDate) && log.id != null) {
            await deleteLog(log.id!);
            deletedCount++;
          }
        } catch (e) {
          // Skip invalid timestamps
        }
      }

      if (deletedCount > 0 && showLogs && kDebugMode) {
        debugPrint('🔍 API Lens: Deleted $deletedCount old logs');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔍 API Lens: Error cleaning old logs: $e');
      }
    }
  }

  Future<void> enforceMaxLogs(int maxLogs, {bool showLogs = false}) async {
    try {
      final logs = await getAllLogs();
      if (logs.length > maxLogs) {
        final logsToDelete = logs.length - maxLogs;
        for (int i = logs.length - logsToDelete; i < logs.length; i++) {
          if (logs[i].id != null) {
            await deleteLog(logs[i].id!);
          }
        }

        if (showLogs && kDebugMode) {
          debugPrint(
              '🔍 API Lens: Deleted $logsToDelete old logs (max: $maxLogs)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔍 API Lens: Error enforcing max logs: $e');
      }
    }
  }

  Future<String> exportLogsAsJson() async {
    final logs = await getAllLogs();
    final jsonList = logs.map((log) => log.toMap()).toList();
    return jsonEncode(jsonList);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
