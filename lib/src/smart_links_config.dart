/// Configuration for [TomatoDeeplio].
class TomatoDeeplioConfig {
  /// Your app's custom domain, e.g. `links.example.com`.
  final String domain;

  /// URI scheme for deep links, e.g. `myapp`.
  final String uriScheme;

  /// Android package name, e.g. `com.example.myapp`.
  final String? androidPackageName;

  /// iOS bundle identifier, e.g. `com.example.myapp`.
  final String? iosBundleId;

  /// iOS App Store ID (numeric), e.g. `123456789`.
  final String? iosAppStoreId;

  /// Fallback URL shown when the app is not installed and no store link
  /// is available.
  final String? fallbackUrl;

  /// Whether to enable deferred deep link recovery.
  final bool enableDeferredLinks;

  /// Maximum age of a deferred link before it is discarded.
  final Duration deferredLinkMaxAge;

  /// Whether to print debug logs.
  final bool debugMode;

  /// Default UTM source to attach to generated links.
  final String? defaultUtmSource;

  /// Default UTM medium to attach to generated links.
  final String? defaultUtmMedium;

  const TomatoDeeplioConfig({
    required this.domain,
    required this.uriScheme,
    this.androidPackageName,
    this.iosBundleId,
    this.iosAppStoreId,
    this.fallbackUrl,
    this.enableDeferredLinks = true,
    this.deferredLinkMaxAge = const Duration(days: 30),
    this.debugMode = false,
    this.defaultUtmSource,
    this.defaultUtmMedium,
  });

  /// Validates the config and throws [ArgumentError] on invalid values.
  void validate() {
    if (domain.isEmpty) throw ArgumentError('domain must not be empty');
    if (uriScheme.isEmpty) throw ArgumentError('uriScheme must not be empty');
    if (uriScheme.contains('://')) {
      throw ArgumentError(
          'uriScheme should not include "://", e.g. use "myapp" not "myapp://"');
    }
  }

  @override
  String toString() =>
      'TomatoDeeplioConfig(domain: $domain, scheme: $uriScheme, deferred: $enableDeferredLinks)';
}
