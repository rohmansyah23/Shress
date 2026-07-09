# AGENTS.md — Sheress

## Project Overview

Multi-tenant financial reporting app. Flutter + Supabase + Riverpod.

## State Management

- **Riverpod 2.x** — `StateNotifierProvider` for auth, `FutureProvider` for async data
- Never use `setState` for global state; use providers
- Use `ref.read` for one-time actions, `ref.watch` for reactive rebuilds

## Code Conventions

- **No comments** in code unless documenting a public API
- **Indonesian** for user-facing strings, **English** for code
- Follow existing patterns in neighboring files
- Use `AppConstants.*` for magic strings/numbers
- Use `AppTheme.*` for styling (never raw `TextStyle`)
- Use `FormatHelpers.rupiah()` / `FormatHelpers.displayDate()` for formatting

## Naming

| Item | Convention | Example |
|---|---|---|
| Files | `snake_case` | `login_screen.dart` |
| Classes | `PascalCase` | `LoginScreen` |
| Providers | `camelCase` + `Provider` suffix | `authProvider` |
| Functions | `camelCase` | `_handleLogin()` |
| Private members | `_camelCase` | `_isLoading` |
| Folders | `snake_case` | `core/constants/` |

## Architecture Rules

- **`lib/core/`** — utilities only (no Flutter widgets except shared widgets)
- **`lib/data/`** — data layer (models, services, repositories)
- **`lib/providers/`** — Riverpod providers
- **`lib/ui/`** — screens per feature folder
- Screens import providers, but providers never import screens
- `SupabaseService` is the single source of truth for remote data

## Common Patterns

### Error Handling

```dart
ErrorHandler.classify(error).userMessage  // User-friendly Indonesian message
```

Always wrap async operations; never let raw errors reach the UI.

### Adding a Feature

1. Model in `data/local/models/`
2. Query method in `data/remote/supabase_service.dart`
3. Provider in `providers/`
4. Screen in `ui/<feature>/`

## Commands

```bash
flutter pub get              # Install dependencies
flutter analyze              # Static analysis (must pass before committing)
flutter test                 # Run tests
flutter run                  # Run on connected device
dart run flutter_launcher_icons  # Generate app icons
```

## Git

- Use descriptive commit messages in Indonesian or English
- Run `flutter analyze` before every commit
- No secrets in code — use `.env` (git-ignored)

## Database

5 Supabase migrations in `supabase/migrations/`. Run via Dashboard SQL Editor or CLI:

```bash
supabase link --project-ref <ref>
supabase db push
```
