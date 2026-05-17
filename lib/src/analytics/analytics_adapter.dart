import 'package:flutter_smart_links/src/models/analytics_event.dart';

/// Interface for plugging in custom analytics backends.
///
/// Implement this to forward smart link events to Firebase Analytics,
/// Amplitude, Mixpanel, Branch.io, or any other provider.
///
/// Example:
/// ```dart
/// class FirebaseAnalyticsAdapter implements AnalyticsAdapter {
///   @override
///   Future<void> track(SmartLinkAnalyticsEvent event) async {
///     await FirebaseAnalytics.instance.logEvent(
///       name: event.type.name,
///       parameters: event.toMap().cast<String, Object>(),
///     );
///   }
/// }
/// ```
abstract interface class AnalyticsAdapter {
  /// Called whenever a smart link analytics event occurs.
  Future<void> track(SmartLinkAnalyticsEvent event);
}
