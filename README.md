# tomato_deeplio

[![pub.dev](https://img.shields.io/pub/v/tomato_deeplio.svg)](https://pub.dev/packages/tomato_deeplio)
[![GitHub](https://img.shields.io/badge/GitHub-ChaiwaT--Sun%2Ftomato__deeplio-blue?logo=github)](https://github.com/ChaiwaT-Sun/tomato_deeplio)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/ChaiwaT-Sun/tomato_deeplio/blob/main/LICENSE)

A production-ready Flutter plugin for **App Links**, **Universal Links**, **Deep Links**, **Deferred Deep Links**, and **dynamic routing** — a modern, self-hosted replacement for Firebase Dynamic Links.

---

## Features

| Feature | Status |
|---|---|
| Android App Links (HTTPS verified) | ✅ |
| iOS Universal Links | ✅ |
| Custom URI scheme deep links | ✅ |
| Deferred deep links (no Firebase required) | ✅ |
| Dynamic route matching (`:param` syntax) | ✅ |
| Link generator (HTTPS / custom scheme / QR) | ✅ |
| Analytics adapter interface | ✅ |
| Firebase Hosting compatible | ✅ |
| Web redirect page with App Store / Play Store fallback | ✅ |
| Null-safe, Dart 3 | ✅ |

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  tomato_deeplio: ^1.0.0
```

```bash
flutter pub get
```

---

## Quick Start

```dart
import 'package:tomato_deeplio/tomato_deeplio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final deeplio = TomatoDeeplio();

  await deeplio.initialize(
    config: TomatoDeeplioConfig(
      domain: 'links.example.com',        // your custom domain
      uriScheme: 'myapp',                 // your URI scheme
      androidPackageName: 'com.example.myapp',
      iosBundleId: 'com.example.myapp',
      iosAppStoreId: '123456789',
      fallbackUrl: 'https://example.com',
      enableDeferredLinks: true,
      debugMode: true,
    ),
    routes: [
      RouteDefinition(
        name: 'product',
        pattern: '/product/:id',
        handler: (match) {
          print('Product ID: ${match.pathParams['id']}');
        },
      ),
    ],
  );

  runApp(MyApp());
}
```

---

## Listen for Incoming Links

```dart
final deeplio = TomatoDeeplio();

// Raw link stream
deeplio.linkStream.listen((link) {
  print(link.path);           // /product/123
  print(link.queryParams);    // {ref: USER001}
  print(link.isDeferred);     // true/false
  print(link.source);         // utm_source
  print(link.campaign);       // utm_campaign
});

// Result stream — includes route match info
deeplio.resultStream.listen((result) {
  if (result.hasRoute) {
    print(result.routeMatch!.routeName);   // 'product'
    print(result.routeMatch!.allParams);   // {id: 123, ref: USER001}
  }
});
```

---

## Generate Links

```dart
final deeplio = TomatoDeeplio();

// HTTPS smart link
final url = deeplio.createLink(
  path: '/product/123',
  params: {'ref': 'USER001'},
  utmSource: 'email',
  utmCampaign: 'launch',
);
// → https://links.example.com/product/123?ref=USER001&utm_source=email&utm_campaign=launch

// Custom URI scheme deep link
final deepLink = deeplio.createDeepLink(
  path: '/product/123',
  params: {'ref': 'USER001'},
);
// → myapp://product/123?ref=USER001

// QR-compatible link
final qrUrl = deeplio.createQrLink(
  path: '/promo/SUMMER24',
  utmCampaign: 'summer_sale',
);
// → https://links.example.com/promo/SUMMER24?utm_source=qr&utm_medium=qr_code&utm_campaign=summer_sale
```

---

## Route Matching

Routes use `:paramName` syntax. First match wins.

```dart
deeplio.router.addRoutes([
  RouteDefinition(
    name: 'product',
    pattern: '/product/:id',
    handler: (match) {
      final id = match.pathParams['id'];       // from path
      final ref = match.queryParams['ref'];    // from query string
      // Navigate...
    },
  ),
  RouteDefinition(
    name: 'category_item',
    pattern: '/category/:slug/item/:id',
    handler: (match) {
      print(match.allParams); // merged: path params + query params
    },
  ),
  RouteDefinition(
    name: 'promo',
    pattern: '/promo/:code',
  ),
]);
```

---

## Deferred Deep Links

Sends users to the right screen even if they install the app **after** clicking the link.

```
User clicks link
  → Web redirect page stores URL + token in localStorage
  → User installs app
  → App opens for first time
  → TomatoDeeplio recovers the original URL automatically
  → Navigates to correct screen
```

```dart
// Recovered deferred link fires automatically via linkStream.
// Or check manually:
final link = await deeplio.getPendingDeferredLink();
if (link != null) {
  print('Deferred: ${link.path}');
}
```

---

## Analytics

Plug in any analytics backend by implementing `AnalyticsAdapter`:

```dart
class MyAnalyticsAdapter implements AnalyticsAdapter {
  @override
  Future<void> track(SmartLinkAnalyticsEvent event) async {
    // Send to Firebase, Amplitude, Mixpanel, etc.
    await FirebaseAnalytics.instance.logEvent(
      name: event.type.name,
      parameters: event.toMap().cast<String, Object>(),
    );
  }
}

await deeplio.initialize(
  config: config,
  analyticsAdapters: [MyAnalyticsAdapter()],
);
```

### Event types

| Event | Fired when |
|---|---|
| `linkReceived` | Any incoming link is parsed |
| `deferredLinkRecovered` | First-open deferred link replayed |
| `routeMatched` | Link matched a route definition |
| `routeNotMatched` | No route matched |
| `linkCreated` | `createLink()` was called |
| `appOpened` | App opened from a link |

---

## Android Setup

### 1. AndroidManifest.xml

Add to your `<activity>` in `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- App Links — HTTPS verified, no chooser dialog (Android 6+) -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="https" android:host="links.example.com"/>
</intent-filter>

<!-- Custom URI scheme -->
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="myapp"/>
</intent-filter>
```

### 2. assetlinks.json

Host at `https://links.example.com/.well-known/assetlinks.json`:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.example.myapp",
    "sha256_cert_fingerprints": ["AA:BB:CC:..."]
  }
}]
```

Get your SHA-256 fingerprint:

```bash
# Debug
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android

# Release
keytool -list -v -keystore your-release.keystore
```

### 3. Verify

```bash
adb shell pm get-app-links com.example.myapp
# Force re-verify
adb shell pm verify-app-links --re-verify com.example.myapp
```

---

## iOS Setup

### 1. Info.plist

Add to `ios/Runner/Info.plist`:

```xml
<!-- Custom URI scheme -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>myapp</string></array>
  </dict>
</array>
```

### 2. Associated Domains (Xcode)

**Signing & Capabilities → + Capability → Associated Domains**

Add: `applinks:links.example.com`

### 3. apple-app-site-association

Host at `https://links.example.com/.well-known/apple-app-site-association`
(no `.json` extension, `Content-Type: application/json`):

```json
{
  "applinks": {
    "details": [{
      "appIDs": ["TEAMID.com.example.myapp"],
      "components": [{ "/": "/*" }]
    }]
  }
}
```

Replace `TEAMID` with your Apple Developer Team ID.

### 4. Verify

```bash
# Check AASA is reachable
curl -I https://links.example.com/.well-known/apple-app-site-association

# Test Universal Link on simulator
xcrun simctl openurl booted 'https://links.example.com/product/1'
```

> Universal Links only work on **real devices**, not the simulator.

---

## Firebase Hosting Setup

```bash
npm install -g firebase-tools
firebase login
firebase init   # select Hosting + Functions

cp -r web/* firebase/public/
firebase deploy
```

The included `firebase/firebase.json` handles:
- `/.well-known/*` served with correct `Content-Type`
- All paths → `index.html` (the redirect page)
- `/api/*` → Cloud Function (optional deferred link server)

---

## Web Redirect Page

The `web/index.html` included in this package:

1. Stores the current URL + install token in `localStorage` (deferred link)
2. Attempts to open the app via custom URI scheme
3. Falls back to **App Store** or **Play Store** if the app is not installed
4. Falls back to a custom URL if no store link is configured

---

## Folder Structure

```
tomato_deeplio/
├── lib/
│   ├── tomato_deeplio.dart          ← public barrel export
│   └── src/
│       ├── smart_links.dart         ← TomatoDeeplio main class
│       ├── smart_links_config.dart  ← TomatoDeeplioConfig
│       ├── models/
│       ├── router/
│       ├── analytics/
│       ├── services/
│       ├── platform/
│       └── exceptions/
├── android/
│   └── src/main/kotlin/ts/sun/tomato_deeplio/
│       └── TomatoDeeplioPlugin.kt
├── ios/
│   └── Classes/
│       └── TomatoDeeplioPlugin.swift
├── web/
│   ├── index.html
│   └── .well-known/
│       ├── apple-app-site-association
│       └── assetlinks.json
├── firebase/
│   ├── firebase.json
│   └── functions/index.js
└── example/
    └── lib/main.dart
```

---

## Migration from Firebase Dynamic Links

| Firebase Dynamic Links | tomato_deeplio |
|---|---|
| `FirebaseDynamicLinks.instance.onLink` | `deeplio.linkStream.listen()` |
| `getInitialLink()` | handled automatically in `initialize()` |
| `DynamicLinkParameters` | `deeplio.createLink(path, params)` |
| Deferred deep links | built-in, no Firebase needed |
| `PendingDynamicLinkData` | `deeplio.getPendingDeferredLink()` |

## Migration from Branch.io

| Branch.io | tomato_deeplio |
|---|---|
| `Branch.initSession` | `TomatoDeeplio().initialize()` |
| `Branch.subscribe` | `deeplio.linkStream.listen()` |
| `BranchUniversalObject.generateShortUrl` | `deeplio.createLink()` |
| `Branch.getLatestReferringParams` | `deeplio.getPendingDeferredLink()` |
| Custom analytics | `AnalyticsAdapter` interface |

---

## Security Considerations

- Use **HTTPS** for App Links and Universal Links — never HTTP in production.
- Validate `assetlinks.json` and AASA before going live — invalid files silently break verification.
- **Sanitise path params** before using in navigation or database queries.
- Deferred link tokens are **single-use** and expire after `deferredLinkMaxAge` (default 30 days).
- Custom URI schemes can be intercepted by other apps — use App Links / Universal Links for sensitive flows.
- Never put secrets in link parameters — they appear in server logs and analytics.

---

## Troubleshooting

### Android App Links not opening the app

1. `curl https://links.example.com/.well-known/assetlinks.json` — must return 200
2. SHA-256 fingerprint must match your signing key exactly
3. `android:autoVerify="true"` must be set in the intent-filter
4. Run `adb shell pm get-app-links com.example.myapp` to check verification status
5. Force re-verify: `adb shell pm verify-app-links --re-verify com.example.myapp`

### iOS Universal Links not working

1. AASA must be served with `Content-Type: application/json` (no `.json` extension)
2. Associated Domains entitlement must be enabled in Xcode
3. Team ID in AASA must match your Apple Developer account
4. Test on a **real device** — Universal Links do not work in the simulator
5. Use [Apple's AASA validator](https://search.developer.apple.com/appsearch-validation-tool/)

### Deferred links not recovering

1. `enableDeferredLinks: true` must be set in config
2. The web redirect page must have run before the app was installed
3. Check `localStorage` in browser DevTools for `_sl_deferred` key
4. Check that the token has not already been consumed

### Links not matching routes

1. Pattern uses `:paramName` for dynamic segments — e.g. `/product/:id`
2. Segment count must match exactly — `/product/:id` will not match `/product/123/details`
3. Routes are matched in registration order — put more specific patterns first
4. Enable `debugMode: true` to see matching logs in the console

---

## License

MIT — [ChaiwaT-Sun/tomato_deeplio](https://github.com/ChaiwaT-Sun/tomato_deeplio)
