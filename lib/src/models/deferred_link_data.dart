/// Persisted data for deferred deep link recovery.
///
/// When a user installs the app via a smart link, this data is stored
/// locally and replayed on first open so the app can navigate to the
/// correct destination.
class DeferredLinkData {
  /// The original URL the user clicked before installing.
  final String url;

  /// When the link was first captured (click time).
  final DateTime capturedAt;

  /// Whether this deferred link has already been consumed.
  final bool consumed;

  /// Install tracking token (set by the web redirect page).
  final String? installToken;

  /// Optional referrer string from the web page.
  final String? referrer;

  const DeferredLinkData({
    required this.url,
    required this.capturedAt,
    this.consumed = false,
    this.installToken,
    this.referrer,
  });

  /// Creates a [DeferredLinkData] from a JSON map (for persistence).
  factory DeferredLinkData.fromJson(Map<String, dynamic> json) =>
      DeferredLinkData(
        url: json['url'] as String,
        capturedAt: DateTime.parse(json['capturedAt'] as String),
        consumed: json['consumed'] as bool? ?? false,
        installToken: json['installToken'] as String?,
        referrer: json['referrer'] as String?,
      );

  /// Serialises to a JSON map.
  Map<String, dynamic> toJson() => {
        'url': url,
        'capturedAt': capturedAt.toIso8601String(),
        'consumed': consumed,
        if (installToken != null) 'installToken': installToken,
        if (referrer != null) 'referrer': referrer,
      };

  /// Returns a copy marked as consumed.
  DeferredLinkData markConsumed() => DeferredLinkData(
        url: url,
        capturedAt: capturedAt,
        consumed: true,
        installToken: installToken,
        referrer: referrer,
      );

  @override
  String toString() =>
      'DeferredLinkData(url: $url, consumed: $consumed, token: $installToken)';
}
