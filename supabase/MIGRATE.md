# Migrasi Database ke Supabase

## Prasyarat

1. **Buat Project di Supabase** (https://supabase.com)
2. **Dapatkan credentials** dari dashboard Supabase:
   - `Project Settings > API > Project URL` → `SUPABASE_URL`
   - `Project Settings > API > anon/public key` → `SUPABASE_ANON_KEY`

## Langkah Migrasi

### Opsi 1: Via Supabase Dashboard (Mudah)

1. Login ke [Supabase Dashboard](https://supabase.com/dashboard)
2. Pilih project Anda
3. Buka **SQL Editor** (sidebar kiri)
4. **Copy paste** isi file `supabase/migrations/20260718000000_initial_schema.sql` ke editor
5. Klik **Run** (atau **Cmd+Enter**)
6. Tunggu hingga semua query selesai (tidak ada error merah)

### Opsi 2: Via Supabase CLI (Advanced)

```bash
# Install Supabase CLI
# https://supabase.com/docs/guides/cli

# Login ke Supabase
supabase login

# Link project
supabase link --project-ref your-project-ref

# Jalankan migrasi
supabase db push
```

## Konfigurasi `.env`

Setelah migrasi selesai, **update file `.env`** di root project:

```env
# Ganti dengan URL project Supabase Anda
SUPABASE_URL=https://your-project-id.supabase.co

# Ganti dengan Anon Key dari Supabase
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## Verifikasi

Setelah migrasi berhasil, pastikan tabel-tabel berikut muncul di Supabase Table Editor:

| Tabel | Deskripsi |
|---|---|
| `users` | User profiles (sync otomatis dari Auth) |
| `businesses` | Daftar bisnis (Agen Minuman Alkali, Teh Solo, Warung Kopi) |
| `user_businesses` | Bridge akses user ke bisnis |
| `categories` | Kategori income/expense per bisnis |
| `transactions` | Transaksi keuangan |
| `debtors` | Daftar penghutang (Piutang) |
| `debts` | Detail hutang per penghutang |
| `debt_payments` | Riwayat pembayaran cicilan hutang |
| `consignors` | Daftar penitip barang (Konsinyasi) |
| `consignments` | Batch penitipan barang |
| `consignment_items` | Detail item yang dititipkan |
| `consignment_settlements` | Pembayaran ke penitip |
| `push_tokens` | Token FCM push notification per user/device |
| `owner_notifications` | Notifikasi yang dikirim oleh owner |
| `owner_activity_logs` | Audit log untuk CUD operasi pada transaksi, piutang, titipan |

## Troubleshooting

### Error: "permission denied"
- Pastikan Anda login sebagai **owner** project Supabase
- Atau jalankan query di **SQL Editor** (bukan dari aplikasi)

### Error: "relation already exists"
- Aman, artinya tabel sudah ada. Migration menggunakan `IF NOT EXISTS`.

### Error: "cannot use auth.uid()"
- Query dengan `auth.uid()` hanya bisa dijalankan via SQL Editor (bukan koneksi langsung).
- Jika menggunakan koneksi langsung, hapus dulu bagian RLS policies, jalankan DDL, lalu tambahkan RLS manually.

### App tidak connect ke Supabase
- Cek file `.env` — pastikan `SUPABASE_URL` dan `SUPABASE_ANON_KEY` sudah benar.
- Jalankan `flutter run` dan lihat console untuk pesan error konfigurasi.
- App akan tetap berjalan dalam **mode offline-only** jika .env tidak valid.
