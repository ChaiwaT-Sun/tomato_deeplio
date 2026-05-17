/// Types of analytics events emitted by flutter_smart_links.
enum SmartLinkEventType {
  /// A link was received and parsed.
  linkReceived,

  /// A deferred link was recovered on first open.
  deferredLinkRecovered,

  /// A link was matched to a route.
  routeMatched,

  /// A link could not be matched to any route.
  routeNotMatched,

  /// A link was clicked / opened (web side).
  linkClicked,

  /// App was opened from a link.
  appOpened,

  /// A new link was generated.
  linkCreated,
}

/// An analytics event emitted by the smart links system.
class SmartLinkAnalyticsEvent {
  /// The type of event.
  final SmartLinkEventType type;

  /// The URL involved in the event.
  final String? url;

  /// The path component.
  final String? path;

  /// The matched route name, if applicable.
  final String? routeName;

  /// Whether the link was deferred.
  final bool isDeferred;

  /// UTM source.
  final String? source;

  /// UTM campaign.
  final String? campaign;

  /// UTM medium.
  final String? medium;

  /// When the event occurred.
  final DateTime timestamp;

  /// Additional custom properties.
  final Map<String, dynamic> properties;

  SmartLinkAnalyticsEvent({
    required this.type,
    this.url,
    this.path,
    this.routeName,
    this.isDeferred = false,
    this.source,
    this.campaign,
    this.medium,
    this.properties = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'event': type.name,
        'url': url,
        'path': path,
        'routeName': routeName,
        'isDeferred': isDeferred,
        'source': source,
        'campaign': campaign,
        'medium': medium,
        'timestamp': timestamp.toIso8601String(),
        ...properties,
      };

  @override
  String toString() => 'SmartLinkAnalyticsEvent(${type.name}, path: $path)';
}
