import 'dart:async';

import 'package:tomato_deeplio/src/analytics/analytics_adapter.dart';
import 'package:tomato_deeplio/src/analytics/console_analytics_adapter.dart';
import 'package:tomato_deeplio/src/exceptions/smart_links_exception.dart';
import 'package:tomato_deeplio/src/models/analytics_event.dart';
import 'package:tomato_deeplio/src/models/smart_link.dart';
import 'package:tomato_deeplio/src/models/smart_link_result.dart';
import 'package:tomato_deeplio/src/platform/method_channel_smart_links.dart';
import 'package:tomato_deeplio/src/platform/smart_links_platform_interface.dart';
import 'package:tomato_deeplio/src/router/route_definition.dart';
import 'package:tomato_deeplio/src/router/smart_link_router.dart';
import 'package:tomato_deeplio/src/services/deferred_link_service.dart';
import 'package:tomato_deeplio/src/services/link_generator.dart';
import 'package:tomato_deeplio/src/services/link_parser.dart';
import 'package:tomato_deeplio/src/smart_links_config.dart';

/// The main entry point for tomato_deeplio.
///
/// ## Quick start
/// ```dart
/// final smartLinks = TomatoDeeplio();
///
/// await smartLinks.initialize(
///   config: TomatoDeeplioConfig(
///     domain: 'links.example.com',
///     uriScheme: 'myapp',
///   ),
/// );
///
/// smartLinks.linkStream.listen((link) {
///   print(link.path);
/// });
///
/// final url = smartLinks.createLink(
///   path: '/product/123',
///   params: {'ref': 'USER001'},
/// );
/// ```
class TomatoDeeplio {
  // ── Singleton ──────────────────────────────────────────────────────────────

  static TomatoDeeplio? _instance;

  /// Returns the singleton instance.
  factory TomatoDeeplio() => _instance ??= TomatoDeeplio._internal();

  TomatoDeeplio._internal();

  // ── State ──────────────────────────────────────────────────────────────────

  bool _initialized = false;
  late TomatoDeeplioConfig _config;
  late LinkParser _parser;
  late LinkGenerator _generator;
  late SmartLinkRouter _router;
  late DeferredLinkService _deferredService;

  final List<AnalyticsAdapter> _analyticsAdapters = [];
  final StreamController<SmartLink> _linkController =
      StreamController<SmartLink>.broadcast();
  final StreamController<SmartLinkResult> _resultController =
      StreamController<SmartLinkResult>.broadcast();

  StreamSubscription<String>? _platformSubscription;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Whether [initialize] has been called.
  bool get isInitialized => _initialized;

  /// The active configuration.
  TomatoDeeplioConfig get config {
    _assertInitialized();
    return _config;
  }

  /// Stream of incoming [SmartLink]s (both cold-start and foreground).
  Stream<SmartLink> get linkStream {
    _assertInitialized();
    return _linkController.stream;
  }

  /// Stream of [SmartLinkResult]s with route matching information.
  Stream<SmartLinkResult> get resultStream {
    _assertInitialized();
    return _resultController.stream;
  }

  /// The router used for route matching.
  SmartLinkRouter get router {
    _assertInitialized();
    return _router;
  }

  // ── Initialisation ─────────────────────────────────────────────────────────

  /// Initialises the TomatoDeeplio system.
  ///
  /// Must be called once, typically in `main()` before `runApp()`.
  ///
  /// - [config] — required configuration.
  /// - [routes] — optional initial route definitions.
  /// - [analyticsAdapters] — optional analytics backends.
  /// - [debugMode] — if true, adds a [ConsoleAnalyticsAdapter].
  Future<void> initialize({
    required TomatoDeeplioConfig config,
    List<RouteDefinition> routes = const [],
    List<AnalyticsAdapter> analyticsAdapters = const [],
    bool debugMode = false,
  }) async {
    if (_initialized) throw const AlreadyInitializedException();

    config.validate();
    _config = config;
    _parser = LinkParser(config);
    _generator = LinkGenerator(config);
    _router = SmartLinkRouter();
    _router.addRoutes(routes);

    _analyticsAdapters.addAll(analyticsAdapters);
    if (debugMode || config.debugMode) {
      _analyticsAdapters.add(const ConsoleAnalyticsAdapter(verbose: true));
    }

    // Register the method channel implementation
    TomatoDeeplioPlatformInterface.instance = MethodChannelTomatoDeeplio();

    // Deferred link service
    _deferredService = await DeferredLinkService.create();

    _initialized = true;

    // Handle cold-start link
    await _handleInitialLink();

    // Handle deferred link on first open
    if (config.enableDeferredLinks) {
      await _handleDeferredLink();
    }

    // Subscribe to foreground links
    _platformSubscription = TomatoDeeplioPlatformInterface.instance.linkStream
        .listen(_onRawLink, onError: _onLinkError);
  }

  // ── Link handling ──────────────────────────────────────────────────────────

  /// Manually processes a raw URL string as a smart link.
  ///
  /// Useful for testing or handling links from custom sources.
  Future<SmartLinkResult> handleLink(String rawUrl,
      {bool isDeferred = false}) async {
    _assertInitialized();
    try {
      final link = _parser.parse(rawUrl, isDeferred: isDeferred);
      return _processLink(link);
    } on InvalidLinkException catch (e) {
      _log('Invalid link: $rawUrl — ${e.message}');
      rethrow;
    }
  }

  // ── Link generation ────────────────────────────────────────────────────────

  /// Creates a full HTTPS smart link URL.
  ///
  /// ```dart
  /// final url = smartLinks.createLink(
  ///   path: '/product/123',
  ///   params: {'ref': 'USER001'},
  /// );
  /// ```
  String createLink({
    required String path,
    Map<String, String> params = const {},
    String? utmSource,
    String? utmMedium,
    String? utmCampaign,
    String? fallbackUrl,
  }) {
    _assertInitialized();
    final url = _generator.createLink(
      path: path,
      params: params,
      utmSource: utmSource,
      utmMedium: utmMedium,
      utmCampaign: utmCampaign,
      fallbackUrl: fallbackUrl ?? _config.fallbackUrl,
    );
    _trackEvent(SmartLinkAnalyticsEvent(
      type: SmartLinkEventType.linkCreated,
      url: url,
      path: path,
    ));
    return url;
  }

  /// Creates a custom URI scheme deep link.
  String createDeepLink({
    required String path,
    Map<String, String> params = const {},
  }) {
    _assertInitialized();
    return _generator.createDeepLink(path: path, params: params);
  }

  /// Creates a QR-compatible HTTPS link.
  String createQrLink({
    required String path,
    Map<String, String> params = const {},
    String? utmCampaign,
  }) {
    _assertInitialized();
    return _generator.createQrLink(
      path: path,
      params: params,
      utmCampaign: utmCampaign,
    );
  }

  // ── Analytics ──────────────────────────────────────────────────────────────

  /// Registers an additional [AnalyticsAdapter].
  void addAnalyticsAdapter(AnalyticsAdapter adapter) {
    _assertInitialized();
    _analyticsAdapters.add(adapter);
  }

  // ── Deferred links ─────────────────────────────────────────────────────────

  /// Stores a deferred link URL for first-open recovery.
  ///
  /// Call this from your web redirect page's install token handler.
  Future<void> storeDeferredLink(String url, {String? token}) async {
    _assertInitialized();
    await _deferredService.storeFromUrl(url, token: token);
  }

  /// Returns the pending deferred link data, if any.
  ///
  /// Returns `null` if no unconsumed deferred link exists.
  Future<SmartLink?> getPendingDeferredLink() async {
    _assertInitialized();
    final data = _deferredService.getPending();
    if (data == null) return null;
    try {
      return _parser.parse(data.url, isDeferred: true);
    } catch (_) {
      return null;
    }
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  /// Disposes resources. Call when the app is shutting down.
  Future<void> dispose() async {
    await _platformSubscription?.cancel();
    await _linkController.close();
    await _resultController.close();
    _initialized = false;
    _instance = null;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _handleInitialLink() async {
    try {
      final rawUrl =
          await TomatoDeeplioPlatformInterface.instance.getInitialLink();
      if (rawUrl != null && rawUrl.isNotEmpty) {
        await _onRawLink(rawUrl);
      }
    } catch (e) {
      _log('Error reading initial link: $e');
    }
  }

  Future<void> _handleDeferredLink() async {
    if (!_deferredService.isFirstOpen) return;
    await _deferredService.markOpened();

    final pending = _deferredService.getPending();
    if (pending == null) return;

    _log('Recovering deferred link: ${pending.url}');

    try {
      final link = _parser.parse(pending.url, isDeferred: true);
      _processLink(link);
      await _deferredService.markConsumed();

      _trackEvent(SmartLinkAnalyticsEvent(
        type: SmartLinkEventType.deferredLinkRecovered,
        url: pending.url,
        path: link.path,
        isDeferred: true,
        source: link.source,
        campaign: link.campaign,
        medium: link.medium,
      ));
    } catch (e) {
      _log('Failed to recover deferred link: $e');
    }
  }

  Future<void> _onRawLink(String rawUrl) async {
    try {
      final link = _parser.parse(rawUrl);
      _processLink(link);
    } on InvalidLinkException catch (e) {
      _log('Received invalid link: $e');
    }
  }

  void _onLinkError(Object error) {
    _log('Platform link stream error: $error');
  }

  SmartLinkResult _processLink(SmartLink link) {
    final routeMatch = _router.match(link);

    final result = SmartLinkResult(
      link: link,
      routeMatch: routeMatch,
    );

    _linkController.add(link);
    _resultController.add(result);

    _trackEvent(SmartLinkAnalyticsEvent(
      type: SmartLinkEventType.linkReceived,
      url: link.rawUrl,
      path: link.path,
      isDeferred: link.isDeferred,
      source: link.source,
      campaign: link.campaign,
      medium: link.medium,
    ));

    if (routeMatch != null) {
      _trackEvent(SmartLinkAnalyticsEvent(
        type: SmartLinkEventType.routeMatched,
        url: link.rawUrl,
        path: link.path,
        routeName: routeMatch.routeName,
        isDeferred: link.isDeferred,
      ));
    } else {
      _trackEvent(SmartLinkAnalyticsEvent(
        type: SmartLinkEventType.routeNotMatched,
        url: link.rawUrl,
        path: link.path,
        isDeferred: link.isDeferred,
      ));
    }

    return result;
  }

  void _trackEvent(SmartLinkAnalyticsEvent event) {
    for (final adapter in _analyticsAdapters) {
      adapter.track(event).catchError((Object e) {
        _log('Analytics adapter error: $e');
      });
    }
  }

  void _assertInitialized() {
    if (!_initialized) throw const NotInitializedException();
  }

  void _log(String message) {
    if (_config.debugMode) {
      // ignore: avoid_print
      print('[TomatoDeeplio] $message');
    }
  }
}
