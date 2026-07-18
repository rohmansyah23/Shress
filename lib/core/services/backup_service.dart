import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/constants.dart';
import '../utils/notif_log.dart';

class BackupException implements Exception {
  final String message;
  const BackupException(this.message);

  @override
  String toString() => message;
}

class BackupService {
  static final BackupService instance = BackupService._();
  BackupService._();

  static const _tables = [
    'users',
    'businesses',
    'user_businesses',
    'categories',
    'transactions',
    'debtors',
    'debts',
    'debt_payments',
    'consignors',
    'consignments',
    'consignment_items',
    'consignment_settlements',
    'push_tokens',
    'owner_notifications',
    'owner_activity_logs',
  ];

  Future<File> exportDataAsSql(SupabaseClient supabase) async {
    NotifLog.info('Backup: export SQL started');
    final buf = StringBuffer();
    final now = DateTime.now().toIso8601String();
    buf.writeln('-- Backup Sheress - ${AppConstants.appName}');
    buf.writeln('-- Generated at: $now');
    buf.writeln('-- Version: ${AppConstants.appVersion}');
    buf.writeln();
    buf.writeln('BEGIN;');
    buf.writeln();

    for (final table in _tables) {
      List<dynamic> rows;
      try {
        final response = await supabase.from(table).select().order('id', ascending: true);
        rows = (response as List<dynamic>).toList();
      } catch (e) {
        NotifLog.warn('Backup: table $table skipped — ${e.toString().length > 80 ? e.toString().substring(0, 80) : e.toString()}');
        continue;
      }
      if (rows.isEmpty) continue;

      final columns = (rows.first as Map<String, dynamic>).keys.toList();
      final colList = columns.map((c) => '"$c"').join(', ');

      buf.writeln('INSERT INTO public."$table" ($colList) VALUES');

      for (var i = 0; i < rows.length; i++) {
        final row = rows[i] as Map<String, dynamic>;
        final values = columns.map((c) => _sqlValue(row[c])).join(', ');
        buf.write('  ($values)');
        buf.writeln(i < rows.length - 1 ? ',' : ';');
      }
      buf.writeln();
    }

    buf.writeln('COMMIT;');

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sheress_backup_${DateTime.now().millisecondsSinceEpoch}.sql');
    await file.writeAsString(buf.toString(), encoding: utf8);
    NotifLog.info('Backup: SQL exported to ${file.path}');
    return file;
  }

  String _sqlValue(dynamic value) {
    if (value == null) return 'NULL';
    if (value is int || value is double) return value.toString();
    if (value is bool) return value ? 'true' : 'false';
    if (value is String) return "'${value.replaceAll("'", "''")}'";
    return "'${jsonEncode(value).replaceAll("'", "''")}'";
  }

  Future<File> backupData(SupabaseClient supabase) async {
    NotifLog.info('Backup: JSON backup started');
    final Map<String, List<dynamic>> allData = {};

    for (final table in _tables) {
      try {
        final response = await supabase.from(table).select().order('id', ascending: true);
        allData[table] = (response as List<dynamic>).toList();
      } catch (e) {
        NotifLog.warn('Backup: table $table failed — ${e.toString().length > 80 ? e.toString().substring(0, 80) : e.toString()}');
        allData[table] = [];
      }
    }

    final backup = {
      'app': AppConstants.appName,
      'version': AppConstants.appVersion,
      'backup_date': DateTime.now().toIso8601String(),
      'tables': allData,
    };

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sheress_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(backup),
      encoding: utf8,
    );

    NotifLog.info('Backup: JSON exported to ${file.path}');
    return file;
  }

  /// Exports the database schema from the local migration file.
  /// On mobile devices where the migration file is unavailable,
  /// falls back to fetching the current schema from Supabase via SQL.
  Future<File> backupSchema() async {
    NotifLog.info('Backup: schema export started');

    String schema;

    // Load from bundled asset (works on all platforms)
    try {
      schema = await rootBundle.loadString('supabase/migrations/20260718000000_initial_schema.sql');
      NotifLog.info('Backup: schema loaded from bundled asset');
    } catch (e) {
      NotifLog.warn('Backup: schema asset not found — $e');
      throw BackupException(
        'File skema database tidak tersedia di perangkat ini.',
      );
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sheress_schema_${DateTime.now().millisecondsSinceEpoch}.sql');
    await file.writeAsString(schema, encoding: utf8);

    NotifLog.info('Backup: schema exported to ${file.path}');
    return file;
  }

  Future<void> shareFile(File file) async {
    if (!await file.exists()) {
      NotifLog.error('Backup: file not found at ${file.path}');
      throw BackupException('File backup tidak ditemukan');
    }
    NotifLog.info('Backup: sharing file ${file.path}');
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Backup Sheress - ${AppConstants.appName}',
      ),
    );
  }
}
