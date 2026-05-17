import 'package:tomato_deeplio/src/smart_links_config.dart';

/// Generates smart link URLs from path + parameter inputs.
class LinkGenerator {
  final TomatoDeeplioConfig config;

  const LinkGenerator(this.config);

  /// Creates a full HTTPS smart link URL.
  ///
  /// Example:
  /// ```dart
  /// generator.createLink(
  ///   path: '/product/123',
  ///   params: {'ref': 'USER001', 'utm_source': 'email'},
  /// );
  /// // → https://links.example.com/product/123?ref=USER001&utm_source=email
  /// ```
  String createLink({
    required String path,
    Map<String, String> params = const {},
    String? utmSource,
    String? utmMedium,
    String? utmCampaign,
    String? fallbackUrl,
  }) {
    final allParams = <String, String>{
      if (config.defaultUtmSource != null)
        'utm_source': config.defaultUtmSource!,
      if (config.defaultUtmMedium != null)
        'utm_medium': config.defaultUtmMedium!,
      ...params,
      // Explicit overrides win
      if (utmSource != null) 'utm_source': utmSource,
      if (utmMedium != null) 'utm_medium': utmMedium,
      if (utmCampaign != null) 'utm_campaign': utmCampaign,
      if (fallbackUrl != null) '_sl_fallback': fallbackUrl,
    };

    final normalizedPath = path.startsWith('/') ? path : '/$path';

    final uri = Uri(
      scheme: 'https',
      host: config.domain,
      path: normalizedPath,
      queryParameters: allParams.isEmpty ? null : allParams,
    );

    return uri.toString();
  }

  /// Creates a custom URI scheme deep link.
  ///
  /// Example: `myapp://product/123?ref=USER001`
  String createDeepLink({
    required String path,
    Map<String, String> params = const {},
  }) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;

    final uri = Uri(
      scheme: config.uriScheme,
      host: '',
      path: normalizedPath,
      queryParameters: params.isEmpty ? null : params,
    );

    // Uri with empty host produces `myapp:///path`, normalise to `myapp://path`
    return uri
        .toString()
        .replaceFirst('${config.uriScheme}:///', '${config.uriScheme}://');
  }

  /// Generates a QR-compatible URL (always HTTPS, no custom scheme).
  String createQrLink({
    required String path,
    Map<String, String> params = const {},
    String? utmSource,
    String? utmCampaign,
  }) =>
      createLink(
        path: path,
        params: params,
        utmSource: utmSource ?? 'qr',
        utmMedium: 'qr_code',
        utmCampaign: utmCampaign,
      );
}
