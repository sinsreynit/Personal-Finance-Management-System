# PFMS Mobile (Flutter) — Sprint 1 & 2

A `flutter create` skeleton (android/ios/web platform folders, assets, tests)
couldn't be generated here since Flutter isn't available in this sandbox —
this is the `lib/` app code + `pubspec.yaml` to drop into a fresh project.

## Setup
1. `flutter create pfms_mobile`
2. Replace the generated `lib/` folder and `pubspec.yaml` with these files.
3. `flutter pub get`
4. Open `lib/services/api_service.dart` and set `kApiBaseUrl` to match your
   Laravel backend (defaults to the Android emulator alias `10.0.2.2`).
5. `flutter run`

## What's included
**Sprint 1**
- Register / Login / Logout (`screens/auth`, token stored via `shared_preferences`)
- Profile view/edit + Change Password (`screens/profile`)
- Category management, income & expense tabs (`screens/categories`)

**Sprint 2**
- Add/Edit/Delete income & expense (single form, type toggle) (`screens/transactions/transaction_form_screen.dart`)
- Transaction list with swipe-to-delete
- Search/filter by keyword and type (`transactions_screen.dart`)

State is managed with `provider` (`AuthProvider`, `FinanceProvider`); all API
calls go through `ApiService`, which attaches the Sanctum bearer token
automatically once logged in.
