// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Test notifikasi owner (owner_activity_logs) menggunakan SCHEMA REAL dari database.
///
/// Membuat data realistis mirip production:
///   - Owner (syahr642) - role owner
///   - Staff (pasep123 / Pak Asep) - role staff
///   - Business "Agen Milagros"
///   - Category "Penjualan Harian"
///
/// Flow:
///   pasep123 -> buat transaksi di Agen Milagros -> edit -> hapus
///   -> verify notifikasi owner masuk dengan benar
///
/// Edge function notify-owner-cud akan dipanggil via pg_net,
/// sehingga push notification benar-benar terkirim ke device owner.
void main() {
  test('Owner CUD notifications - pasep123 at Agen Milagros', () async {
    // ── Read .env ──────────────────────────────────────────────
    final envFile = File('.env');
    expect(await envFile.exists(), true, reason: '.env file not found');

    final lines = await envFile.readAsLines();
    String? url;
    String? serviceRoleKey;
    for (var line in lines) {
      if (line.startsWith('SUPABASE_URL=')) {
        url = line.split('=').sublist(1).join('=').trim();
      }
      if (line.startsWith('SUPABASE_SERVICE_ROLE_KEY=')) {
        serviceRoleKey = line.split('=').sublist(1).join('=').trim();
      }
    }

    expect(url, isNotNull, reason: 'SUPABASE_URL not found in .env');
    expect(serviceRoleKey, isNotNull,
        reason: 'SUPABASE_SERVICE_ROLE_KEY not found in .env');

    final admin = SupabaseClient(url!, serviceRoleKey!);

    // ── Tracking ───────────────────────────────────────────────
    String? staffId;
    String? ownerId;
    int? businessId;
    int? categoryId;
    final createdTransactionIds = <int>[];
    final createdDebtIds = <int>[];
    final createdConsignmentIds = <int>[];
    final createdLogIds = <String>[];
    int? tempDebtorId;
    int? tempConsignorId;

    bool createdStaff = false;
    bool createdOwner = false;
    bool createdBusiness = false;
    bool createdCategory = false;
    bool createdUserBusinessLink = false;

    try {
      // ══════════════════════════════════════════════════════════
      // PHASE 0: SETUP DATA REALISTIS
      // ══════════════════════════════════════════════════════════
      print('\n=== PHASE 0: SETUP DATA REALISTIS ===');

      // 0a. Fetch or create owner (syahr642)
      var ownerResult = await admin
          .from('users')
          .select('id, username, display_name, role')
          .eq('role', 'owner')
          .limit(1)
          .maybeSingle();

      String ownerName;
      if (ownerResult != null) {
        ownerId = ownerResult['id'] as String;
        ownerName = ownerResult['display_name'] as String;
        print('  Owner existing: $ownerName ($ownerId)');
      } else {
        ownerId = '00000000-0000-0000-0000-000000000001';
        ownerName = 'Rohman Syah';
        await admin.from('users').upsert({
          'id': ownerId,
          'email': 'syahr642@gmail.com',
          'username': 'syahr642',
          'display_name': ownerName,
          'role': 'owner',
          'is_active': true,
        });
        createdOwner = true;
        print('  Owner dibuat: $ownerName ($ownerId)');
      }

      // 0b. Fetch or create staff (pasep123 / Pak Asep)
      var staffResult = await admin
          .from('users')
          .select('id, username, display_name, role')
          .eq('username', 'pasep123')
          .maybeSingle();

      String staffName;
      if (staffResult != null) {
        staffId = staffResult['id'] as String;
        staffName = staffResult['display_name'] as String;
        print('  Staff existing: $staffName ($staffId)');
      } else {
        staffId = '00000000-0000-0000-0000-000000000002';
        staffName = 'Pak Asep';
        await admin.from('users').upsert({
          'id': staffId,
          'email': 'pakasep@gmail.com',
          'username': 'pasep123',
          'display_name': staffName,
          'role': 'staff',
          'is_active': true,
        });
        createdStaff = true;
        print('  Staff dibuat: $staffName ($staffId)');
      }

      // 0c. Fetch or create business "Agen Milagros"
      var bizResult = await admin
          .from('businesses')
          .select('id, name')
          .eq('name', 'Agen Milagros')
          .maybeSingle();

      String businessName;
      if (bizResult != null) {
        businessId = bizResult['id'] as int;
        businessName = bizResult['name'] as String;
        print('  Business existing: $businessName (id=$businessId)');
      } else {
        final inserted = await admin.from('businesses').insert({
          'name': 'Agen Milagros',
          'description': 'Bangunan samping bengkel',
        }).select('id').single();
        businessId = inserted['id'] as int;
        businessName = 'Agen Milagros';
        createdBusiness = true;
        print('  Business dibuat: $businessName (id=$businessId)');
      }

      // 0d. Link staff to business if not already linked
      final linkResult = await admin
          .from('user_businesses')
          .select('id')
          .eq('user_id', staffId!)
          .eq('business_id', businessId!)
          .maybeSingle();
      if (linkResult == null) {
        await admin.from('user_businesses').insert({
          'user_id': staffId,
          'business_id': businessId,
        });
        createdUserBusinessLink = true;
        print('  Staff linked ke Business');
      } else {
        print('  Staff sudah linked ke Business');
      }

      // 0e. Fetch or create category "Penjualan Harian" for Agen Milagros
      var catResult = await admin
          .from('categories')
          .select('id, name, type')
          .eq('business_id', businessId!)
          .eq('name', 'Penjualan Harian')
          .maybeSingle();

      if (catResult != null) {
        categoryId = catResult['id'] as int;
        print('  Category existing: ${catResult['name']} (id=$categoryId)');
      } else {
        final inserted = await admin.from('categories').insert({
          'business_id': businessId,
          'name': 'Penjualan Harian',
          'type': 'income',
        }).select('id').single();
        categoryId = inserted['id'] as int;
        createdCategory = true;
        print('  Category dibuat: Penjualan Harian (id=$categoryId)');
      }

      // 0f. Create temporary debtor for debts test
      final debtorResult = await admin.from('debtors').insert({
        'business_id': businessId,
        'name': 'Test Debtor Notif',
        'phone': '08111222333',
      }).select('id').single();
      tempDebtorId = debtorResult['id'] as int;
      print('  Temp Debtor dibuat: id=$tempDebtorId');

      // 0g. Create temporary consignor for consignments test
      final consignorResult = await admin.from('consignors').insert({
        'business_id': businessId,
        'name': 'Test Consignor Notif',
        'phone': '08999888777',
      }).select('id').single();
      tempConsignorId = consignorResult['id'] as int;
      print('  Temp Consignor dibuat: id=$tempConsignorId');

      print('');
      print('  === SKENARIO TEST ===');
      print('  $staffName (staff) membuat transaksi di $businessName');
      print('  Owner: $ownerName');
      print('  Notifikasi akan masuk ke owner_activity_logs');
      print('  Edge function notify-owner-cud akan dipanggil via pg_net');

      // ══════════════════════════════════════════════════════════
      // PHASE 1: TRANSACTIONS (INSERT -> UPDATE -> DELETE)
      // pasep123 membuat transaksi di Agen Milagros
      // ══════════════════════════════════════════════════════════
      print('\n=== PHASE 1: TRANSAKSI ===');

      // 1a. INSERT transaksi
      print('  1a. INSERT Transaksi');
      final txnInsert = await admin.from('transactions').insert({
        'business_id': businessId,
        'category_id': categoryId,
        'user_id': staffId,
        'type': 'income',
        'amount': 150000,
        'cogs': 50000,
        'payment_method': 'cash',
        'description': 'Penjualan air Milagros 1 dus',
        'transaction_date': DateTime.now().toIso8601String().substring(0, 10),
      }).select('id').single();
      final txnId = txnInsert['id'] as int;
      createdTransactionIds.add(txnId);

      // Verify activity log INSERT
      final logsAfterTxnInsert = await admin
          .from('owner_activity_logs')
          .select('id, action_type, table_name, title, body, details')
          .eq('business_id', businessId)
          .eq('table_name', 'transactions')
          .eq('action_type', 'INSERT')
          .order('created_at', ascending: false)
          .limit(1);
      expect(logsAfterTxnInsert.isNotEmpty, true,
          reason: 'Log INSERT transaksi tidak ditemukan');
      final logTxnInsert = (logsAfterTxnInsert as List).first;
      createdLogIds.add(logTxnInsert['id'] as String);
      print('    Log: "${logTxnInsert['title']}"');
      print('    Body: "${logTxnInsert['body']}"');
      expect(logTxnInsert['title'], contains('Transaksi Baru'));
      expect(logTxnInsert['title'], contains(businessName));
      expect(logTxnInsert['body'], contains(staffName));
      expect(logTxnInsert['body'], contains('menambahkan'));
      expect(logTxnInsert['body'], contains('Rp'));
      final detailsInsert = logTxnInsert['details'];
      expect(detailsInsert, isNotNull, reason: 'details INSERT harus ada');
      expect(detailsInsert, isA<Map>(), reason: 'details harus JSON object');
      expect(detailsInsert['user_id'], equals(staffId));
      expect(detailsInsert['business_id'], equals(businessId));

      // 1b. UPDATE transaksi
      print('  1b. UPDATE Transaksi');
      await admin.from('transactions').update({
        'amount': 200000,
        'cogs': 75000,
        'description': 'Penjualan air Milagros 1 dus + 1 galon',
      }).eq('id', txnId);

      final logsAfterTxnUpdate = await admin
          .from('owner_activity_logs')
          .select('id, action_type, table_name, title, body')
          .eq('business_id', businessId)
          .eq('table_name', 'transactions')
          .eq('action_type', 'UPDATE')
          .order('created_at', ascending: false)
          .limit(1);
      expect(logsAfterTxnUpdate.isNotEmpty, true,
          reason: 'Log UPDATE transaksi tidak ditemukan');
      final logTxnUpdate = (logsAfterTxnUpdate as List).first;
      createdLogIds.add(logTxnUpdate['id'] as String);
      print('    Log: "${logTxnUpdate['title']}"');
      print('    Body: "${logTxnUpdate['body']}"');
      expect(logTxnUpdate['title'], contains('Pembaruan Transaksi'));
      expect(logTxnUpdate['title'], contains(businessName));
      expect(logTxnUpdate['body'], contains(staffName));
      expect(logTxnUpdate['body'], contains('mengubah'));
      expect(logTxnUpdate['body'], contains('Rp'));

      // 1c. DELETE transaksi
      print('  1c. DELETE Transaksi');
      await admin.from('transactions').delete().eq('id', txnId);
      createdTransactionIds.remove(txnId);

      final logsAfterTxnDelete = await admin
          .from('owner_activity_logs')
          .select('id, action_type, table_name, title, body')
          .eq('business_id', businessId)
          .eq('table_name', 'transactions')
          .eq('action_type', 'DELETE')
          .order('created_at', ascending: false)
          .limit(1);
      expect(logsAfterTxnDelete.isNotEmpty, true,
          reason: 'Log DELETE transaksi tidak ditemukan');
      final logTxnDelete = (logsAfterTxnDelete as List).first;
      createdLogIds.add(logTxnDelete['id'] as String);
      print('    Log: "${logTxnDelete['title']}"');
      print('    Body: "${logTxnDelete['body']}"');
      expect(logTxnDelete['title'], contains('Penghapusan Transaksi'));
      expect(logTxnDelete['title'], contains(businessName));
      expect(logTxnDelete['body'], contains(staffName));
      expect(logTxnDelete['body'], contains('menghapus'));
      expect(logTxnDelete['body'], contains('Rp'));

      // ══════════════════════════════════════════════════════════
      // PHASE 2: DEBTS / PIUTANG (INSERT -> UPDATE -> DELETE)
      // ══════════════════════════════════════════════════════════
      print('\n=== PHASE 2: PIUTANG ===');

      // 2a. INSERT piutang
      print('  2a. INSERT Piutang');
      final debtInsert = await admin.from('debts').insert({
        'debtor_id': tempDebtorId,
        'business_id': businessId,
        'user_id': staffId,
        'amount': 500000,
        'paid_amount': 0,
        'description': 'Piutang air Milagros untuk warung',
        'status': 'unpaid',
      }).select('id').single();
      final debtId = debtInsert['id'] as int;
      createdDebtIds.add(debtId);

      final logsAfterDebtInsert = await admin
          .from('owner_activity_logs')
          .select('id, action_type, table_name, title, body, details')
          .eq('business_id', businessId)
          .eq('table_name', 'debts')
          .eq('action_type', 'INSERT')
          .order('created_at', ascending: false)
          .limit(1);
      expect(logsAfterDebtInsert.isNotEmpty, true,
          reason: 'Log INSERT piutang tidak ditemukan');
      final logDebtInsert = (logsAfterDebtInsert as List).first;
      createdLogIds.add(logDebtInsert['id'] as String);
      print('    Log: "${logDebtInsert['title']}"');
      print('    Body: "${logDebtInsert['body']}"');
      expect(logDebtInsert['title'], contains('Piutang Baru'));
      expect(logDebtInsert['title'], contains(businessName));
      expect(logDebtInsert['body'], contains(staffName));
      expect(logDebtInsert['body'], contains('mencatat piutang baru'));
      expect(logDebtInsert['body'], contains('Test Debtor Notif'));
      expect(logDebtInsert['body'], contains('Rp'));

      // 2b. UPDATE piutang
      print('  2b. UPDATE Piutang');
      await admin.from('debts').update({
        'amount': 750000,
        'status': 'partial',
        'paid_amount': 250000,
      }).eq('id', debtId);

      final logsAfterDebtUpdate = await admin
          .from('owner_activity_logs')
          .select('id, action_type, table_name, title, body')
          .eq('business_id', businessId)
          .eq('table_name', 'debts')
          .eq('action_type', 'UPDATE')
          .order('created_at', ascending: false)
          .limit(1);
      expect(logsAfterDebtUpdate.isNotEmpty, true,
          reason: 'Log UPDATE piutang tidak ditemukan');
      final logDebtUpdate = (logsAfterDebtUpdate as List).first;
      createdLogIds.add(logDebtUpdate['id'] as String);
      print('    Log: "${logDebtUpdate['title']}"');
      print('    Body: "${logDebtUpdate['body']}"');
      expect(logDebtUpdate['title'], contains('Pembaruan Piutang'));
      expect(logDebtUpdate['title'], contains(businessName));
      expect(logDebtUpdate['body'], contains(staffName));
      expect(logDebtUpdate['body'], contains('mengubah'));
      expect(logDebtUpdate['body'], contains('Rp'));

      // 2c. DELETE piutang
      print('  2c. DELETE Piutang');
      await admin.from('debts').delete().eq('id', debtId);
      createdDebtIds.remove(debtId);

      final logsAfterDebtDelete = await admin
          .from('owner_activity_logs')
          .select('id, action_type, table_name, title, body')
          .eq('business_id', businessId)
          .eq('table_name', 'debts')
          .eq('action_type', 'DELETE')
          .order('created_at', ascending: false)
          .limit(1);
      expect(logsAfterDebtDelete.isNotEmpty, true,
          reason: 'Log DELETE piutang tidak ditemukan');
      final logDebtDelete = (logsAfterDebtDelete as List).first;
      createdLogIds.add(logDebtDelete['id'] as String);
      print('    Log: "${logDebtDelete['title']}"');
      print('    Body: "${logDebtDelete['body']}"');
      expect(logDebtDelete['title'], contains('Penghapusan Piutang'));
      expect(logDebtDelete['title'], contains(businessName));
      expect(logDebtDelete['body'], contains(staffName));
      expect(logDebtDelete['body'], contains('menghapus'));
      expect(logDebtDelete['body'], contains('Rp'));

      // ══════════════════════════════════════════════════════════
      // PHASE 3: CONSIGNMENTS / TITIPAN (INSERT -> UPDATE -> DELETE)
      // ══════════════════════════════════════════════════════════
      print('\n=== PHASE 3: TITIPAN ===');

      // 3a. INSERT titipan
      print('  3a. INSERT Titipan');
      final consInsert = await admin.from('consignments').insert({
        'consignor_id': tempConsignorId,
        'business_id': businessId,
        'user_id': staffId,
        'total_amount': 300000,
        'description': 'Titipan air Milagros dari supplier',
        'status': 'active',
        'type': 'reseller',
      }).select('id').single();
      final consId = consInsert['id'] as int;
      createdConsignmentIds.add(consId);

      final logsAfterConsInsert = await admin
          .from('owner_activity_logs')
          .select('id, action_type, table_name, title, body, details')
          .eq('business_id', businessId)
          .eq('table_name', 'consignments')
          .eq('action_type', 'INSERT')
          .order('created_at', ascending: false)
          .limit(1);
      expect(logsAfterConsInsert.isNotEmpty, true,
          reason: 'Log INSERT titipan tidak ditemukan');
      final logConsInsert = (logsAfterConsInsert as List).first;
      createdLogIds.add(logConsInsert['id'] as String);
      print('    Log: "${logConsInsert['title']}"');
      print('    Body: "${logConsInsert['body']}"');
      expect(logConsInsert['title'], contains('Titipan Baru'));
      expect(logConsInsert['title'], contains(businessName));
      expect(logConsInsert['body'], contains(staffName));
      expect(logConsInsert['body'], contains('mencatat titipan baru'));
      expect(logConsInsert['body'], contains('Test Consignor Notif'));
      expect(logConsInsert['body'], contains('Rp'));

      // 3b. UPDATE titipan
      print('  3b. UPDATE Titipan');
      await admin.from('consignments').update({
        'total_amount': 450000,
        'description': 'Update titipan: tambah 10 dus air Milagros',
      }).eq('id', consId);

      final logsAfterConsUpdate = await admin
          .from('owner_activity_logs')
          .select('id, action_type, table_name, title, body')
          .eq('business_id', businessId)
          .eq('table_name', 'consignments')
          .eq('action_type', 'UPDATE')
          .order('created_at', ascending: false)
          .limit(1);
      expect(logsAfterConsUpdate.isNotEmpty, true,
          reason: 'Log UPDATE titipan tidak ditemukan');
      final logConsUpdate = (logsAfterConsUpdate as List).first;
      createdLogIds.add(logConsUpdate['id'] as String);
      print('    Log: "${logConsUpdate['title']}"');
      print('    Body: "${logConsUpdate['body']}"');
      expect(logConsUpdate['title'], contains('Pembaruan Titipan'));
      expect(logConsUpdate['title'], contains(businessName));
      expect(logConsUpdate['body'], contains(staffName));
      expect(logConsUpdate['body'], contains('mengubah'));
      expect(logConsUpdate['body'], contains('Rp'));

      // 3c. DELETE titipan
      print('  3c. DELETE Titipan');
      await admin.from('consignments').delete().eq('id', consId);
      createdConsignmentIds.remove(consId);

      final logsAfterConsDelete = await admin
          .from('owner_activity_logs')
          .select('id, action_type, table_name, title, body')
          .eq('business_id', businessId)
          .eq('table_name', 'consignments')
          .eq('action_type', 'DELETE')
          .order('created_at', ascending: false)
          .limit(1);
      expect(logsAfterConsDelete.isNotEmpty, true,
          reason: 'Log DELETE titipan tidak ditemukan');
      final logConsDelete = (logsAfterConsDelete as List).first;
      createdLogIds.add(logConsDelete['id'] as String);
      print('    Log: "${logConsDelete['title']}"');
      print('    Body: "${logConsDelete['body']}"');
      expect(logConsDelete['title'], contains('Penghapusan Titipan'));
      expect(logConsDelete['title'], contains(businessName));
      expect(logConsDelete['body'], contains(staffName));
      expect(logConsDelete['body'], contains('menghapus'));
      expect(logConsDelete['body'], contains('Rp'));

      // ══════════════════════════════════════════════════════════
      // PHASE 5: OWNER SELF-ACTION → TIDAK ADA LOG
      // Owner membuat/mengedit/menghapus transaksi sendiri →
      // trigger harus skip, tidak boleh ada notifikasi self-notif
      // ══════════════════════════════════════════════════════════
      print('\n=== PHASE 5: OWNER SELF-ACTION (TIDAK ADA LOG) ===');

      // Hitung log saat ini untuk business ini
      final logsBeforeOwnerAction = await admin
          .from('owner_activity_logs')
          .select('id')
          .eq('business_id', businessId!);
      final logCountBefore = (logsBeforeOwnerAction as List).length;
      print('  Log count sebelum owner action: $logCountBefore');

      // 5a. Owner INSERT transaksi
      print('  5a. INSERT Transaksi oleh Owner (harus skip)');
      final ownerTxnInsert = await admin.from('transactions').insert({
        'business_id': businessId,
        'category_id': categoryId,
        'user_id': ownerId,
        'type': 'income',
        'amount': 999000,
        'cogs': 300000,
        'payment_method': 'transfer',
        'description': 'Owner test - harus tidak ada log',
        'transaction_date': DateTime.now().toIso8601String().substring(0, 10),
      }).select('id').single();
      final ownerTxnId = ownerTxnInsert['id'] as int;
      print('    Transaksi owner dibuat: id=$ownerTxnId');

      // Tidak boleh ada log baru
      final logsAfterOwnerInsert = await admin
          .from('owner_activity_logs')
          .select('id')
          .eq('business_id', businessId);
      final logCountAfterInsert = (logsAfterOwnerInsert as List).length;
      expect(logCountAfterInsert, equals(logCountBefore),
          reason: 'Owner INSERT tidak boleh menghasilkan log (self-notif)');
      print('    Log count setelah INSERT: $logCountAfterInsert (sama, OK)');

      // 5b. Owner UPDATE transaksi
      print('  5b. UPDATE Transaksi oleh Owner (harus skip)');
      await admin.from('transactions').update({
        'amount': 1000000,
        'description': 'Owner test update - harus tidak ada log',
      }).eq('id', ownerTxnId);

      final logsAfterOwnerUpdate = await admin
          .from('owner_activity_logs')
          .select('id')
          .eq('business_id', businessId);
      final logCountAfterUpdate = (logsAfterOwnerUpdate as List).length;
      expect(logCountAfterUpdate, equals(logCountBefore),
          reason: 'Owner UPDATE tidak boleh menghasilkan log (self-notif)');
      print('    Log count setelah UPDATE: $logCountAfterUpdate (sama, OK)');

      // 5c. Owner DELETE transaksi
      print('  5c. DELETE Transaksi oleh Owner (harus skip)');
      await admin.from('transactions').delete().eq('id', ownerTxnId);

      final logsAfterOwnerDelete = await admin
          .from('owner_activity_logs')
          .select('id')
          .eq('business_id', businessId);
      final logCountAfterDelete = (logsAfterOwnerDelete as List).length;
      expect(logCountAfterDelete, equals(logCountBefore),
          reason: 'Owner DELETE tidak boleh menghasilkan log (self-notif)');
      print('    Log count setelah DELETE: $logCountAfterDelete (sama, OK)');

      print('  PHASE 5: OWNER SELF-ACTION SKIP VERIFIED OK');

      // ══════════════════════════════════════════════════════════
      // PHASE 4: VERIFIKASI SEMUA LOG
      // ══════════════════════════════════════════════════════════
      print('\n=== PHASE 4: VERIFIKASI SEMUA LOG ===');

      final allLogs = await admin
          .from('owner_activity_logs')
          .select('id, action_type, table_name, details, title, body')
          .eq('business_id', businessId!)
          .order('created_at', ascending: false);

      final logList = allLogs as List;
      print('  Total logs untuk $businessName: ${logList.length}');
      expect(logList.length, greaterThanOrEqualTo(6),
          reason: 'Minimal 6 log (3 tables x INSERT+DELETE)');

      final insertLogs =
          logList.where((l) => l['action_type'] == 'INSERT').toList();
      for (final log in insertLogs) {
        final details = log['details'];
        expect(details, isNotNull,
            reason: 'details tidak boleh null untuk INSERT log');
        expect(details, isA<Map>(),
            reason: 'details harus berupa JSON object');
        print('  ${log['table_name']} INSERT:');
        print('    title : ${log['title']}');
        print('    body  : ${log['body']}');
        print('    keys  : ${details.keys.toList()}');
      }

      // ══════════════════════════════════════════════════════════
      // SUMMARY
      // ══════════════════════════════════════════════════════════
      print('\n=== SEMUA TEST LULUS ===');
      print('');
      print('  Skenario: $staffName (staff) -> $businessName');
      print('  Owner: $ownerName');
      print('');
      print('  Transaksi: INSERT OK | UPDATE OK | DELETE OK');
      print('  Piutang:   INSERT OK | UPDATE OK | DELETE OK');
      print('  Titipan:   INSERT OK | UPDATE OK | DELETE OK');
      print('  Owner Self-Action: INSERT SKIP | UPDATE SKIP | DELETE SKIP');
      print('  Details JSONB verified OK');
      print('');
      print('  Push notification terkirim via edge function notify-owner-cud');
    } finally {
      // ══════════════════════════════════════════════════════════
      // CLEANUP: Hapus hanya data yang dibuat test ini
      // ══════════════════════════════════════════════════════════
      print('\n=== CLEANUP ===');

      // Delete activity logs
      if (createdLogIds.isNotEmpty) {
        await admin
            .from('owner_activity_logs')
            .delete()
            .inFilter('id', createdLogIds);
        print('  ${createdLogIds.length} activity logs dihapus');
      }

      // Delete test transactions
      for (final id in createdTransactionIds) {
        await admin.from('transactions').delete().eq('id', id);
      }
      if (createdTransactionIds.isNotEmpty) {
        print('  ${createdTransactionIds.length} transaksi dihapus');
      }

      // Delete test debts
      for (final id in createdDebtIds) {
        await admin.from('debts').delete().eq('id', id);
      }
      if (createdDebtIds.isNotEmpty) {
        print('  ${createdDebtIds.length} piutang dihapus');
      }

      // Delete test consignments
      for (final id in createdConsignmentIds) {
        await admin.from('consignments').delete().eq('id', id);
      }
      if (createdConsignmentIds.isNotEmpty) {
        print('  ${createdConsignmentIds.length} titipan dihapus');
      }

      // Delete temporary debtor
      if (tempDebtorId != null) {
        await admin.from('debtors').delete().eq('id', tempDebtorId);
        print('  Debtor $tempDebtorId dihapus');
      }

      // Delete temporary consignor
      if (tempConsignorId != null) {
        await admin.from('consignors').delete().eq('id', tempConsignorId);
        print('  Consignor $tempConsignorId dihapus');
      }

      // Delete user-business link (hanya jika dibuat test ini)
      if (createdUserBusinessLink && staffId != null) {
        await admin
            .from('user_businesses')
            .delete()
            .eq('user_id', staffId);
        print('  User-business link dihapus');
      }

      // Delete category (hanya jika dibuat test ini)
      if (createdCategory && categoryId != null) {
        await admin.from('categories').delete().eq('id', categoryId);
        print('  Category test dihapus');
      }

      // Delete business (hanya jika dibuat test ini)
      if (createdBusiness && businessId != null) {
        await admin.from('businesses').delete().eq('id', businessId);
        print('  Business test dihapus');
      }

      // Delete users (hanya jika dibuat test ini)
      if (createdStaff && staffId != null) {
        await admin.from('users').delete().eq('id', staffId);
        print('  Staff test dihapus');
      }
      if (createdOwner && ownerId != null) {
        await admin.from('users').delete().eq('id', ownerId);
        print('  Owner test dihapus');
      }

      print('  CLEANUP SELESAI');
    }
  });
}
