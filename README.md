# PFMS Project — Sprint 1 & 2

Two apps, one folder, so you can open/work on both at the same time.

```
pfms-project/
├── pfms-backend/   Laravel API + web admin  (see pfms-backend/README.md)
└── mobile/         Flutter mobile app        (see mobile/README.md)
```

## Run both together
Open two terminals:

**Terminal 1 — backend**
```bash
cd pfms-project/pfms-backend
php artisan serve
```

**Terminal 2 — mobile**
```bash
cd pfms-project/mobile
flutter run
```

Start the backend first — the mobile app checks the API on launch (auto-login),
so it needs something to talk to. Make sure `kApiBaseUrl` in
`mobile/lib/services/api_service.dart` points at wherever the backend is
actually running (see mobile/README.md for emulator vs. physical device notes).

Each subfolder has its own setup README with full install steps.
