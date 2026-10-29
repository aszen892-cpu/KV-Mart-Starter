# KV Mart — Flutter + Firebase Starter

Starter foundation for:
- Flutter customer app (Android, with Web support available through FlutterFire)
- Firebase Authentication with Google only
- Cloud Firestore product catalog
- Separate Flutter Web admin starter
- Firestore Security Rules

## 1. Prerequisites
Install Flutter, Android Studio (or another Flutter IDE), Node.js, Firebase CLI, and FlutterFire CLI.

```bash
flutter doctor
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

## 2. Create the customer app
From the extracted project folder:

```bash
flutter create customer_app --org com.kvmart01
```

Copy `customer_app/lib/main.dart` from this starter over the generated file and replace `customer_app/pubspec.yaml` with the starter `customer_app/pubspec.yaml`.

Then run:

```bash
cd customer_app
flutter pub get
flutterfire configure --project=kv-mart
```

Select Android (and any other platforms you intend to support). Check the Android package name is exactly `com.kvmart01`. FlutterFire generates `lib/firebase_options.dart`; do not hand-write it.

## 3. Firebase Console setup
In Firebase Console for project `kv-mart`:
1. Authentication → Sign-in method → enable Google.
2. Add your Android app with package `com.kvmart01` if it is not already registered.
3. Add the SHA-1 and SHA-256 fingerprints for your debug/release signing keys in Project settings → Your apps.
4. Create a Cloud Firestore database in production mode.
5. Add a product document to `products`, e.g.:

```json
{
  "name": "Premium Rice 5kg",
  "description": "Everyday staple",
  "categoryId": "grocery",
  "sellerId": "approved-seller-uid",
  "price": 399,
  "mrp": 499,
  "stock": 25,
  "imageUrl": "",
  "isActive": true,
  "createdAt": "<use a Firestore Timestamp in the console>"
}
```

For initial UI testing, a product needs `name`, `price`, `mrp`, `stock`, `isActive`; `description`, `categoryId`, `sellerId`, `imageUrl`, `createdAt` are recommended.

## 4. Install and run the app

```bash
flutter run
```

Google Sign-In uses the native Google account picker. If sign-in fails, verify Google is enabled in Firebase Authentication and SHA fingerprints are configured.

## 5. Deploy Firestore rules
From this starter root, make sure `.firebaserc` points at the intended project, then:

```bash
firebase deploy --only firestore:rules
```

Review `firestore.rules` carefully before production. Rules are security boundaries; do not use open rules such as `allow read, write: if true`.

## 6. Admin Web starter
Create the separate web app:

```bash
flutter create admin_web
```

Copy `admin_web/lib/main.dart` and `admin_web/pubspec.yaml` from this starter, then:

```bash
cd admin_web
flutter pub get
flutterfire configure --project=kv-mart
flutter run -d chrome
```

Configure Firebase Web app in the same project when prompted. The admin UI requires `users/{your-auth-uid}.role == "admin"`.

### Bootstrap the first admin safely
1. Sign in once using the admin Google account so the app creates `users/{uid}`.
2. In Firebase Console → Firestore, locate `users/{uid}`.
3. Manually set `role` to `admin` using a trusted project owner account.
4. Do not expose any client-side UI or rule that lets users set their own role.

The provided admin starter is a gated shell and product-list view, not yet a complete CRUD management portal.

## 7. Firestore schema starter
- `users/{uid}` — profile fields and trusted role
- `products/{productId}` — product catalog
- `categories/{categoryId}` — category metadata
- `banners/{bannerId}` — home banner metadata
- `users/{uid}/cart/{productId}` — per-user cart items
- `users/{uid}/wishlist/{productId}` — per-user wishlist items
- `orders/{orderId}` — server-created order records
- `sellers/{uid}` — seller profile/KYC status (sensitive fields should be restricted)
- `payoutRequests/{requestId}` — server/admin-controlled payout workflow

## Production safety checklist
- Implement checkout and payment verification with trusted Cloud Functions or a trusted server.
- Never trust prices, discounts, stock, order status, commission, or wallet totals sent by the client.
- Do not store bank details unless necessary; restrict access tightly and follow applicable legal/security requirements.
- Add App Check, abuse controls, backups, monitoring, and Firestore Rules Emulator tests.
- Use Cloud Storage rules for uploaded product/review images; this starter does not enable arbitrary uploads.
- For web deployment, configure authorized domains and review the Google sign-in flow.
