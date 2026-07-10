# Sheress

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2.svg?style=for-the-badge&logo=Dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Cloud--First-3ECF8E.svg?style=for-the-badge&logo=Supabase&logoColor=white)](https://supabase.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-brightgreen.svg?style=for-the-badge)](#)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg?style=for-the-badge)](#)

**Sheress** adalah platform pelaporan dan manajemen keuangan *multi-tenant* berbasis mobile yang dirancang khusus untuk mempermudah operasional multi-cabang/bisnis (*multi-business tracking*). Dibangun menggunakan Flutter untuk performa UI yang responsif dan Supabase sebagai solusi *cloud-first backend* berkeamanan tinggi dengan kebijakan *Row Level Security* (RLS).

---

## 🚀 Fitur Utama

Aplikasi ini dirancang dengan alur kerja keuangan modern dan pembagian peran yang ketat (*Role-Based Access Control*):

* 📊 **Multi-Tenant Dashboard**: Rekapitulasi laba kotor, HPP (COGS), total pendapatan, pengeluaran operasional, serta laba/rugi bersih per bisnis secara waktu nyata (*real-time*).
* 💼 **Manajemen Multi-Bisnis**: Kemampuan bagi *Owner* untuk mengelola banyak cabang usaha (*multi-business switcher*) secara *seamless* dalam satu akun.
* 👥 **Manajemen Pengguna Terintegrasi**: Panel kontrol pengguna lengkap dengan penetapan hak akses/role (*Owner*, *Manager*, *Staff*) dan pembatasan visibilitas cabang.
* 📈 **Laporan Laba/Rugi (P&L) Interaktif**: Analisis periodik (Harian, Mingguan, Bulanan, Tahunan) dengan visualisasi grafik garis & batang interaktif (*fl_chart*).
* 📸 **Integrasi QRIS Statis**: Unggah dan kelola gambar kode QRIS per bisnis menggunakan Supabase Storage untuk pembayaran digital yang cepat di setiap cabang.
* 🎨 **Desain Modern & Responsif**: Tema kustom berbasis Material 3 dengan dukungan penuh *Light/Dark Mode* yang dirancang secara ergonomis untuk visibilitas dan kenyamanan maksimal.

---

## 🛠️ Tech Stack & Dependencies

| Layer | Teknologi / Paket | Deskripsi |
|---|---|---|
| **Core Framework** | `Flutter 3.x` · `Dart 3.x` | Kerangka kerja pengembangan lintas platform. |
| **State Management** | `Flutter Riverpod 2.x` | Manajemen state deklaratif, aman tipe data, dan mudah diuji. |
| **Backend / Database** | `Supabase Flutter` | Integrasi Auth, database PostgreSQL, dan penyimpanan Cloud Storage. |
| **Visualisasi Data** | `fl_chart 0.69.x` | Library grafik performa tinggi untuk visualisasi tren profitabilitas. |
| **Error & Crash Tracking** | `Sentry Flutter 9.x` | Pemantauan error secara real-time langsung ke dashboard Sentry. |
| **Konektivitas** | `connectivity_plus` | Pendeteksi status jaringan aktif demi kelancaran sinkronisasi data cloud. |

---

## 📐 Arsitektur Folder

Aplikasi Shress mengadopsi pola pemisahan lapisan logika (*Separation of Concerns*) yang bersih dan terstruktur untuk skalabilitas jangka panjang:

```
lib/
├── main.dart                  # Titik awal aplikasi & inisialisasi konfigurasi global
├── core/
│   ├── config/                # Validasi variabel lingkungan (.env)
│   ├── constants/             # Magic strings, keys, dan parameter aplikasi
│   ├── network/               # Monitoring status konektivitas internet
│   ├── qris/                  # Layanan resolver dan pengunggah gambar QRIS
│   ├── services/              # Integrasi SDK eksternal (seperti Sentry)
│   ├── theme/                 # Skema warna Material 3, tipografi, dan status-colors
│   ├── utils/                 # Klasifikasi error (ErrorHandler) & helper formatting data
│   └── widgets/               # Komponen UI global (skeleton loader, offline overlay, dll.)
│
├── data/
│   ├── local/                 # Model data internal aplikasi
│   └── remote/                # Repositori Auth & Supabase Query Service (Single Source of Truth)
│
├── providers/                 # Riverpod Providers untuk state auth dan transaksi
│
└── ui/                        # Layap presentasi (Screen, Sheet, Panel per modul fitur)
    ├── auth/                  # Halaman masuk & pemulihan kata sandi
    ├── business_switcher/     # Halaman pemilih bisnis/cabang aktif
    ├── category/              # Kelola kategori pemasukan & pengeluaran (CRUD)
    ├── dashboard/             # Antarmuka dasbor utama & panel QRIS
    ├── owner/                 # Panel khusus Owner (User management & Business CRUD)
    ├── reports/               # Layar filter laporan keuangan
    ├── settings/              # Preferensi aplikasi dan konfigurasi akun
    └── transaction/           # Alur input transaksi baru dan riwayat mutasi
```

---

## 🔒 Skema Keamanan Database (Supabase RLS)

Data multi-tenant dilindungi dengan kebijakan **Row Level Security (RLS)** pada level PostgreSQL di Supabase. Kebijakan ini memastikan isolasi data antar penyewa/tenant berjalan dengan aman:

* **Tabel `users`**: Profil pengguna disinkronkan secara otomatis melalui trigger database saat registrasi di Supabase Auth.
* **Tabel `businesses`**: Hanya dapat dimodifikasi oleh Owner. Manager dan Staff hanya memiliki izin baca pada bisnis tempat mereka ditugaskan.
* **Tabel `user_businesses`**: Tabel perantara yang mendefinisikan hubungan penugasan akun ke cabang bisnis tertentu.
* **Tabel `transactions`**: RLS memastikan transaksi hanya bisa dibaca/ditulis oleh pengguna yang memiliki penugasan aktif (`user_businesses`) pada bisnis tersebut.

Detail skrip migrasi database dapat ditemukan pada folder [supabase/migrations/](file:///D:/A-Projek/mobile-app/Shress/supabase/migrations/).

---

## ⚙️ Panduan Menjalankan Project

### Prasyarat System
* Flutter SDK versi `3.22.x` ke atas
* Akun atau CLI proyek **Supabase** aktif

### 1. Clone & Unduh Dependensi
```bash
git clone https://github.com/your-org/shress.git
cd shress
flutter pub get
```

### 2. Konfigurasi Variabel Lingkungan
Buat berkas `.env` pada direktori root proyek dan isi parameter berikut:
```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
APP_NAME=Sheress
APP_ENVIRONMENT=production
SYNC_INTERVAL_SECONDS=30
```

### 3. Setup Skema Database (Supabase)
Terapkan migrasi database yang ada di folder `supabase/migrations/` ke proyek Supabase Anda. Anda dapat menyalin file migrasi ke dalam SQL Editor Dashboard Supabase Anda, atau menggunakan Supabase CLI:
```bash
supabase link --project-ref <your-project-ref>
supabase db push
```

### 4. Menjalankan Aplikasi
```bash
flutter run
```

---

## 📦 Panduan Kompilasi & Build Rilis

Aplikasi ini mendukung otomatisasi kompilasi untuk keperluan pengujian internal maupun distribusi toko aplikasi:

### 1. Build Android App Bundle (AAB) — Siap Unggah Play Store
Merupakan format terkompresi yang direkomendasikan Google Play Store untuk mengoptimalkan ukuran download pengguna:
```bash
flutter build appbundle --release
```
*Hasil output berkas:* `build/app/outputs/bundle/release/app-release.aab`

### 2. Build APK Tunggal (Fat APK) — Untuk Instalasi Langsung
Berguna untuk pengujian mandiri tanpa melalui Play Store:
```bash
flutter build apk --release
```
*Hasil output berkas:* `build/app/outputs/flutter-apk/app-release.apk`

### 3. Build APK Terpisah per Arsitektur CPU (Hemat Ukuran)
Menghasilkan berkas APK yang lebih kecil dan spesifik untuk arsitektur perangkat (ARM v7, ARM v8, x86_64):
```bash
flutter build apk --release --split-per-abi
```

---

## 🧪 Pengujian & Penjaminan Kualitas

Selalu pastikan kualitas kode terjaga dengan menjalankan perintah berikut sebelum melakukan komitmen (*commit*) perubahan ke repositori git:

```bash
flutter analyze              # Melakukan analisis kode statis (linter check)
flutter test                 # Menjalankan seluruh unit & widget test
```

---

## 📄 Lisensi
Proprietary — Hak Cipta Dilindungi Undang-Undang. **Sheress** 2026.
