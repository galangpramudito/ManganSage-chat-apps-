# mangansage

Mobile app untuk sistem absensi Mangan Group. Built with Flutter + Supabase.

---

## ⚡ Quick Links

- 📖 **[Quick Start: Update System](QUICK_START_UPDATE_SYSTEM.md)** - Fast reference untuk publish update
- 📋 **[Auto Update Guide](AUTO_UPDATE_GUIDE.md)** - Complete documentation
- 🔍 **[Audit Report (2026-08-14)](AUDIT_REPORT_2026-08-14.md)** - Latest security audit
- 💡 **[System Improvements](UPDATE_SYSTEM_IMPROVEMENTS.md)** - Roadmap & recommendations

---

## 🚀 Features

- ✅ **Supabase Integration** - Real-time sync dengan web dashboard
- ✅ **FCM Push Notifications** - Instant announcements & reminders
- ✅ **In-App Auto-Update** - OTA updates tanpa Play Store
- ✅ **Camera Attendance** - Submit photo proof langsung dari app
- ✅ **Offline Support** - Local notifications tetap jalan
- ✅ **Dark/Light Theme** - Auto-detect system preference
- ✅ **Security** - SHA-256 APK verification, secure token storage

---

## 📦 Tech Stack

- **Framework:** Flutter 3.12+
- **State Management:** Riverpod
- **Backend:** Supabase (PostgreSQL + Storage + Auth)
- **Notifications:** Firebase Cloud Messaging + flutter_local_notifications
- **Architecture:** Feature-based clean architecture

---

## 🛠️ Development Setup

### Prerequisites
- Flutter SDK 3.12+
- Android Studio / VS Code
- Supabase account

### Installation
```bash
# Clone & navigate
cd "app project/app"

# Install dependencies
flutter pub get

# Setup environment
cp .env.example .env
# Edit .env dengan Supabase credentials

# Run
flutter run
```

### First Time Build
```bash
# Generate code (freezed, riverpod, env)
flutter pub run build_runner build --delete-conflicting-outputs

# Build APK
flutter build apk --release
```

---

## 🚀 Deployment

### Publish Update to Users
```powershell
# Bump version di pubspec.yaml (e.g., 1.2.0+2 → 1.3.0+3)
# Then run:
.\publish_update.ps1
```

See [QUICK_START_UPDATE_SYSTEM.md](QUICK_START_UPDATE_SYSTEM.md) for details.

---

## 🔒 Security

- ✅ SHA-256 checksum verification untuk APK updates
- ✅ Secure token storage dengan flutter_secure_storage
- ✅ HTTPS-only communication
- ✅ RLS policies di Supabase

---

## 📚 Documentation

- [AUTO_UPDATE_GUIDE.md](AUTO_UPDATE_GUIDE.md) - In-app update system documentation
- [UPDATE_SYSTEM_IMPROVEMENTS.md](UPDATE_SYSTEM_IMPROVEMENTS.md) - Future improvements & roadmap
- [AUDIT_REPORT_2026-08-14.md](AUDIT_REPORT_2026-08-14.md) - Security audit report

---

## 🤝 Contributing

1. Create feature branch
2. Make changes
3. Test thoroughly
4. Submit PR with clear description

---

## 📞 Support

For issues or questions, contact development team.

---

**Built with ❤️ for Mangan Group**
