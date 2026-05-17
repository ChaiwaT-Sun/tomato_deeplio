# tomato_deeplio

[![pub.dev](https://img.shields.io/pub/v/tomato_deeplio.svg)](https://pub.dev/packages/tomato_deeplio)
[![GitHub](https://img.shields.io/badge/GitHub-ChaiwaT--Sun%2Fflutter__smart__links-blue?logo=github)](https://github.com/ChaiwaT-Sun/tomato_deeplio)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/ChaiwaT-Sun/tomato_deeplio/blob/main/LICENSE)

A production-ready Flutter package for **App Links**, **Universal Links**, **Deep Links**, **Deferred Deep Links**, and **dynamic routing** — a modern, self-hosted replacement for Firebase Dynamic Links.

---

## Features

| Feature | Status |
|---|---|
| Android App Links (HTTPS verified) | ✅ |
| iOS Universal Links | ✅ |
| Custom URI scheme deep links | ✅ |
| Deferred deep links (no Firebase) | ✅ |
| Dynamic route matching (`:param` syntax) | ✅ |
| Link generator (HTTPS / scheme / QR) | ✅ |
| Analytics adapter interface | ✅ |
| Firebase Hosting compatible | ✅ |
| Web redirect page with store fallback | ✅ |
| Null-safe, Dart 3 | ✅ |

---

## Folder Structure

```
tomato_deeplio/
├── lib/
│   ├── tomato_deeplio.dart          ← public barrel export
│   └── src/
│       ├── smart_links.dart              ← main TomatoDeeplio class
│       ├── smart_links_config.dart       ← TomatoDeeplioConfig
│       ├── models/
│       │   ├── smart_link.dart
│       │   ├── smart_link_result.dart
│       │   ├── deferred_link_data.dart
│       │   ├── route_match.dart
│       │   └── analytics_event.dart
│       ├── router/
│       │   ├── smart_link_router.dart
│       │   └── route_definition.dart
│       ├── analytics/
│       │   ├── analytics_adapter.dart
│       │   └── console_analytics_adapter.dart
│       ├── services/
│       │   ├── deferred_link_service.dart
│       │   ├── link_parser.dart
│       │   └── link_generator.dart
│       ├── platform/
│       │   ├── smart_links_platform_interface.dart
│       │   └── method_channel_smart_links.dart
│       └── exceptions/
│           └── smart_links_exception.dart
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml           ← intent-filters
│       └── kotlin/.../TomatoDeeplioPlugin.kt
├── ios/
│   └── Runner/
│       ├── TomatoDeeplioPlugin.swift
│       ├── AppDelegate.swift
│       └── Info.plist                    ← URL scheme + associated domains
├── web/
│   ├── index.html                        ← redirect page
│   └── .well-known/
│       ├── apple-app-site-association
│       └── assetlinks.json
├── firebase/
│   ├── firebase.json                     ← hosting + rewrites
│   └── functions/
│       └── index.js                      ← optional serverless deferred links
├── example/
│   └── lib/main.dart
└── test/
    └── smart_link_test.dart
```

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  tomato_deeplio: ^1.0.0
```

Then run:

```bash
flutter pub get
```

---

## Quick Start

```dart
import 'package:tomato_deeplio/tomato_deeplio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final smartLinks = TomatoDeeplio();

  await smartLinks.initialize(
    config: TomatoDeeplioConfig(
      domain: 'links.example.com',      // your custom domain
      uriScheme: 'myapp',               // your URI scheme
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
          // Navigate to product page
          print('Product ID: ${match.pathParams['id']}');
        },
      ),
    ],
  );

  // Listen for incoming links
  smartLinks.linkStream.listen((link) {
    print('Received: ${link.path}');
    print('Params: ${link.queryParams}');
    print('Deferred: ${link.isDeferred}');
  });

  // Or listen for results with route matching
  smartLinks.resultStream.listen((result) {
    if (result.hasRoute) {
      print('Route: ${result.routeMatch!.routeName}');
      print('All params: ${result.routeMatch!.allParams}');
    }
  });

  runApp(MyApp());
}
```

### Generate links

```dart
final smartLinks = TomatoDeeplio();

// HTTPS smart link
final url = smartLinks.createLink(
  path: '/product/123',
  params: {'ref': 'USER001'},
  utmSource: 'email',
  utmCampaign: 'launch',
);
// → https://links.example.com/product/123?ref=USER001&utm_source=email&utm_campaign=launch

// Custom URI scheme
final deepLink = smartLinks.createDeepLink(path: '/product/123');
// → myapp://product/123

// QR-compatible link
final qrUrl = smartLinks.createQrLink(
  path: '/promo/SUMMER24',
  utmCampaign: 'summer_sale',
);
// → https://links.example.com/promo/SUMMER24?utm_source=qr&utm_medium=qr_code&utm_campaign=summer_sale
```

---

## Android Setup

### 1. AndroidManifest.xml

The `AndroidManifest.xml` is already configured in this package. For your own app, add these intent-filters to your `<activity>`:

```xml
<!-- App Links (HTTPS verified — no chooser dialog) -->
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

Host this file at `https://links.example.com/.well-known/assetlinks.json`:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.example.myapp",
    "sha256_cert_fingerprints": ["YOUR:SHA256:FINGERPRINT"]
  }
}]
```

Get your SHA-256 fingerprint:

```bash
# Debug keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release keystore
keytool -list -v -keystore your-release.keystore
```

### 3. Verify App Links

```bash
adb shell pm get-app-links com.example.myapp
```

---

## iOS Setup

### 1. Info.plist

Already configured in this package. For your own app, add:

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

In Xcode: **Signing & Capabilities → + Capability → Associated Domains**

Add: `applinks:links.example.com`

### 3. apple-app-site-association

Host this file at `https://links.example.com/.well-known/apple-app-site-association`
(no `.json` extension, `Content-Type: application/json`):

```json
{
  "applinks": {
    "details": [{
      "appIDs": ["TEAMID.com.example.myapp"],
      "components": [
        { "/": "/*" }
      ]
    }]
  }
}
```

Replace `TEAMID` with your Apple Developer Team ID.

### 4. Verify Universal Links

```bash
# Check AASA is reachable
curl -I https://links.example.com/.well-known/apple-app-site-association

# Use Apple's validator
open https://search.developer.apple.com/appsearch-validation-tool/
```

---

## Deferred Deep Links

Deferred deep links let you send users to the right place in your app even if they install it after clicking a link.

### How it works

```
User clicks link → Web redirect page stores token in localStorage
       ↓
User installs app → App opens for first time
       ↓
DeferredLinkService checks for pending token
       ↓
Recovers original URL → Navigates to correct screen
```

### Web redirect page

The `web/index.html` in this package handles this automatically. It:
1. Stores the current URL + a unique token in `localStorage`
2. Attempts to open the app via custom URI scheme
3. Falls back to App Store / Play Store if the app isn't installed

### Optional: server-side persistence

For more reliable deferred links (survives browser data clearing), use the included Firebase Cloud Function:

```bash
cd firebase
firebase deploy --only functions,hosting
```

The web page can then POST the token to `/api/deferred` and the app can GET it on first open.

---

## Route Matching

```dart
smartLinks.router.addRoutes([
  RouteDefinition(
    name: 'product',
    pattern: '/product/:id',
    handler: (match) {
      final id = match.pathParams['id'];
      final ref = match.queryParams['ref'];
      Navigator.pushNamed(context, '/product', arguments: {'id': id, 'ref': ref});
    },
  ),
  RouteDefinition(
    name: 'category_item',
    pattern: '/category/:slug/item/:id',
    handler: (match) {
      print(match.allParams); // merged path + query params
    },
  ),
]);
```

Routes are matched in registration order. First match wins.

---

## Analytics

Implement `AnalyticsAdapter` to forward events to any backend:

```dart
class FirebaseAnalyticsAdapter implements AnalyticsAdapter {
  @override
  Future<void> track(SmartLinkAnalyticsEvent event) async {
    await FirebaseAnalytics.instance.logEvent(
      name: event.type.name,
      parameters: event.toMap().cast<String, Object>(),
    );
  }
}

// Register at init time
await smartLinks.initialize(
  config: config,
  analyticsAdapters: [FirebaseAnalyticsAdapter()],
);

// Or add later
smartLinks.addAnalyticsAdapter(MyCustomAdapter());
```

### Event types

| Event | When |
|---|---|
| `linkReceived` | Any incoming link is parsed |
| `deferredLinkRecovered` | First-open deferred link replayed |
| `routeMatched` | Link matched a route definition |
| `routeNotMatched` | No route matched |
| `linkCreated` | `createLink()` was called |
| `appOpened` | App opened from a link |

---

## Firebase Hosting Setup

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Init (select Hosting + Functions)
firebase init

# Copy web assets
cp -r web/* firebase/public/

# Deploy
firebase deploy
```

The `firebase/firebase.json` rewrites ensure:
- `/.well-known/*` files are served with correct `Content-Type`
- All other paths serve `index.html` (the redirect page)
- `/api/*` routes go to the Cloud Function

---

## Branch.io Migration

| Branch.io | tomato_deeplio |
|---|---|
| `Branch.initSession` | `TomatoDeeplio().initialize()` |
| `Branch.subscribe` | `smartLinks.linkStream.listen()` |
| `BranchUniversalObject.generateShortUrl` | `smartLinks.createLink()` |
| `Branch.getLatestReferringParams` | `smartLinks.getPendingDeferredLink()` |
| Custom analytics | `AnalyticsAdapter` interface |

---

## Security Considerations

- **HTTPS only** for App Links and Universal Links — never use HTTP in production.
- **Validate `assetlinks.json` and AASA** before going live. Invalid files silently break link verification.
- **Sanitise path params** before using them in navigation or database queries.
- **Deferred link tokens** are single-use and expire after `deferredLinkMaxAge` (default 30 days).
- **Custom URI schemes** can be intercepted by other apps. Use App Links / Universal Links for sensitive flows.
- **Never put secrets** in link parameters — they appear in server logs and analytics.

---

## Troubleshooting

### Android App Links not opening the app

1. Check `assetlinks.json` is reachable: `curl https://links.example.com/.well-known/assetlinks.json`
2. Verify SHA-256 fingerprint matches your signing key.
3. Check `android:autoVerify="true"` is set in the intent-filter.
4. On Android 12+, run: `adb shell pm get-app-links com.example.myapp`
5. Force re-verification: `adb shell pm verify-app-links --re-verify com.example.myapp`

### iOS Universal Links not working

1. Verify AASA is served with `Content-Type: application/json` (no `.json` extension).
2. Check Associated Domains entitlement is enabled in Xcode.
3. Team ID in AASA must match your Apple Developer account.
4. Universal Links only work on real devices, not the simulator.
5. Test with: `xcrun simctl openurl booted 'https://links.example.com/product/1'`

### Deferred links not recovering

1. Ensure `enableDeferredLinks: true` in config.
2. The web redirect page must run before the app is installed.
3. Check `localStorage` in browser DevTools for `_sl_deferred` key.
4. Verify `DeferredLinkService` is not finding a consumed token.

### Links not matching routes

1. Check pattern syntax — use `:paramName` for dynamic segments.
2. Segment count must match exactly (no wildcards).
3. Routes are matched in order — put more specific patterns first.
4. Use `debugMode: true` to see route matching logs.

---

## License

MIT
