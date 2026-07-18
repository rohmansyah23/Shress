// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Test JWT RPC flow', () async {
    // Read .env file
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

    print('Menghubungkan ke Supabase...');
    final client = SupabaseClient(url!, anonKey!);
    final adminClient = SupabaseClient(url, serviceRoleKey!);

    final tempEmail = 'test_jwt_temp_${DateTime.now().millisecondsSinceEpoch}@ssrs.com';
    final tempUsername = 'test_jwt_temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempPassword = 'testpassword123';
    String? tempUserId;

    try {
      // 0. Pembuatan User Sementara
      print('\n=== 0. MEMBUAT USER SEMENTARA ===');
      final createResult = await client.rpc('create_public_user', params: {
        'p_email': tempEmail,
        'p_username': tempUsername,
        'p_role': 'owner',
        'p_password': tempPassword,
      });
      
      expect(createResult, isNotNull, reason: 'Gagal membuat user sementara');
      tempUserId = createResult as String;
      print('✓ User sementara berhasil dibuat! ID: $tempUserId');

      // 1. Test Login to get signed JWT (Skenario 1)
      print('\n=== 1. SIMULASI LOGIN (verify_public_password) ===');
      final loginResult = await client.rpc('verify_public_password', params: {
        'p_identifier': tempEmail,
        'p_password': tempPassword,
      });

      expect(loginResult, isNotNull, reason: 'Login gagal: Kredensial tidak valid');

      final data = loginResult as Map;
      final userId = data['user_id'] as String;
      final token = data['token'] as String;

      print('✓ Login Sukses!');
      print('User ID: $userId');
      print('Signed JWT Token: \n$token');

      // 2. Test Verification of valid token
      print('\n=== 2. VERIFIKASI TOKEN VALID (verify_user_jwt) ===');
      final verifyResult = await client.rpc('verify_user_jwt', params: {
        'p_token': token,
      });
      print('✓ Hasil Verifikasi (Token Valid): $verifyResult');
      expect((verifyResult as Map)['valid'], true);

      // 3. Test Verification of tampered token (Skenario 2)
      print('\n=== 3. VERIFIKASI TOKEN YANG DIRUSAK (Tampered Signature) ===');
      final tamperedToken = token + 'a'; // Menambahkan karakter untuk merusak signature
      final verifyTamperedResult = await client.rpc('verify_user_jwt', params: {
        'p_token': tamperedToken,
      });
      print('✓ Hasil Verifikasi (Token Rusak): $verifyTamperedResult');
      expect((verifyTamperedResult as Map)['valid'], false);
      expect(verifyTamperedResult['error'], 'Tanda tangan token tidak cocok');

      // 4. Test Verification after session version increment (Skenario 3)
      print('\n=== 4. SIMULASI FORCE LOGOUT (Menyegarkan session_version) ===');
      // Naikkan session_version menggunakan admin client (service_role) bypass RLS
      await adminClient.from('users').update({
        'session_version': 2,
      }).eq('id', tempUserId);
      print('✓ session_version di database di-update ke 2');

      final verifyExpiredResult = await client.rpc('verify_user_jwt', params: {
        'p_token': token, // Kirim token lama (yang masih memiliki sv: 1)
      });
      print('✓ Hasil Verifikasi (Token Kedaluwarsa/Batal): $verifyExpiredResult');
      expect((verifyExpiredResult as Map)['valid'], false);
      expect(verifyExpiredResult['error'], 'Sesi kedaluwarsa atau user nonaktif');

    } finally {
      // 5. Clean up: Delete the temporary user
      if (tempUserId != null) {
        print('\n=== 5. CLEANUP DATABASE ===');
        await adminClient.from('users').delete().eq('id', tempUserId);
        print('✓ User sementara $tempUserId berhasil dihapus dari database.');
      }
    }
  });
}
