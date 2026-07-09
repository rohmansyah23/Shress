# SSRS Finance

Multi-tenant financial reporting application — offline-first dengan Supabase sync, role-based access, dan P&L reports.

> **Status:** Active Development · `v1.0.0`

## Fitur Utama

| Fitur | Deskripsi |
|---|---|
| **📊 Dashboard** | Ringkasan keuangan per bisnis — Pendapatan, HPP, Laba Kotor, Pengeluaran, Laba/Rugi |
| **💳 Transaksi** | Input transaksi Uang Masuk/Keluar per kategori, dengan dukungan COGS untuk income |
| **📈 Laporan Laba/Rugi** | Periodic breakdown (Bulan Ini · Bulan Lalu · 3 Bulan · Kustom), grafik bulanan/mingguan, bar chart + line chart overlay |
| **📤 Export CSV/PDF** | Ekspor laporan laba/rugi ke file CSV (spreadsheet) atau PDF (siap cetak), share via system share sheet |
| **👥 Multi-role** | Owner (full access), Manager (manage staff + transaksi), Staff (transaksi sendiri) |
| **🔐 Auth** | Login/logout via Supabase Auth, session restore, role-based routing |
| **📱 QRIS** | Offline-first QRIS image display per bisnis, upload ke Supabase Storage |
| **🔄 Offline Sync** | Hive local database + Supabase sync, connectivity-aware |
| **👑 Owner Panel** | Multi-business dashboard, user management (role dropdown, business assignment) |

## Screens

```
lib/ui/
├── splash/          splash_screen.dart         → App splash + auth route guard
├── auth/            login_screen.dart           → Email/password login
├── owner/
│   ├── owner_shell.dart                        → Owner scaffold + bottom nav
│   ├── owner_dashboard_tab.dart                → Owner business overview
│   └── user_management_panel.dart              → User/RBAC management
├── business_switcher/
│   └── business_switcher_screen.dart           → Business picker (manager/staff)
├── dashboard/
│   └── dashboard_screen.dart                   → Store dashboard + summary cards
├── transaction/
│   └── transaction_sheet.dart                  → Income/Expense form (modal)
└── ledger/
    └── profit_loss_sheet.dart                  → P&L sheet + bar/line chart + export
```

## Tech Stack

| Layer | Teknologi |
|---|---|
| **Framework** | Flutter 3.x · Dart 3.x |
| **State Management** | Riverpod 2.x (StateNotifier + FutureProvider.family) |
| **Backend** | Supabase (Auth · PostgreSQL · Storage) |
| **Local DB** | Hive (offline-first, sync buffer) |
| **Charts** | fl_chart 0.69.x (bar + line combined) |
| **PDF** | pdf 3.x + share_plus 10.x |
| **SVG** | flutter_svg 2.x |
| **Icons** | flutter_launcher_icons |
| **Networking** | supabase_flutter · connectivity_plus |

## Arsitektur

```
lib/
├── core/
│   ├── config/          app_config.dart         → .env loader + validator
│   ├── constants/       constants.dart          → App-wide constants
│   ├── export/          export_service.dart     → CSV/PDF generation
│   ├── network/         connectivity_service.dart
│   ├── qris/            qris_resolver.dart      → QRIS image resolution
│   │                   qris_upload_service.dart → Supabase Storage upload
│   ├── sync/            sync_service.dart       → Offline → Supabase sync
│   ├── theme/           app_theme.dart          → Material 3 theme + text styles
│   └── utils/           format_helpers.dart     → Rupiah, date, period formatting
│
├── data/
│   ├── local/
│   │   ├── database.dart                       → Hive CRUD operations
│   │   └── models/      *.dart                 → Data models (Business, Transaction, etc.)
│   └── remote/
│       └── auth_repository.dart                → Supabase Auth operations
│
├── providers/
│   ├── auth_provider.dart                      → Auth state + role management
│   └── transaction_provider.dart               → Transaction save + refresh
│
└── ui/                  (screens listed above)
```

## Roles & Access

| Role | Akses |
|---|---|
| **👑 Owner** | Semua bisnis, manage users, manage roles, all reports, manage categories |
| **📋 Manager** | Business assignments, input transaksi, lihat laporan bisnis assigned, manage staff |
| **👤 Staff** | Input transaksi sendiri, lihat laporan bisnis assigned |

## Setup

### Prasyarat

- Flutter SDK 3.x
- Supabase project (free tier cukup)

### 1. Clone & Install

```bash
git clone https://github.com/your-org/ssrs_finance.git
cd ssrs_finance
flutter pub get
```

### 2. Konfigurasi `.env`

```env
# Dapatkan dari Supabase Dashboard → Project Settings → API
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Opsional
APP_NAME=SSRS Finance
APP_ENVIRONMENT=development
SYNC_INTERVAL_SECONDS=30
```

### 3. Migrasi Database

Ikuti panduan di [supabase/MIGRATE.md](supabase/MIGRATE.md):

```bash
# Opsi 1: Via Supabase Dashboard
# Buka SQL Editor → copy paste supabase/migrations/001_initial_schema.sql → Run

# Opsi 2: Via CLI
supabase link --project-ref your-project-ref
supabase db push
```

### 4. Jalankan

```bash
flutter run
```

## Fitur Lengkap

### 📊 Dashboard (per Store)
- Laba/Rugi bersih (large card, warna dinamis 🟢/🔴)
- Pendapatan, HPP, Laba Kotor, Pengeluaran (detail cards)
- Sync banner dengan jumlah transaksi pending
- QRIS button → bottom sheet overlay
- Pull-to-refresh

### 💳 Transaksi
- Segmented tab: Uang Masuk / Uang Keluar
- Kategori dropdown (dinamis per tab)
- Date picker
- COGS (HPP) — hanya untuk income, animasi expand
- Payment method: Tunai / Transfer / QRIS / Lainnya
- Validasi form + snackbar feedback

### 📈 Laporan Laba/Rugi
- **Period filters:** Bulan Ini · Bulan Lalu · 3 Bulan · Kustom (date range picker)
- **Bar chart (fl_chart):** Grouped income/expense bars per month/week, animated (800ms easeInOutCubic)
- **Line chart overlay:** Net profit trend line with dots, styled per profit/loss
- **Weekly breakdown toggle:** Switch between monthly/weekly view (single-month periods only)
- **Net profit summary rows** with ▲/▼ arrow indicators
- **Accounting layout:** Pendapatan → HPP → Laba Kotor → Pengeluaran → Laba/Rugi Bersih
- **Transaction list:** Toggle view with detail dialog
- **Export:** CSV (spreadsheet) + PDF (professional A4, colored sections)

### 👑 Owner Panel
- Two-tab scaffold: Dashboard + Users
- Multi-business overview cards
- User list with search 🔍
- Role dropdown: Owner / Manager / Staff
- Business assignment checkboxes (multi-select)
- Pull-to-refresh + local cache

### 🔐 Authentication
- Email/password login with Supabase Auth
- Session restore on app start
- Error messages in Bahasa Indonesia
- Reactive route guard (Splash → Dashboard/Login)

### 🔄 Offline Sync
- All transactions saved to Hive first
- Background sync when online
- Sync banner showing pending count
- Connectivity-aware

### 🖼️ QRIS
- Resolution chain: Supabase Storage URL → local SVG → network URL → fallback icon
- Offline badge indicator
- Placeholder SVGs bundled (replace with real QRIS via upload service)
- Upload service to Supabase Storage

## App Icon

```bash
# Place 1024×1024 PNG at assets/icons/app_icon.png
# Then generate all resolutions:
dart run flutter_launcher_icons
```

## Struktur Database (Supabase)

| Tabel | Deskripsi |
|---|---|
| `users` | User profiles (auto-sync from Auth) |
| `businesses` | Businesses (3 default: Alkali, Teh Solo, Warung Kopi) |
| `user_businesses` | User ↔ Business bridge |
| `categories` | Income/Expense categories per business |
| `transactions` | Financial transactions |
| `financial_reports` | Pre-calculated P&L snapshots |

## Lisensi

Proprietary — SSRS
