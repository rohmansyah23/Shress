<div align="center">

<img src="assets/icons/app_icon.png" alt="Sheress" width="140" style="border-radius: 24px;" />

<br />
<br />

# Sheress

### Multi-tenant financial reporting for Indonesian SMEs

<br />

A production-grade Flutter application that empowers business owners, managers, and staff
with real-time financial insights, transaction tracking, QRIS payment integration, and
multi-business management — all backed by Supabase.

<br />

[![Flutter](https://img.shields.io/badge/Flutter-3.12+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-2.16+-3FCF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-Welcome-brightgreen?style=for-the-badge)](https://github.com/username/sheress/pulls)

<br />

[![Download APK](https://img.shields.io/badge/⬇_Download-APK-blue?style=for-the-badge&logo=android)](#build)
[![Documentation](https://img.shields.io/badge/📖_Documentation-white?style=for-the-badge&logo=github)](#table-of-contents)
[![Live Demo](https://img.shields.io/badge/🚀_Live_Demo-green?style=for-the-badge&logo=vercel)](#preview)

<br />

<sub>

**Flutter** • **Dart** • **Supabase** • **Riverpod** • **Clean Architecture**

</sub>

</div>

---

<br />

## 📋 Quick Overview

<table>
<tr>
<td width="50%" valign="top">

| | |
|:--|:--|
| 📱 **Platform** | Android, Web |
| 🏗️ **Architecture** | Clean Architecture |
| ⚡ **State Management** | Riverpod |
| 🔥 **Backend** | Supabase |
| 🗄️ **Database** | PostgreSQL |
| 🔐 **Auth** | Supabase Auth |
| 🌐 **Language** | Indonesian (id_ID) |
| 📄 **License** | MIT |
| 📦 **Version** | 1.0.0 |

</td>
<td width="50%" valign="top">

| | |
|:--|:--|
| 🎨 **UI Framework** | Material 3 |
| 🌙 **Theme** | Dark & Light Mode |
| 📊 **Charts** | fl_chart |
| 💳 **Payments** | QRIS Integration |
| 🐛 **Monitoring** | Sentry |
| 🔔 **Notifications** | Local Notifications |
| 📶 **Offline** | Connectivity Detection |
| 🏪 **Multi-Tenant** | Role-Based (Owner/Manager/Staff) |
| ☁️ **Storage** | Supabase Storage |

</td>
</tr>
</table>

<br />

---

<br />

## 📸 Preview

<p align="center">
  <em>App screenshots and demo coming soon.</em>
  <br /><br />
  <img src="https://via.placeholder.com/300x600/1A237E/FFFFFF?text=Dashboard" alt="Dashboard" width="200" />
  &nbsp;&nbsp;
  <img src="https://via.placeholder.com/300x600/0D47A1/FFFFFF?text=Transactions" alt="Transactions" width="200" />
  &nbsp;&nbsp;
  <img src="https://via.placeholder.com/300x600/1565C0/FFFFFF?text=Reports" alt="Reports" width="200" />
  &nbsp;&nbsp;
  <img src="https://via.placeholder.com/300x600/1E88E5/FFFFFF?text=Dark+Mode" alt="Dark Mode" width="200" />
</p>

<br />

> 💡 **Tip:** Replace the placeholder images above with actual screenshots in `docs/images/` folder.

<br />

---

<br />

## 📑 Table of Contents

- [About](#-about)
- [Features](#-features)
- [Architecture](#-architecture)
- [Folder Structure](#-folder-structure)
- [Tech Stack](#-tech-stack)
- [Screens](#-screens)
- [Getting Started](#-getting-started)
- [Environment Variables](#-environment-variables)
- [Configuration](#-configuration)
- [Packages](#-packages)
- [Performance](#-performance)
- [Security](#-security)
- [Testing](#-testing)
- [Build](#-build)
- [Roadmap](#-roadmap)
- [FAQ](#-faq)
- [Contributing](#-contributing)
- [License](#-license)
- [Author](#-author)
- [Acknowledgements](#-acknowledgements)

<br />

---

<br />

## 🎯 About

<div align="center">

**The Problem**

Most Indonesian SMEs still rely on manual bookkeeping — paper notebooks, spreadsheets, or scattered notes — leading to lost records, fragmented data, and zero real-time visibility.

**The Solution**

Sheress provides a **cloud-first**, **role-based** financial platform that unifies transaction tracking, debt management, QRIS payments, and multi-business oversight in a single, beautiful app.

</div>

<br />

### Who Is This For?

| Role | What They Can Do |
|:-----|:-----------------|
| 👔 **Business Owner** | Monitor multiple businesses, manage staff, view P&L reports |
| 📊 **Manager** | Track daily transactions, generate reports, manage QRIS |
| 👤 **Staff** | Record income & expenses in real-time |

<br />

---

<br />

## ✨ Features

<table>
<tr>
<td width="50%" valign="top">

#### 🔐 Authentication & Access
- ✅ Username/password login
- ✅ Role-based access control
- ✅ Password reset flow
- ✅ Session persistence

#### 🏪 Multi-Business
- ✅ Multiple business entities
- ✅ Seamless business switching
- ✅ Business-level data isolation
- ✅ Business profile management

#### 💰 Transactions
- ✅ Income & expense tracking
- ✅ Category-based organization
- ✅ Transaction history with filters
- ✅ Edit & delete transactions

</td>
<td width="50%" valign="top">

#### 📊 Financial Reports
- ✅ Real-time dashboard
- ✅ P&L (Profit & Loss) reports
- ✅ Interactive bar charts
- ✅ Period-based filtering

#### 💳 QRIS Integration
- ✅ Display QRIS per business
- ✅ Upload custom QRIS images
- ✅ SVG rendering support
- ✅ Image caching

#### 📋 Debt & Consignment
- ✅ Debtor/reseller tracking
- ✅ Payment status management
- ✅ Consignment monitoring
- ✅ Sales reports

</td>
</tr>
<tr>
<td width="50%" valign="top">

#### 🎨 UI/UX
- ✅ Material 3 design system
- ✅ Dark & Light theme
- ✅ Custom color palette
- ✅ Smooth animations
- ✅ Offline overlay

#### 🔔 Notifications
- ✅ Daily reminders
- ✅ Local notifications
- ✅ Customizable schedule

</td>
<td width="50%" valign="top">

#### ⚡ Technical
- ✅ Clean Architecture
- ✅ Riverpod state management
- ✅ Supabase backend
- ✅ Sentry crash reporting
- ✅ Connectivity monitoring
- ✅ Global error boundary

</td>
</tr>
</table>

<br />

---

<br />

## 🏗️ Architecture

Sheress follows **Clean Architecture** with a **feature-based** structure, ensuring separation of concerns, testability, and maintainability.

```
┌──────────────────────────────────────────────────────────┐
│                    🎨 PRESENTATION                        │
│                  UI Screens, Widgets                      │
│                                                          │
│    ┌──────────┐    ┌───────────┐    ┌──────────────┐    │
│    │    UI    │    │ Providers │    │   Reusable   │    │
│    │ Screens  │◄──▶│ (Riverpod)│◄──▶│   Widgets    │    │
│    └──────────┘    └───────────┘    └──────────────┘    │
└──────────────────────────┬───────────────────────────────┘
                           │
┌──────────────────────────▼───────────────────────────────┐
│                      📦 DATA                             │
│              Models, Services, Repositories               │
│                                                          │
│    ┌──────────┐    ┌───────────┐    ┌──────────────┐    │
│    │  Models  │◄───│  Services │◄───│   Remote     │    │
│    │  (DTOs)  │    │ (Supabase)│    │   API        │    │
│    └──────────┘    └───────────┘    └──────────────┘    │
└──────────────────────────┬───────────────────────────────┘
                           │
┌──────────────────────────▼───────────────────────────────┐
│                      ⚙️ CORE                             │
│            Config, Theme, Utils, Services                 │
│                                                          │
│    ┌────────┐ ┌────────┐ ┌────────┐ ┌────────────┐     │
│    │ Config │ │ Theme  │ │ Utils  │ │  Services  │     │
│    └────────┘ └────────┘ └────────┘ └────────────┘     │
└──────────────────────────────────────────────────────────┘
```

### Layer Breakdown

| Layer | Purpose | Key Components |
|:------|:--------|:---------------|
| ⚙️ **Core** | Shared infrastructure & utilities | `AppConfig`, `AppTheme`, `ErrorHandler`, `FormatHelpers`, `Constants` |
| 📦 **Data** | Data models & API operations | `SupabaseService`, `AuthRepository`, 9 data models |
| 🔄 **Providers** | Business logic & state management | `AuthProvider`, `TransactionProvider`, `ThemeProvider`, etc. |
| 🎨 **UI** | Feature screens & widgets | 17 feature modules, 30+ screens |

<br />

---

<br />

## 📁 Folder Structure

```
lib/
│
├── main.dart                              # 🚀 App entry point
│
├── core/                                  # ⚙️  Shared infrastructure
│   ├── config/                            #     Environment & app config
│   │   └── app_config.dart
│   ├── constants/                         #     App-wide constants
│   │   └── constants.dart
│   ├── network/                           #     Connectivity monitoring
│   │   └── connectivity_service.dart
│   ├── qris/                              #     QRIS image handling
│   │   ├── qris_resolver.dart
│   │   └── qris_upload_service.dart
│   ├── services/                          #     Platform services
│   │   ├── notification_service.dart
│   │   └── sentry_service.dart
│   ├── theme/                             #     Material 3 theming
│   │   └── app_theme.dart
│   ├── utils/                             #     Shared utilities
│   │   ├── error_handler.dart
│   │   └── format_helpers.dart
│   └── widgets/                           #     Reusable UI components
│       ├── error_widgets.dart
│       ├── finance_bar_chart.dart
│       ├── global_error_boundary.dart
│       ├── offline_overlay.dart
│       ├── shared_widgets.dart
│       ├── summary_card.dart
│       └── trend_chart.dart
│
├── data/                                  # 📦 Data layer
│   ├── local/
│   │   └── models/                        #     Data models (9 models)
│   │       ├── business_model.dart
│   │       ├── category_model.dart
│   │       ├── consignment_model.dart
│   │       ├── consignor_model.dart
│   │       ├── debt_model.dart
│   │       ├── debt_payment_model.dart
│   │       ├── debtor_model.dart
│   │       ├── transaction_model.dart
│   │       └── user_model.dart
│   └── remote/                            #     API services
│       ├── auth_repository.dart
│       └── supabase_service.dart
│
├── providers/                             # 🔄 Riverpod providers
│   ├── auth_provider.dart
│   ├── business_providers.dart
│   ├── debt_consignment_provider.dart
│   ├── debtor_provider.dart
│   ├── notification_provider.dart
│   ├── paginated_list_provider.dart
│   ├── query_cache_provider.dart
│   ├── theme_provider.dart
│   ├── transaction_list_provider.dart
│   └── transaction_provider.dart
│
└── ui/                                    # 🎨 Presentation layer
    ├── auth/                              #     Authentication
    ├── business_detail/                   #     Business detail
    ├── category/                          #     Category management
    ├── consignments/                      #     Consignment tracking
    ├── dashboard/                         #     Dashboard & QRIS
    ├── debtors/                           #     Debt management
    ├── manager/                           #     Manager role
    ├── onboarding/                        #     Onboarding wizard
    ├── owner/                             #     Owner role
    ├── profile/                           #     User profile
    ├── reports/                           #     Financial reports
    ├── settings/                          #     App settings
    ├── splash/                            #     Splash screen
    ├── transaction/                       #     Transaction CRUD
    └── widgetbook/                        #     Component showcase
```

<br />

---

<br />

## 🛠️ Tech Stack

| Category | Technology | Purpose |
|:---------|:-----------|:--------|
| 🎨 **Framework** | [Flutter](https://flutter.dev) | Cross-platform UI toolkit |
| 📝 **Language** | [Dart](https://dart.dev) | Type-safe programming language |
| 🔄 **State** | [Riverpod](https://riverpod.dev) | Compile-safe state management |
| ☁️ **Backend** | [Supabase](https://supabase.com) | Open-source Firebase alternative |
| 🗄️ **Database** | PostgreSQL (Supabase) | Relational database with RLS |
| 🔐 **Auth** | Supabase Auth | JWT-based authentication |
| 📊 **Charts** | [fl_chart](https://flchart.dev) | Beautiful, interactive charts |
| 🖼️ **SVG** | [flutter_svg](https://pub.dev/packages/flutter_svg) | SVG image rendering |
| 🔤 **Fonts** | [google_fonts](https://fonts.google.com) | Inter font family |
| 🐛 **Monitoring** | [Sentry](https://sentry.io) | Crash reporting & analytics |
| 🔔 **Notifications** | flutter_local_notifications | Local push notifications |
| 📶 **Network** | [connectivity_plus](https://pub.dev/packages/connectivity_plus) | Network status detection |
| ⚙️ **Config** | [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) | Environment variables |
| 📅 **Locale** | [intl](https://pub.dev/packages/intl) | Indonesian date/number formatting |

<br />

---

<br />

## 📱 Screens

| Screen | Description | Access |
|:-------|:------------|:-------|
| 🚀 **Splash** | App initialization & auth check | All |
| 🔐 **Login** | Username/password authentication | All |
| 🔄 **Forgot Password** | Password reset via email | All |
| 📋 **Onboarding** | First-time user setup | All |
| 📊 **Owner Dashboard** | Multi-business overview with charts | Owner |
| 📊 **Manager Dashboard** | Business-specific summary | Manager |
| 📝 **Transaction History** | Paginated list with filters | Owner, Manager |
| ➕ **Transaction Sheet** | Add/edit income or expense | Owner, Manager, Staff |
| 🏷️ **Category Management** | CRUD for categories | Owner |
| 🏪 **Business Detail** | Business info & QRIS | Owner |
| 🏪 **Manage Businesses** | Create/edit/delete businesses | Owner |
| 💳 **QRIS Display** | Show QRIS payment code | Manager, Owner |
| 📤 **QRIS Upload** | Upload QRIS image | Owner |
| 👥 **Debtors List** | View all debtors/resellers | Owner, Manager |
| 👤 **Debtor Detail** | Individual debtor info | Owner, Manager |
| ➕ **Add Debt** | Record new debt entry | Owner, Manager |
| 📦 **Consignors List** | View all consignors | Owner, Manager |
| 👤 **Consignor Detail** | Consignor transactions | Owner, Manager |
| 📦 **Consignment Detail** | Individual consignment | Owner, Manager |
| 📊 **Report Sales** | Sales report | Owner, Manager |
| 📈 **Owner Reports** | P&L by period | Owner |
| 📈 **Manager Reports** | Business financial reports | Manager |
| 👥 **User Management** | Manage staff users | Owner |
| ✏️ **User Form** | Add/edit user | Owner |
| 👤 **Profile** | User profile & settings | All |
| ⚙️ **Settings** | App preferences & theme | All |

<br />

---

<br />

## 🚀 Getting Started

### Prerequisites

| Requirement | Version | Check |
|:------------|:--------|:------|
| Flutter SDK | 3.12+ | `flutter --version` |
| Dart SDK | 3.12+ | `dart --version` |
| Android Studio | Latest | — |
| Supabase Account | Free tier | [supabase.com](https://supabase.com) |

### Installation

```bash
# 1️⃣  Clone the repository
git clone https://github.com/username/sheress.git
cd sheress

# 2️⃣  Install dependencies
flutter pub get

# 3️⃣  Configure environment
cp .env.template .env
# ✏️  Edit .env with your Supabase credentials

# 4️⃣  Run the app
flutter run
```

### Quick Start with Demo Data

After setting up Supabase and running migrations, login with:

| Role | Username | Password |
|:-----|:---------|:---------|
| 👔 Owner | `owner` | `password123` |
| 📊 Manager | `manager` | `password123` |
| 👤 Staff | `staff` | `password123` |

<br />

---

<br />

## 🔧 Environment Variables

Create a `.env` file in the project root:

```env
# ─── Supabase (Required) ──────────────────────────
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key

# ─── Sentry (Optional) ────────────────────────────
SENTRY_DSN=your-sentry-dsn

# ─── App Config ───────────────────────────────────
APP_NAME=Sheress
APP_ENVIRONMENT=development

# ─── Sync Config ──────────────────────────────────
SYNC_INTERVAL_SECONDS=30
SYNC_BATCH_SIZE=50
QRIS_CACHE_DAYS=30
```

### Getting Supabase Credentials

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project → **Project Settings → API**
3. Copy **Project URL** and **anon/public** key

<br />

---

<br />

## ⚙️ Configuration

<details>
<summary><strong>🟢 Android Configuration</strong></summary>

<br />

| Property | Value |
|:---------|:------|
| Min SDK | 24 (Android 7.0) |
| Namespace | `com.sheress.app` |
| Kotlin | 2.0.21 |
| AGP | 9.0.1 |

</details>

<details>
<summary><strong>🔵 Web Configuration</strong></summary>

<br />

| Property | Value |
|:---------|:------|
| PWA Manifest | `web/manifest.json` |
| Deep Link | `sheress://reset-password` |

</details>

<details>
<summary><strong>🗄️ Database Migrations (21 files)</strong></summary>

<br />

| # | Migration | Description |
|:--|:----------|:------------|
| 001 | `initial_schema` | Core tables: users, businesses, transactions |
| 002 | `qris_storage_bucket` | QRIS image storage |
| 003 | `demo_accounts` | Demo user accounts |
| 004 | `public_passwords` | Password hashing functions |
| 005 | `update_rls_policies` | Row Level Security |
| 006 | `public_auth` | Auth helper functions |
| 007 | `drop_unused_policies` | Cleanup unused RLS |
| 008 | `allow_anon_rls` | Anonymous RLS access |
| 009 | `insert_demo_users` | Seed demo users |
| 010 | `username_login` | Username-based auth |
| 011 | `qris_mime_types` | QRIS MIME restrictions |
| 012 | `fix_qris_storage_policies` | Fix QRIS RLS |
| 013 | `simplify_qris_storage_policies` | Simplify QRIS RLS |
| 014 | `drop_financial_reports` | Remove legacy reports |
| 015 | `add_debts_and_consignment` | Debt & consignment tables |
| 016 | `grant_debt_consignment_permissions` | RLS for debt/consignment |
| 017 | `consignment_two_models` | Reseller & daily models |
| 018 | `enable_realtime_consignment` | Realtime subscriptions |
| 019 | `fix_categories_unique` | Category uniqueness |
| 020 | `migrate_debt_to_reseller` | Debt migration |
| 021 | `integrate_debt_transactions` | Debt transaction integration |

</details>

<br />

---

<br />

## 📦 Packages

| Package | Purpose | Why This One |
|:--------|:--------|:-------------|
| `flutter_riverpod` | State management | Compile-safe, testable, no context needed |
| `supabase_flutter` | Backend integration | Open-source, excellent Flutter SDK |
| `flutter_dotenv` | Environment config | Simple `.env` file loading |
| `connectivity_plus` | Network detection | Cross-platform connectivity status |
| `flutter_svg` | SVG rendering | Best SVG support for Flutter |
| `fl_chart` | Charts & graphs | Beautiful, customizable, performant |
| `image_picker` | Camera/gallery | Native image selection |
| `google_fonts` | Typography | Runtime font loading, no bundling |
| `intl` | Formatting | Indonesian locale support |
| `sentry` | Crash reporting | Industry-standard error tracking |
| `flutter_local_notifications` | Notifications | Reliable local reminders |
| `shared_preferences` | Local storage | Simple key-value persistence |
| `path_provider` | File paths | Platform-specific directories |
| `timezone` | Timezone data | Accurate notification scheduling |

<br />

---

<br />

## ⚡ Performance

| Optimization | How It's Implemented |
|:-------------|:---------------------|
| 📄 **Pagination** | `PaginatedListNotifier` for transactions, debts, consignments |
| 💾 **Query Caching** | `QueryCache` with configurable TTL reduces API calls |
| 🦥 **Lazy Loading** | On-demand screen initialization |
| 🔒 **Const Widgets** | Extensive `const` usage minimizes rebuilds |
| 📊 **Chart Optimization** | Efficient data points for smooth rendering |
| 🖼️ **Image Optimization** | SVG for QRIS (resolution-independent) |
| 🛡️ **Error Boundaries** | `GlobalErrorBoundary` prevents cascade crashes |
| 🔄 **Zone Handling** | Catch unhandled async errors gracefully |

<br />

---

<br />

## 🔒 Security

| Measure | Implementation |
|:--------|:---------------|
| 🔐 **Row Level Security** | PostgreSQL RLS — tenants cannot access each other's data |
| 🎭 **Role-Based Access** | Owner / Manager / Staff with distinct permissions |
| 🔑 **Environment Variables** | Secrets in `.env` (gitignored) |
| 🌐 **HTTPS Only** | All Supabase communication over TLS |
| ✅ **Input Validation** | `ErrorHandler.classify()` for typed errors |
| 🎫 **JWT Tokens** | Supabase Auth with automatic refresh |
| 🐛 **Crash Reporting** | Sentry with sanitized error data |

<br />

---

<br />

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

<details>
<summary><strong>📊 Test Structure</strong></summary>

<br />

```
test/
└── widget_test.dart        # Smoke test for SheressApp
```

> The test suite is currently minimal. Expanding coverage is on the roadmap.

</details>

<br />

---

<br />

## 📦 Build

### Android APK

```bash
# Debug
flutter build apk --debug

# Release
flutter build apk --release

# Split by ABI (recommended)
flutter build apk --split-per-abi
```

### Android App Bundle

```bash
flutter build appbundle --release
```

### Web

```bash
# Standard build
flutter build web --release

# With base href
flutter build web --base-href="/sheress/"
```

### Windows

```bash
flutter build windows --release
```

<br />

---

<br />

## 🗺️ Roadmap

- [x] ✅ Authentication (username login)
- [x] ✅ Role-based access (Owner / Manager / Staff)
- [x] ✅ Multi-business management
- [x] ✅ Transaction tracking (income/expense)
- [x] ✅ Financial dashboard with charts
- [x] ✅ QRIS payment integration
- [x] ✅ Debt & consignment management
- [x] ✅ Dark / Light theme
- [x] ✅ Offline detection overlay
- [x] ✅ Sentry crash reporting
- [x] ✅ Local notifications
- [x] ✅ P&L financial reports
- [ ] 🔲 Push notifications (FCM)
- [ ] 🔲 Export reports to PDF
- [ ] 🔲 Multi-language support (i18n)
- [ ] 🔲 Biometric authentication
- [ ] 🔲 Receipt scanning (OCR)
- [ ] 🔲 Realtime sync (Supabase Realtime)
- [ ] 🔲 Unit & widget tests (80%+ coverage)
- [ ] 🔲 CI/CD pipeline (GitHub Actions)
- [ ] 🔲 iOS support

<br />

---

<br />

## ❓ FAQ

<details>
<summary><strong>Why Supabase instead of Firebase?</strong></summary>

<br />

Supabase provides a ** PostgreSQL database ** with ** Row Level Security **, which is perfect for multi -tenant apps. It's open - source, has excellent Flutter support, and the free tier is generous.

</details>

<details>
<summary><strong>Why Riverpod over Bloc or GetX?</strong></summary>

<br />

Riverpod is ** compile - safe **, requires ** no BuildContext **, and has excellent testability. It's the evolution of Provider with better developer experience.

</details>

<details>
<summary><strong>Can I use this app offline?</strong></summary>

<br />

Sheress detects network connectivity and shows an offline overlay. Full offline mode with local database sync is planned for v2.

</details>

<details>
<summary><strong>How does multi-tenancy work?</strong></summary>

<br />

Each user is assigned to one or more businesses with a specific role (Owner, Manager, Staff). PostgreSQL Row Level Security ensures users can only access data for their assigned businesses.

</details>

<details>
<summary><strong>Is this production-ready?</strong></summary>

<br />

Yes. The app uses Sentry for crash reporting, proper error handling, RLS for security, and follows Clean Architecture principles. It's actively developed and used.

</details>

<br />

---

<br />

## 🤝 Contributing

Contributions are welcome! Here's how:

### 1. Fork & Clone

```bash
git clone https://github.com/your-username/sheress.git
cd sheress
```

### 2. Create Branch

```bash
git checkout -b feature/amazing-feature
```

### 3. Commit (Conventional Commits)

```bash
git commit -m "feat: add amazing feature"
git commit -m "fix: resolve login issue"
git commit -m "docs: update README"
```

### 4. Push & PR

```bash
git push origin feature/amazing-feature
```

Then open a Pull Request on GitHub.

### Commit Types

| Type | Description |
|:-----|:------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation |
| `style` | Formatting (no code change) |
| `refactor` | Code restructuring |
| `test` | Adding tests |
| `chore` | Maintenance tasks |

<br />

---

<br />

## 📄 License

This project is licensed under the **MIT License**.

```
MIT License

Copyright (c) 2026 Sheress

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject
to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

<br />

---

<br />

## 👨‍💻 Author

<div align="center">

**Built with ❤️ by**

<br />

[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/username)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/username)
[![Portfolio](https://img.shields.io/badge/Portfolio-000000?style=for-the-badge&logo=vercel&logoColor=white)](https://yourportfolio.com)
[![Email](https://img.shields.io/badge/Email-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:your@email.com)

</div>

<br />

---

<br />

## 🙏 Acknowledgements

Built with these amazing technologies:

- [Flutter](https://flutter.dev) — Beautiful native apps in record time
- [Supabase](https://supabase.com) — Open source Firebase alternative
- [Riverpod](https://riverpod.dev) — Simple, compile-safe state management
- [fl_chart](https://flchart.dev) — Powerful Flutter chart library
- [Sentry](https://sentry.io) — Application monitoring & error tracking
- [Google Fonts](https://fonts.google.com) — Inter font family
- [Material Design 3](https://m3.material.io) — Design system

<br />

---

<br />

<div align="center">

**Made with 🇮🇩 by Indonesian Developer**

<br />

⭐ **Star this repo if you find it useful!**

<br />

<sub>

[Back to Top](#-quick-overview)

</sub>

</div>
