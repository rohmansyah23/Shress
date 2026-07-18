// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Test komprehensif untuk notifikasi owner (owner_activity_logs)
/// saat staff/manager melakukan INSERT, UPDATE, DELETE pada:
/// - transactions
/// - debts (piutang)
/// - consignments (titipan)
///
/// Test ini membuat data prerequisites jika belum ada,
/// lalu membersihkan semua data test di akhir (try/finally).
void main() {
  test('Owner CUD notifications - transactions, debts, consignments', () async {
    // ── Read .env ──────────────────────────────────────────────
    final envFile = File('.env');
    expect(await envFile.exists(), true, reason: '.env file not found');

    final lines = await envFile.readAsLines();
    String? url;
    String? anonKey;
    String? serviceRoleKey;
    for (var line in lines) {
      if (line.startsWith('SUPABASE_URL=')) {
        url = line.split('=').sublist(1).join('=').trim();
      }
      if (line.startsWith('SUPABASE_ANON_KEY=')) {
        anonKey = line.split('=').sublist(1).join('=').trim();
      }
      if (line.startsWith('SUPABASE_SERVICE_ROLE_KEY=')) {
        serviceRoleKey = line.split('=').sublist(1).join('=').trim();
      }
    }

    expect(url, isNotNull, reason: 'SUPABASE_URL not found in .env');
    expect(anonKey, isNotNull, reason: 'SUPABASE_ANON_KEY not found in .env');
    expect(serviceRoleKey, isNotNull, reason: 'SUPABASE_SERVICE_ROLE_KEY not found in .env');

    final admin = SupabaseClient(url!, serviceRoleKey!);

    // ── Tracking IDs for cleanup ───────────────────────────────
    final createdUserIds = <String>[];
    int? businessId;
    int? categoryId;
    int? debtorId;
    int? consignorId;
    final createdTransactionIds = <int>[];
    final createdDebtIds = <int>[];
    final createdConsignmentIds = <int>[];
    final createdLogIds = <String>[];
    final createdPushTokenIds = <String>[];

    try {
      // ══════════════════════════════════════════════════════════
      // PHASE 0: Create prerequisite data
      // ══════════════════════════════════════════════════════════
      print('\n=== PHASE 0: MEMBUAT DATA PREREQUISITES ===');

      final ts = DateTime.now().millisecondsSinceEpoch;

      // 0a. Create test owner + staff users
      // UUID last segment must be exactly 12 hex chars
      final hexTs = ts.toRadixString(16).padLeft(10, '0').substring(0, 8);
      final ownerId = '00000000-0000-0000-0000-${hexTs}aa01';
      final staffId = '00000000-0000-0000-0000-${hexTs}aa02';
      createdUserIds.addAll([ownerId, staffId]);

      await admin.from('users').upsert([
        {
          'id': ownerId,
          'email': 'test_owner_notif_$ts@ssrs.com',
          'username': 'test_owner_notif_$ts',
          'display_name': 'Test Owner',
          'role': 'owner',
          'is_active': true,
        },
        {
          'id': staffId,
          'email': 'test_staff_notif_$ts@ssrs.com',
          'username': 'test_staff_notif_$ts',
          'display_name': 'Test Staff',
          'role': 'staff',
          'is_active': true,
        },
      ]);
      print('  Users dibuat: owner=$ownerId, staff=$staffId');

      // 0b. Create business
      final bizResult = await admin.from('businesses').insert({
        'name': 'Test Business Notif $ts',
        'description': 'Business untuk test notifikasi',
      }).select('id').single();
      businessId = bizResult['id'] as int;
      print('  Business dibuat: id=$businessId');

      // 0c. Link users to business
      await admin.from('user_businesses').insert([
        {'user_id': ownerId, 'business_id': businessId},
        {'user_id': staffId, 'business_id': businessId},
      ]);
      print('  Users linked ke business');

      // 0d. Create category (required for transactions)
      final catResult = await admin.from('categories').insert({
        'business_id': businessId,
        'name': 'Test Category',
        'type': 'income',
      }).select('id').single();
      categoryId = catResult['id'] as int;
      print('  Category dibuat: id=$categoryId');

      // 0e. Create debtor (required for debts)
      final debtorResult = await admin.from('debtors').insert({
        'business_id': businessId,
        'name': 'Test Debtor',
        'phone': '08123456789',
      }).select('id').single();
      debtorId = debtorResult['id'] as int;
      print('  Debtor dibuat: id=$debtorId');

      // 0f. Create consignor (required for consignments)
      final consignorResult = await admin.from('consignors').insert({
        'business_id': businessId,
        'name': 'Test Consignor',
        'phone': '08987654321',
      }).select('id').single();
      consignorId = consignorResult['id'] as int;
      print('  Consignor dibuat: id=$consignorId');

      // 0g. Create push_token for owner (needed by edge function)
      final pushResult = await admin.from('push_tokens').insert({
        'user_id': ownerId,
        'fcm_token': 'test_fcm_token_$ts',
        'platform': 'android',
        'is_active': true,
      }).select('id').single();
      createdPushTokenIds.add(pushResult['id'] as String);
      print('  Push token dibuat untuk owner');

      // ══════════════════════════════════════════════════════════
      // PHASE 1: TRANSACTIONS (INSERT -> UPDATE -> DELETE)
      // ══════════════════════════════════════════════════════════
      print('\n=== PHASE 1: TEST TRANSACTIONS ===');

      // 1a. INSERT transaction
      print('  1a. INSERT Transaksi');
      final txnInsert = await admin.from('transactions').insert({
        'business_id': businessId,
        'category_id': categoryId,
        'user_id': staffId,
        'type': 'income',
        'amount': 150000,
        'cogs': 50000,
        'payment_method': 'cash',
        'description': 'Test transaksi notifikasi',
        'transaction_date': DateTime.now().toIso8601String().substring(0, 10),
      }).select('id').single();
      final txnId = txnInsert['id'] as int;
      createdTransactionIds.add(txnId);

      // Verify activity log for INSERT
      final logsAfterTxnInsert = await admin
          .from('owner_activity_logs')
          .select('id, action_type, table_name, title, body')
          .eq('table_name', 'transactions')
          .eq('action_type', 'INSERT')
          .order('created_at', ascending: false)
          .limit(1);
      expect(logsAfterTxnInsert.isNotEmpty, true, reason: 'Log INSERT transaksi tidak ditemukan');
      final logTxnInsert = (logsAfterTxnInsert as List).first;
      createdLogIds.add(logTxnInsert['id'] as String);
      print('    Log: "${logTxnInsert['title']}"');
      expect(logTxnInsert['title'], contains('Transaksi Baru'));
      expect(logTxnInsert['body'], contains('menambahkan'));
      expect(logTxnInsert['body'], contains('Rp'));

      // 1b. UPDATE transaction
      print('  1b. UPDATE Transaksi');
      await admin.from('transactions').update({
        'amount': 200000,
        'description': 'Test update transaksi notifikasi',
      }).eq('id', txnId);

      final logsAfterTxnUpdate = await admin
          .from('owner_activity_logs')
          .select('id, action_type, table_name, title, body')
          .eq('table_name', 'transactions')
          .eq('action_type', 'UPDATE')
          .order('created_at', ascending: false)
          .limit(1);
      expect(logsAfterTxnUpdate.isNotEmpty, true, reason: 'Log UPDATE transaksi tidak ditemukan');
      final logTxnUpdate = (logsAfterTxnUpdate as List).first;
      createdLogIds.add(logTxnUpdate['id'] as String);
      print('    Log: "${logTxnUpdate['title']}"');
      expect(logTxnUpdate['title'], contains('Pembaruan Transaksi'));
      expect(logTxnUpdate['body'], contains('mengubah'));
      expect(logTxnUpdate['body'], contains('Rp'));

      // 1c. DELETE transaction
      print('  1c. DELETE Transaksi');
      await admin.from('transactions').delete().eq('id', txnId);
      createdTransactionIds.remove(txnId);

      final logsAfterTxnDelete = await admin
          .from('owner_activity_logs')
          .select('id, action_type, table_name, title, body')
          .eq('table_name', 'transactions')
          .eq('action_type', 'DELETE')
          .order('created_at', ascending: false)
          .limit(1);
      expect(logsAfterTxnDelete.isNotEmpty, true, reason: 'Log DELETE transaksi tidak ditemukan');
      final logTxnDelete = (logsAfterTxnDelete as List).first;
      createdLogIds.add(logTxnDelete['id'] as String);
      print('    Log: "${logTxnDelete['title']}"');
      expect(logTxnDelete['title'], contains('Penghapusan Transaksi'));
      expect(logTxnDelete['body'], contains('menghapus'));

      // ══════════════════════════════════════════════════════════
      // PHASE 2: DEBTS / PIUTANG (INSERT -> UPDATE -> DELETE)
      // ══════════════════════════════════════════════════════════
      print('\n=== PHASE 2: TEST DEBTS (PIUTANG) ===');

      // 2a. INSERT debt
      print('  2a. INSERT Piutang');
      final debtInsert = await admin.from('debts').insert({
        'debtor_id': debtorId,
        'business_id': businessId,
        'user_id': staffId,
        'amount': 500000,
        'paid_amount': 0,
        'description': 'Test piutang notifikasi',
        'status': 'unpaid',
      }).select('id').single();
      final debtId = debtInsert['id'] as int;
      createdDebtIds.add(debtId);

      final logsAfterDebtInsert = await admin
          .from('owner_activity_logs')
          .select('id, action_type, table_name, title, body')
          .eq('table_name', 'debts')
          .eq('action_type', 'INSERT')
          .order('created_at', ascending: false)
          .limit(1);
      expect(logsAfterDebtInsert.isNotEmpty, true, reason: 'Log INSERT piutang tidak ditemukan');
      final logDebtInsert = (logsAfterDebtInsert as List).first;
      createdLogIds.add(logDebtInsert['id'] as String);
      print('    Log: "${logDebtInsert['title']}"');
      expect(logDebtInsert['title'], contains('Piutang Baru'));
      expect(logDebtInsert['body'], contains('mencatat piutang baru'));
      expect(logDebtInsert['body'], contains('Test Debtor'));
      expect(logDebtInsert['body'], contains('Rp'));

      // 2b. UPDATE debt
      print('  2b. UPDATE Piutang');
      await admin.from('debts').update({
        'amount': 750000,
        'status': 'partial',
        'paid_amount': 250000,
      }).eq('id', debtId);

      final logsAfterDebtUpdate = await admin
          .from('owner_activity_logs')
          .select('id, action_type, table_name, title, body')
          .eq('table_name', 'debts')
          .eq('action_type', 'UPDATE')
          .order('created_at', ascending: false)
          .limit(1);
      expect(logsAfterDebtUpdate.isNotEmpty, true, reason: 'Log UPDATE piutang tidak ditemukan');
      final logDebtUpdate = (logsAfterDebtUpdate as List).first;
      createdLogIds.add(logDebtUpdate['id'] as String);
      print('    Log: "${logDebtUpdate['title']}"');
      expect(logDebtUpdate['title'], contains('Pembaruan Piutang'));
      expect(logDebtUpdate['body'], contains('mengubah catatan piutang'));
      expect(logDebtUpdate['body'], contains('Rp'));

      // 2c. DELETE debt
      print('  2c. DELETE Piutang');
      await admin.from('debts').delete().eq('id', debtId);
      createdDebtIds.remove(debtId);

      final logsAfterDebtDelete = await admin
          .from('owner_activity_logs')
          .select('id, action_type, table_name, title, body')
          .eq('table_name', 'debts')
          .eq('action_type', 'DELETE')
          .order('created_at', ascending: false)
          .limit(1);
      expect(logsAfterDebtDelete.isNotEmpty, true, reason: 'Log DELETE piutang tidak ditemukan');
      final logDebtDelete = (logsAfterDebtDelete as List).first;
      createdLogIds.add(logDebtDelete['id'] as String);
      print('    Log: "${logDebtDelete['title']}"');
      expect(logDebtDelete['title'], contains('Penghapusan Piutang'));
      expect(logDebtDelete['body'], contains('menghapus'));

      // ══════════════════════════════════════════════════════════
      // PHASE 3: CONSIGNMENTS / TITIPAN (INSERT -> UPDATE -> DELETE)
      // ══════════════════════════════════════════════════════════
      print('\n=== PHASE 3: TEST CONSIGNMENTS (TITIPAN) ===');

      // 3a. INSERT consignment
      print('  3a. INSERT Titipan');
      final consInsert = await admin.from('consignments').insert({
        'consignor_id': consignorId,
        'business_id': businessId,
        'user_id': staffId,
        'total_amount': 300000,
        'description': 'Test titipan notifikasi',
        'status': 'active',
        'type': 'reseller',
      }).select('id').single();
      final consId = consInsert['id'] as int;
      createdConsignmentIds.add(consId);

      final logsAfterConsInsert = await admin
          .from('owner_activity_logs')
          .select('id, action_type, table_name, title, body')
          .eq('table_name', 'consignments')
          .eq('action_type', 'INSERT')
          .order('created_at', ascending: false)
          .limit(1);
      expect(logsAfterConsInsert.isNotEmpty, true, reason: 'Log INSERT titipan tidak ditemukan');
      final logConsInsert = (logsAfterConsInsert as List).first;
      createdLogIds.add(logConsInsert['id'] as String);
      print('    Log: "${logConsInsert['title']}"');
      expect(logConsInsert['title'], contains('Titipan Baru'));
      expect(logConsInsert['body'], contains('mencatat titipan baru'));
      expect(logConsInsert['body'], contains('Test Consignor'));
      expect(logConsInsert['body'], contains('Rp'));

      // 3b. UPDATE consignment
      print('  3b. UPDATE Titipan');
      await admin.from('consignments').update({
        'total_amount': 450000,
        'description': 'Test update titipan notifikasi',
      }).eq('id', consId);

      final logsAfterConsUpdate = await admin
          .from('owner_activity_logs')
          .select('id, action_type, table_name, title, body')
          .eq('table_name', 'consignments')
          .eq('action_type', 'UPDATE')
          .order('created_at', ascending: false)
          .limit(1);
      expect(logsAfterConsUpdate.isNotEmpty, true, reason: 'Log UPDATE titipan tidak ditemukan');
      final logConsUpdate = (logsAfterConsUpdate as List).first;
      createdLogIds.add(logConsUpdate['id'] as String);
      print('    Log: "${logConsUpdate['title']}"');
      expect(logConsUpdate['title'], contains('Pembaruan Titipan'));
      expect(logConsUpdate['body'], contains('mengubah catatan titipan'));
      expect(logConsUpdate['body'], contains('Rp'));

      // 3c. DELETE consignment
      print('  3c. DELETE Titipan');
      await admin.from('consignments').delete().eq('id', consId);
      createdConsignmentIds.remove(consId);

      final logsAfterConsDelete = await admin
          .from('owner_activity_logs')
          .select('id, action_type, table_name, title, body')
          .eq('table_name', 'consignments')
          .eq('action_type', 'DELETE')
          .order('created_at', ascending: false)
          .limit(1);
      expect(logsAfterConsDelete.isNotEmpty, true, reason: 'Log DELETE titipan tidak ditemukan');
      final logConsDelete = (logsAfterConsDelete as List).first;
      createdLogIds.add(logConsDelete['id'] as String);
      print('    Log: "${logConsDelete['title']}"');
      expect(logConsDelete['title'], contains('Penghapusan Titipan'));
      expect(logConsDelete['body'], contains('menghapus'));

      // ══════════════════════════════════════════════════════════
      // PHASE 4: VERIFIKASI DETAILS (JSONB field)
      // ══════════════════════════════════════════════════════════
      print('\n=== PHASE 4: VERIFIKASI DETAILS ===');

      final allLogs = await admin
          .from('owner_activity_logs')
          .select('id, action_type, table_name, details')
          .eq('business_id', businessId)
          .order('created_at', ascending: false);

      final logList = allLogs as List;
      print('  Total logs untuk business ini: ${logList.length}');
      expect(logList.length, greaterThanOrEqualTo(6),
          reason: 'Minimal 6 log (3 tables x 3 ops, minus DELETE yang sudah tidak ada relasi)');

      // Verify details JSONB contains row data for INSERT logs
      final insertLogs = logList.where((l) => l['action_type'] == 'INSERT').toList();
      for (final log in insertLogs) {
        final details = log['details'];
        expect(details, isNotNull, reason: 'details tidak boleh null untuk INSERT log');
        expect(details, isA<Map>(), reason: 'details harus berupa JSON object');
        print('  Log ${log['table_name']} INSERT details keys: ${details.keys.toList()}');
      }

      // ══════════════════════════════════════════════════════════
      // PHASE 5: SUMMARY
      // ══════════════════════════════════════════════════════════
      print('\n=== SEMUA TEST NOTIFIKASI OWNER LULUS ===');
      print('  Transaksi: INSERT OK | UPDATE OK | DELETE OK');
      print('  Piutang:   INSERT OK | UPDATE OK | DELETE OK');
      print('  Titipan:   INSERT OK | UPDATE OK | DELETE OK');
      print('  Details JSONB verified OK');
    } finally {
      // ══════════════════════════════════════════════════════════
      // CLEANUP: Kembalikan ke kondisi semula
      // ══════════════════════════════════════════════════════════
      print('\n=== CLEANUP: MENGHAPUS SEMUA DATA TEST ===');

      // Delete activity logs created during test
      if (createdLogIds.isNotEmpty) {
        await admin.from('owner_activity_logs').delete().inFilter('id', createdLogIds);
        print('  ${createdLogIds.length} activity logs dihapus');
      }

      // Delete remaining test records (dependents first)
      for (final txnId in createdTransactionIds) {
        await admin.from('transactions').delete().eq('id', txnId);
      }
      for (final debtId in createdDebtIds) {
        await admin.from('debt_payments').delete().eq('debt_id', debtId);
        await admin.from('debts').delete().eq('id', debtId);
      }
      for (final consId in createdConsignmentIds) {
        await admin.from('consignment_items').delete().eq('consignment_id', consId);
        await admin.from('consignment_settlements').delete().eq('consignment_id', consId);
        await admin.from('consignments').delete().eq('id', consId);
      }

      // Delete push tokens
      for (final tokenId in createdPushTokenIds) {
        await admin.from('push_tokens').delete().eq('id', tokenId);
      }

      // Delete parent records
      if (debtorId != null) {
        await admin.from('debtors').delete().eq('id', debtorId);
        print('  Debtor $debtorId dihapus');
      }
      if (consignorId != null) {
        await admin.from('consignors').delete().eq('id', consignorId);
        print('  Consignor $consignorId dihapus');
      }
      if (categoryId != null) {
        await admin.from('categories').delete().eq('id', categoryId);
        print('  Category $categoryId dihapus');
      }

      // Delete business
      if (businessId != null) {
        await admin.from('businesses').delete().eq('id', businessId);
        print('  Business $businessId dihapus');
      }

      // Delete test users
      for (final userId in createdUserIds) {
        await admin.from('users').delete().eq('id', userId);
      }
      print('  ${createdUserIds.length} test users dihapus');

      print('  CLEANUP SELESAI');
    }
  });
}
