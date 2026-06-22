# Canvas-Link (WallpaperSync) 🖼️✨

> A seamless, cross-platform wallpaper synchronization system that brings your favorite Pinterest boards right to your screens every single day.

Canvas-Link ensures that your desktop and mobile devices are always kept fresh with your curated Pinterest inspiration. Simply link your account, pick a board, and let the system handle the rest quietly in the background!

## 🌟 Features

- **Automated Daily Sync**: Automatically fetches and sets a new wallpaper from your Pinterest boards every day.
- **Cross-Platform**: Support for both Android smartphones and Windows PCs.
- **Secure Authentication**: Uses modern OAuth flows to securely link your Pinterest account without ever exposing your credentials.
- **Battery & Resource Friendly**: Background tasks are intelligently scheduled using modern OS APIs (WorkManager on Android, native schedulers on PC) to avoid draining your battery or hogging CPU.
- **Support the Developer**: Integrated Razorpay system for seamless donations directly within the mobile app.

---

## 🏗️ Project Architecture

This repository is organized into three distinct, decoupled components:

### 1. 📱 Mobile Client (`/mobile-client`)
The Android companion application built using **Flutter**.
- **Tech Stack**: Flutter, Dart.
- **Key Packages**: `workmanager` (for background fetching), `wallpaper_manager_plus` (for setting the wallpaper), `razorpay_flutter` (donations), and `flutter_secure_storage`.
- **CI/CD**: Fully automated GitHub Actions workflow (`build-android.yml`) that builds and uploads the release APK on every push.

### 2. 💻 PC Client (`/pc-client`)
The desktop synchronization utility built using **Python**.
- **Tech Stack**: Python.
- **Key Modules**: Custom API clients, background schedulers (`scheduler.py`), and a standalone executable builder (`build.bat` via PyInstaller).
- Runs silently on boot to keep your desktop environment feeling fresh.

### 3. ☁️ Backend (`/backend`)
The high-performance edge API built on **Cloudflare Workers**.
- **Tech Stack**: TypeScript, Cloudflare Workers, Hono/Express (Node.js ecosystem).
- Safely handles the Pinterest OAuth exchange flow, secure token management, and curates API responses for the clients.

---

## 🚀 Getting Started

### Prerequisites
- Node.js & NPM (for Backend)
- Flutter SDK & Android Studio (for Mobile Client)
- Python 3.9+ (for PC Client)

### Setup Instructions

**Backend**
1. Navigate to the backend directory: `cd backend`
2. Install dependencies: `npm install`
3. Add your Pinterest API keys to your `wrangler.toml` or environment secrets.
4. Deploy to your Cloudflare account: `npx wrangler deploy`

**Mobile Client**
1. Navigate to the mobile directory: `cd mobile-client`
2. Fetch packages: `flutter pub get`
3. Ensure your local `local.properties` contains any required API/Backend URLs.
4. Run on your device: `flutter run --release`

**PC Client**
1. Navigate to the PC directory: `cd pc-client`
2. Install Python requirements: `pip install -r requirements.txt`
3. Execute locally: `python main.py`
4. Build Executable: Run `build.bat` to create a standalone `.exe`.

## 🤝 Contributing
Contributions, issues, and feature requests are welcome!
Feel free to check out the [issues page](../../issues) to get started.

## 📄 License
This project is open-source and available under the [MIT License](LICENSE).
