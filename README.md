# Sheress

Multi-tenant financial reporting application — cloud-first dengan Supabase, role-based access, dan P&L reports.

> **Status:** Active Development · `v1.0.0`

## Tech Stack

| Layer | Teknologi |
|---|---|
| **Framework** | Flutter 3.x · Dart 3.x |
| **State Management** | Riverpod 2.x (StateNotifier + FutureProvider) |
| **Backend** | Supabase (Auth · PostgreSQL · Storage) |
| **Charts** | fl_chart 0.69.x (bar + line combined) |
| **PDF** | pdf 3.x + share_plus 10.x |
| **SVG** | flutter_svg 2.x |
| **Error Tracking** | Sentry 9.x |
| **Networking** | supabase_flutter · connectivity_plus |
| **Icons** | flutter_launcher_icons |

## Fitur Utama

| Fitur | Deskripsi |
|---|---|
| **Dashboard** | Ringkasan keuangan per bisnis — Pendapatan, HPP, Laba Kotor, Pengeluaran, Laba/Rugi |
| **Transaksi** | Input transaksi Uang Masuk/Keluar per kategori, dengan dukungan COGS untuk income |
| **Laporan Laba/Rugi** | Periodic breakdown (Bulan Ini · Bulan Lalu · 3 Bulan · Kustom), grafik bulanan/mingguan, bar chart + line chart overlay |
| **Export CSV/PDF** | Ekspor laporan laba/rugi ke file CSV atau PDF, share via system share sheet |
| **Multi-role** | Owner (full access), Manager (manage staff + transaksi), Staff (transaksi sendiri) |
| **Auth** | Login/logout via Supabase Auth, session restore, role-based routing, fallback RPC password |
| **QRIS** | QRIS image display per bisnis, upload ke Supabase Storage |
| **Owner Panel** | Multi-business dashboard, user management (role dropdown, business assignment) |
| **Sync Status** | Indikator status koneksi & pending sync |
| **Saved Reports** | Simpan laporan periodik untuk akses cepat |

## Arsitektur

```
lib/
├── main.dart                              Entry point + ProviderScope
├── core/
│   ├── config/          app_config.dart         → .env loader + validator
│   ├── constants/       constants.dart          → App-wide constants
│   ├── export/          export_service.dart     → CSV/PDF generation
│   ├── network/         connectivity_service.dart
│   ├── qris/            qris_resolver.dart      → QRIS image resolution
│   │                   qris_upload_service.dart → Supabase Storage upload
│   ├── services/        sentry_service.dart     → Crash reporting
│   ├── sync/            sync_service.dart       → V1 stub (cloud-only)
│   ├── theme/           app_theme.dart          → Material 3 theme + text styles
│   ├── utils/           error_handler.dart      → Error classification
│   │                   format_helpers.dart      → Rupiah, date, period formatting
│   └── widgets/         error_widgets.dart      → Error/skeleton widgets
│                       global_error_boundary.dart
│                       offline_overlay.dart
│                       skeleton_widgets.dart
│
├── data/
│   ├── local/
│   │   ├── database.dart                       → V1 stub (cloud-only)
│   │   └── models/      *.dart                 → 6 data models
│   ├── remote/
│   │   ├── auth_repository.dart                → Supabase Auth + RPC fallback
│   │   └── supabase_service.dart               → All Supabase queries
│   └── repositories/                           → V2 (empty)
│
├── providers/
│   ├── auth_provider.dart                      → Auth state, roles, users, businesses
│   └── transaction_provider.dart               → Transaction CRUD + refresh
│
└── ui/
    ├── auth/            login_screen.dart
    ├── business_detail/ business_detail_screen.dart
    ├── business_switcher/ business_switcher_screen.dart
    ├── category/        category_management_screen.dart
    ├── dashboard/       dashboard_screen.dart, qris_display_screen.dart, qris_upload_screen.dart
    ├── ledger/          profit_loss_sheet.dart
    ├── manager/         manager_shell.dart
    ├── onboarding/      onboarding_screen.dart
    ├── owner/           owner_shell.dart, owner_dashboard_tab.dart, owner_history_screen.dart,
    │                    business_owner_shell.dart, user_management_panel.dart, user_form_screen.dart
    ├── profile/         profile_screen.dart
    ├── reports/         manager_report_screen.dart, owner_report_screen.dart, saved_reports_screen.dart
    ├── settings/        settings_screen.dart
    ├── splash/          splash_screen.dart
    ├── sync/            sync_status_screen.dart
    └── transaction/     transaction_sheet.dart, transaction_history_screen.dart, edit_transaction_page.dart
```

## Provider Tree

| Provider | Type | Purpose |
|---|---|---|
| `supabaseServiceProvider` | `Provider` | SupabaseService singleton |
| `authRepositoryProvider` | `Provider` | AuthRepository singleton |
| `authProvider` | `StateNotifierProvider` | Auth state + login/logout/session restore |
| `isAuthenticatedProvider` | Derived `Provider<bool>` | Quick auth check |
| `currentUserProvider` | Derived `Provider<UserModel?>` | Current user |
| `currentUserRoleProvider` | Derived `Provider<String?>` | Current role |
| `allBusinessesProvider` | `FutureProvider` | All businesses (owner) |
| `accessibleBusinessesProvider` | `FutureProvider` | Filtered businesses (manager/staff) |
| `allUsersProvider` | `FutureProvider` | All users (owner only) |
| `transactionRefreshProvider` | `StateProvider<int>` | Trigger list refresh |

## Roles & Access

| Role | Akses |
|---|---|
| **Owner** | Semua bisnis, manage users, manage roles, all reports, manage categories |
| **Manager** | Business assignments, input transaksi, lihat laporan bisnis assigned, manage staff |
| **Staff** | Input transaksi sendiri, lihat laporan bisnis assigned |

## Error Handling

- **`ErrorHandler.classify()`** — maps Supabase/network errors ke pesan Indonesia
- **`GlobalErrorBoundary`** — catches Flutter framework errors
- **`AppErrorObserver`** — catches Riverpod provider errors
- **Zone-level capture** — async errors via `runZonedGuarded`
- **Sentry** — all errors forwarded to Sentry dashboard

## Supabase Migrations

5 migration files di `supabase/migrations/`:

| File | Isi |
|---|---|
| `001_initial_schema.sql` | Core tables + RLS + triggers + seed data |
| `002_qris_storage_bucket.sql` | Storage bucket + RLS for QRIS |
| `003_demo_accounts.sql` | 3 demo users (owner/manager/staff) |
| `004_public_passwords.sql` | RPC `verify_public_password` fallback |
| `005_update_rls_policies.sql` | RLS policy updates |

## Setup

### Prasyarat

- Flutter SDK 3.x
- Supabase project (free tier cukup)

### 1. Clone & Install

```bash
git clone https://github.com/your-org/sheress.git
cd sheress
flutter pub get
```

### 2. Konfigurasi `.env`

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

APP_NAME=Sheress
APP_ENVIRONMENT=development
SYNC_INTERVAL_SECONDS=30
```

### 3. Migrasi Database

Ikuti panduan di [supabase/MIGRATE.md](supabase/MIGRATE.md):

```bash
# Opsi 1: Via Supabase Dashboard
# Buka SQL Editor → copy paste migration files → Run

# Opsi 2: Via CLI
supabase link --project-ref your-project-ref
supabase db push
```

### 4. Jalankan

```bash
flutter run
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

## Testing

```bash
flutter test                          # Run all tests
flutter analyze                       # Static analysis
```

Saat ini hanya ada 1 smoke test (`test/widget_test.dart`).

## Lisensi

Proprietary — Sheress
