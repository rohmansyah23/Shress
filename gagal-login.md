# Analisis Gagal Login & Data Tidak Muncul — SSRS Finance

Dokumen ini mencatat **semua penyebab** kenapa user mengalami kegagalan login atau data (bisnis, kategori, transaksi) tidak muncul setelah login, beserta **perbaikan yang telah diterapkan**.

---

## 1. Login Berhasil Tapi Tidak Redirect ke Dashboard

### Gejala
- User memasukkan email & password benar
- Tombol "Masuk" menunjukkan loading lalu kembali normal
- User tetap di halaman login, tidak pindah ke dashboard
- Harus **reopen app** untuk masuk ke dashboard

### Akar Masalah 1.1 — Riverpod Timing Issue
| Aspek | Detail |
|---|---|
| **Lokasi** | `lib/ui/auth/login_screen.dart` — method `_handleLogin()` |
| **Penyebab** | Awalnya navigasi menggunakan `ref.listen(authProvider, ...)` di dalam `build()`. Ada race condition antara `setState()` dan propagasi state Riverpod. Saat `setState(() => _isLoading = false)` dipanggil, widget rebuild — dan listener auth mungkin tidak sempat fire sebelum build selesai. |
| **Perbaikan** | `AuthNotifier.login()` sekarang mengembalikan `Future<bool>` (true = sukses, false = gagal). `_handleLogin()` langsung menggunakan return value: `final success = await ref.read(authProvider.notifier).login(...)`. Jika `success == true`, navigasi dilakukan langsung tanpa perlu membaca ulang state Riverpod. |

### Akar Masalah 1.2 — Listener Auth Tidak Aktif
| Aspek | Detail |
|---|---|
| **Lokasi** | `lib/ui/splash/splash_screen.dart` — listener auth |
| **Penyebab** | Awalnya hanya `SplashScreen` yang punya listener auth untuk navigasi. Setelah splash selesai dan navigasi ke `LoginScreen`, listener tidak aktif lagi. Jadi ketika login berhasil, tidak ada yang menangkap event `authenticated` untuk navigasi. |
| **Perbaikan** | `LoginScreen` sekarang punya navigasi langsung di `_handleLogin()` tanpa perlu listener terpisah. |

---

## 2. Data (Businesses, Categories, Transaksi) Tidak Muncul

### Gejala
- Login berhasil masuk ke dashboard
- Tapi menampilkan "Tidak ada bisnis tersedia" atau "Belum ada data"
- Laporan keuangan: "coming soon"
- Riwayat transaksi: kosong

### Akar Masalah 2.1 — Data Tidak Di-sync ke Hive Setelah Login
| Aspek | Detail |
|---|---|
| **Lokasi** | `lib/data/remote/auth_repository.dart` — method `signIn()` dan `tryRestoreSession()` |
| **Penyebab** | Aplikasi menggunakan arsitektur **offline-first** — data disimpan di Hive lokal. Tapi method `signIn()` hanya menyimpan `UserModel` ke Hive, tanpa menarik `businesses`, `categories`, dan `user_businesses` dari Supabase. Method `syncInitialData()` baru ditambahkan kemudian. |
| **Perbaikan** | `syncInitialData()` sekarang dipanggil setelah login sukses di kedua path (`signIn()` standar dan RPC fallback). Method ini menarik semua data dari Supabase ke Hive. |

### Akar Masalah 2.2 — Session Restore Tidak Sync Data
| Aspek | Detail |
|---|---|
| **Lokasi** | `lib/data/remote/auth_repository.dart` — method `tryRestoreSession()` |
| **Penyebab** | Saat app di-restart, sesi dipulihkan dari cache Hive lewat `tryRestoreSession()`. Tapi method ini hanya mengembalikan `UserModel` yang sudah di-cache — tidak memanggil `syncInitialData()`. Jadi data bisnis/kategori tetap kosong. |
| **Perbaikan** | `tryRestoreSession()` sekarang memanggil `unawaited(syncInitialData())` untuk background sync. Ditambah `_retrySyncIfDataEmpty()` di `AuthNotifier` yang mengecek ulang 500ms kemudian dan melakukan retry jika data masih kosong. |

### Akar Masalah 2.3 — Sync Gagal Tanpa Retry
| Aspek | Detail |
|---|---|
| **Lokasi** | `lib/data/remote/auth_repository.dart` — method `syncInitialData()` |
| **Penyebab** | Jika koneksi tidak stabil atau Supabase sedang sibuk, query bisa gagal. Awalnya tidak ada retry mechanism — error hanya di-print lalu dilanjutkan. Data tetap kosong. |
| **Perbaikan** | `syncInitialData()` sekarang memiliki **exponential backoff retry** (max 3 attempts) dengan delay 1s, 2s, 4s. Juga mengecek apakah data benar-benar tersimpan di Hive setelah fetch sukses. Mengembalikan `bool` sebagai indikator sukses/gagal. |

### Akar Masalah 2.4 — Provider Tidak Di-invalidate Setelah Retry
| Aspek | Detail |
|---|---|
| **Lokasi** | `lib/providers/auth_provider.dart` — `AuthNotifier` |
| **Penyebab** | Setelah retry sync berhasil dan data tersimpan di Hive, Riverpod provider (`allBusinessesProvider`, `businessSummaryProvider`) tidak di-invalidate. UI tetap menampilkan data lama (kosong) meskipun Hive sudah terisi. |
| **Perbaikan** | `AuthNotifier` menerima callback `onDataSynced` yang dipanggil setelah retry sukses. Callback ini (dari Riverpod scope) meng-invalidate `dataRefreshProvider` dan `allBusinessesProvider`, memicu rebuild UI. Pull-to-refresh juga ditambahkan di semua screen sebagai fallback manual. |

---

## 3. Gagal Login — Invalid Login Credentials

### Gejala
- Menampilkan pesan "Email atau password salah"
- User yakin email & password benar

### Akar Masalah 3.1 — User Tidak Ada di `auth.users`
| Aspek | Detail |
|---|---|
| **Lokasi** | `lib/data/remote/auth_repository.dart` — method `signIn()` |
| **Penyebab** | User dimasukkan langsung ke tabel `public.users` via SQL migration, tanpa melalui Supabase Auth API. Akibatnya, user ada di `public.users` tapi **tidak ada** di `auth.users` — sehingga `signInWithPassword()` gagal dengan "Invalid login credentials". |
| **Perbaikan** | Ditambahkan **fallback RPC** (`verify_public_password`): jika login standar gagal, sistem mencoba verifikasi password melalui fungsi RPC yang membaca `password_hash` dari `public.users`. Jika cocok, login dianggap berhasil dan sesi di-cache lokal. |

### Akar Masalah 3.2 — Migration 004 Belum Dijalankan
| Aspek | Detail |
|---|---|
| **Lokasi** | `supabase/migrations/004_public_passwords.sql` |
| **Penyebab** | Fungsi RPC `verify_public_password` dan kolom `password_hash` di `public.users` didefinisikan di migration 004. Jika migration ini belum dijalankan, fallback RPC akan gagal. |
| **Perbaikan** | Migration 004 sudah dibuat. Jalankan `supabase migration up` untuk mengaktifkannya. |

### Akar Masalah 3.3 — RLS Policy Memblokir Query
| Aspek | Detail |
|---|---|
| **Lokasi** | `lib/data/remote/auth_repository.dart` — method `syncInitialData()` |
| **Penyebab** | Setelah login berhasil, `syncInitialData()` mencoba `SELECT` dari tabel `businesses`, `categories`, `user_businesses`. Jika RLS policy tidak mengizinkan akses, query mengembalikan data kosong (bukan error). |
| **Status** | RLS policy sudah dibuat di migration 001. Policy ini menggunakan `auth.uid()` dan fungsi `user_has_business_access()`. Pastikan user memiliki akses ke bisnis yang dimaksud. |

---

## 4. Ringkasan Perbaikan yang Sudah Dilakukan

| No | Masalah | File | Perbaikan |
|---|---|---|---|
| 1 | Tidak redirect ke dashboard setelah login | `login_screen.dart`, `auth_provider.dart` | `login()` return `bool`, navigasi langsung pakai return value |
| 2 | Data tidak terisi setelah login | `auth_repository.dart` | Panggil `syncInitialData()` setelah `signIn()` |
| 3 | Data tidak terisi setelah restart app | `auth_repository.dart`, `auth_provider.dart` | Panggil `syncInitialData()` + `_retrySyncIfDataEmpty()` di `tryRestoreSession()` |
| 4 | Sync gagal tanpa retry | `auth_repository.dart` | Exponential backoff retry (3x) di `syncInitialData()` |
| 5 | UI tidak update setelah retry sukses | `auth_provider.dart` | Callback `onDataSynced` untuk invalidate provider |
| 6 | User tidak ada di auth.users | `auth_repository.dart` | Fallback RPC `verify_public_password` |
| 7 | Pull-to-refresh tidak ada | `business_switcher_screen.dart`, `owner_dashboard_tab.dart`, `dashboard_screen.dart` | `RefreshIndicator` + invalidate provider |

---

## 5. Cara Test

1. **Fresh Install** — Hapus data aplikasi, install ulang
2. Login dengan `owner@ssrs.com` / `password123`
3. Verify:
   - ✅ Langsung redirect ke dashboard Owner
   - ✅ 3 bisnis muncul (Agen Minuman Alkali, Teh Solo, Warung Kopi)
   - ✅ Kategori muncul sesuai bisnis
   - ✅ Pull-to-refresh berfungsi
4. **Restart app** — tanpa login ulang
   - ✅ Langsung masuk dashboard (session restore)
   - ✅ Data masih ada (sync dari Supabase)
5. **Test offline** — matikan internet, buka app
   - ✅ Data dari Hive tetap muncul
   - ✅ Pull-to-refresh akan sync saat online kembali
