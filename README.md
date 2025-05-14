
# 🛒 Flutter E-Commerce Application – Assignment for ParuSoft Solutions

---

## 🙏 Thank You!

I would like to express my sincere gratitude to **ParuSoft Solutions Pvt Ltd** for the opportunity to work on this assignment. It has been a valuable experience where I got to explore key concepts of Flutter, backend integration, and clean architecture in a real-world application context.

---

## 📱 Project Overview

This is a full-featured **Flutter-based e-commerce application** developed as part of the technical assignment. The app includes:

- Dynamic product catalog with grid/list view, filtering, sorting, and search
- Product detail pages with image galleries, descriptions, variants, and reviews
- Shopping cart with product variant selection
- Complete multi-step checkout flow with order summary, shipping, and payment
- Clean and modular architecture (data, domain, and presentation layers)
- Responsive design suitable for both phones and tablets
- Smooth transitions and error/loading state handling
- Unit and widget tests for key functionalities

---

## 🚀 Getting Started

Below are step-by-step instructions to run both the backend and the Flutter frontend without any issues.

---

## 🔧 Backend Setup (Node.js + Express)

> Ensure you have Node.js (v14 or above) and npm installed on your system.

1. **Navigate to the backend folder**:
   ```bash
   cd backend
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Start the development server**:
   ```bash
   npm run dev
   ```

> The server will run on port **8005**. Make sure this port is free before running.

---

## 📲 Flutter Frontend Setup

> Requirements:
- Flutter SDK installed (`flutter --version` should show >= 3.16)
- Android Studio or VS Code with Flutter extension
- Android device or emulator
- ADB (Android Debug Bridge) must be properly installed and accessible in your system's PATH

### Step-by-Step Guide:

1. **Navigate to your Flutter app folder**:
   ```bash
   cd parusoft_shopping_app
   ```

2. **Install required dependencies**:
   ```bash
   flutter pub get
   ```

3. **Connect your Android phone via USB**:
   - Enable **Developer Mode** on your phone.
   - Enable **USB Debugging** from Developer Options.

4. **Check device connectivity**:
   ```bash
   flutter devices
   ```

5. **Set up port forwarding using ADB**:
   ```bash
   adb reverse tcp:8005 tcp:8005
   ```

6. **Run the Flutter app**:
   ```bash
   flutter run
   ```

---

## 🧰 How to Install ADB (Android Debug Bridge)

### For macOS/Linux:
```bash
brew install android-platform-tools
```

### For Windows:
- Install Android Studio
- Add `platform-tools` to your system’s PATH
- Verify installation:
  ```bash
  adb devices
  ```

---

## 📁 Project Structure

```
├── backend/
├── parusoft_shopping_app/
│   ├── lib/
│   │   ├── constants/
│   │   │   └── routes.dart
│   │   ├── models/
│   │   │   └── product.dart
│   │   ├── services/
│   │   │   ├── product_services.dart
│   │   │   └── user_services.dart
│   │   ├── views/
│   │   │   ├── Cart_view.dart
│   │   │   ├── Checkout_Page_View.dart
│   │   │   ├── Confirmation_Page_View.dart
│   │   │   ├── HomePage.dart
│   │   │   ├── Payment_Page_view.dart
│   │   │   ├── ProductDetailPage.dart
│   │   │   ├── Shipping_Page_View.dart
│   │   │   └── SignIn_SignUp_View.dart
│   │   └── main.dart
│   └── test/
```

---

## ✅ Features Summary

- ✅ Product Catalog with Filters, Search, Sort
- ✅ Product Details with Variants
- ✅ Persistent Cart
- ✅ Checkout Flow
- ✅ Clean Architecture
- ✅ Responsive UI
- ✅ Unit and Widget Testing

---

## 📤 Submission Info

- Report uploaded to Google Drive
- Submitted via: https://forms.gle/p8F8mYHzfAzPvUFp9

---

## 📬 Contact

- **Email:** himanshu.mishra0913@gmail.com

---

## ✨ Final Words

Thank you once again to ParuSoft for the opportunity. Looking forward to your feedback!
