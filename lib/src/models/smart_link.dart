/// Represents a parsed incoming smart link.
class SmartLink {
  /// The full original URL string.
  final String rawUrl;

  /// The URI parsed from [rawUrl].
  final Uri uri;

  /// The path component, e.g. `/product/123`.
  final String path;

  /// Query parameters extracted from the URL.
  final Map<String, String> queryParams;

  /// Path segments, e.g. `['product', '123']`.
  final List<String> pathSegments;

  /// Whether this link was deferred (recovered after first install).
  final bool isDeferred;

  /// The source / referral channel, if present (e.g. `utm_source`).
  final String? source;

  /// The campaign identifier, if present (e.g. `utm_campaign`).
  final String? campaign;

  /// The medium, if present (e.g. `utm_medium`).
  final String? medium;

  /// Custom attribution data passed as query params.
  final Map<String, String> customData;

  const SmartLink({
    required this.rawUrl,
    required this.uri,
    required this.path,
    required this.queryParams,
    required this.pathSegments,
    this.isDeferred = false,
    this.source,
    this.campaign,
    this.medium,
    this.customData = const {},
  });

  /// Parses a [SmartLink] from a [Uri].
  factory SmartLink.fromUri(Uri uri, {bool isDeferred = false}) {
    final params = Map<String, String>.from(uri.queryParameters);

    // Extract UTM / attribution params
    final source = params.remove('utm_source');
    final campaign = params.remove('utm_campaign');
    final medium = params.remove('utm_medium');

    // Everything else is custom data
    final customData = Map<String, String>.from(params)
      ..removeWhere((k, _) => k.startsWith('_sl_'));

    return SmartLink(
      rawUrl: uri.toString(),
      uri: uri,
      path: uri.path.isEmpty ? '/' : uri.path,
      queryParams: Map.unmodifiable(uri.queryParameters),
      pathSegments: List.unmodifiable(
        uri.pathSegments.where((s) => s.isNotEmpty).toList(),
      ),
      isDeferred: isDeferred,
      source: source,
      campaign: campaign,
      medium: medium,
      customData: Map.unmodifiable(customData),
    );
  }

  /// Returns a copy with [isDeferred] set to true.
  SmartLink asDeferred() => SmartLink(
        rawUrl: rawUrl,
        uri: uri,
        path: path,
        queryParams: queryParams,
        pathSegments: pathSegments,
        isDeferred: true,
        source: source,
        campaign: campaign,
        medium: medium,
        customData: customData,
      );

  @override
  String toString() =>
      'SmartLink(path: $path, params: $queryParams, deferred: $isDeferred)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartLink &&
          runtimeType == other.runtimeType &&
          rawUrl == other.rawUrl;

  @override
  int get hashCode => rawUrl.hashCode;
}
