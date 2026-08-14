# 📱 Mangan Group Mobile App

Aplikasi mobile untuk sistem absensi dan manajemen tim Mangan Group. Built with Flutter + Supabase.

---

## 🚀 Quick Links

| Documentation | Description |
|---------------|-------------|
| **[🚀 Release System Guide](README_RELEASE_SYSTEM.md)** | **← START HERE for releasing new versions** |
| [Setup Development](app/README.md) | Flutter app development setup |
| [Auto-Update Guide](app/AUTO_UPDATE_GUIDE.md) | In-app update system documentation |
| [GitHub Actions Guide](app/GITHUB_ACTIONS_RELEASE_GUIDE.md) | Complete CI/CD workflow documentation |

---

## ⚡ Quick Release

```powershell
# Bump version in app/pubspec.yaml
# version: 1.2.3+6 → 1.2.4+7

# Create & push tag
git tag v1.2.4
git push origin v1.2.4

# Done! APK auto-builds & releases in 5-10 minutes
```

👉 **[Full Release Guide →](README_RELEASE_SYSTEM.md)**

---

## 📦 Project Structure

```
ManganSage-chat-apps-/
├── .github/
│   └── workflows/
│       └── release-apk.yml          # CI/CD workflow (auto-build & release)
│
├── app/                             # Flutter mobile app
│   ├── lib/                         # Source code
│   ├── android/                     # Android config
│   ├── pubspec.yaml                 # Dependencies & version
│   └── ...
│
├── README_RELEASE_SYSTEM.md         # 🚀 Release documentation (read this!)
└── README.md                        # This file
```

---

## 🎯 Features

### **Mobile App (Flutter):**
- ✅ Attendance system dengan photo/text submission
- ✅ Real-time sync dengan Supabase
- ✅ Push notifications (FCM)
- ✅ In-app auto-update system
- ✅ Offline support
- ✅ Dark/Light theme

### **CI/CD Automation:**
- ✅ GitHub Actions auto-build
- ✅ APK hosted on GitHub Releases (unlimited storage)
- ✅ SHA-256 security verification
- ✅ Auto-update Supabase database
- ✅ OTA updates to users

---

## 🔧 Development Setup

### **Prerequisites:**
- Flutter SDK 3.12+
- Android Studio / VS Code
- Git

### **Quick Start:**

```bash
# Clone repo
git clone https://github.com/galangpramudito/ManganSage-chat-apps-.git
cd ManganSage-chat-apps-/app

# Install dependencies
flutter pub get

# Setup environment
cp .env.example .env
# Edit .env dengan Supabase credentials

# Run
flutter run
```

**Detailed setup:** See [app/README.md](app/README.md)

---

## 🚀 Releasing New Version

**See:** [**README_RELEASE_SYSTEM.md**](README_RELEASE_SYSTEM.md) for complete guide.

**Quick summary:**
1. Bump `version` in `app/pubspec.yaml`
2. `git tag v1.2.4 && git push origin v1.2.4`
3. Wait 5-10 minutes
4. APK auto-uploaded, database auto-updated, users auto-notified ✅

---

## 📊 Monitoring

- **GitHub Actions:** https://github.com/galangpramudito/ManganSage-chat-apps-/actions
- **Releases:** https://github.com/galangpramudito/ManganSage-chat-apps-/releases
- **Supabase Dashboard:** https://supabase.com/dashboard

---

## 🔒 Security

- ✅ SHA-256 APK integrity verification
- ✅ Secure token storage (flutter_secure_storage)
- ✅ HTTPS-only communication
- ✅ Row Level Security (RLS) di Supabase
- ✅ Secrets managed via GitHub Secrets

---

## 🐛 Troubleshooting

**Common issues:**

1. **Workflow tidak trigger?** → Check tag format (`v1.2.3` with 'v' prefix)
2. **Build failed?** → Check Actions logs for error details
3. **Update tidak muncul?** → Check build_number incremented correctly

**Full troubleshooting guide:** [README_RELEASE_SYSTEM.md#troubleshooting](README_RELEASE_SYSTEM.md#troubleshooting)

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [README_RELEASE_SYSTEM.md](README_RELEASE_SYSTEM.md) | **Main release guide** |
| [app/AUTO_UPDATE_GUIDE.md](app/AUTO_UPDATE_GUIDE.md) | In-app update system |
| [app/GITHUB_ACTIONS_RELEASE_GUIDE.md](app/GITHUB_ACTIONS_RELEASE_GUIDE.md) | CI/CD deep dive |
| [app/UPDATE_SYSTEM_IMPROVEMENTS.md](app/UPDATE_SYSTEM_IMPROVEMENTS.md) | Future enhancements |
| [app/AUDIT_REPORT_2026-08-14.md](app/AUDIT_REPORT_2026-08-14.md) | Security audit report |

---

## 🤝 Contributing

1. Create feature branch: `git checkout -b feature/amazing-feature`
2. Commit changes: `git commit -m "Add amazing feature"`
3. Push branch: `git push origin feature/amazing-feature`
4. Create Pull Request

---

## 📝 Changelog

### **v1.2.3** (2026-08-14)
- ✅ Implemented GitHub Actions CI/CD
- ✅ Auto-release system with unlimited storage
- ✅ SHA-256 APK verification
- ✅ Automated Supabase database updates

**Full history:** [Releases](https://github.com/galangpramudito/ManganSage-chat-apps-/releases)

---

## 📞 Support

- **Issues:** https://github.com/galangpramudito/ManganSage-chat-apps-/issues
- **Contact:** Development team

---

## 📄 License

Private - Mangan Group Internal Use Only

---

**Built with ❤️ for Mangan Group**  
**Last Updated:** 2026-08-14
