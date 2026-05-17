import 'package:flutter_smart_links/src/models/route_match.dart';
import 'package:flutter_smart_links/src/models/smart_link.dart';

/// The result of processing an incoming [SmartLink].
class SmartLinkResult {
  /// The parsed link.
  final SmartLink link;

  /// The matched route, if any route definition matched.
  final RouteMatch? routeMatch;

  /// Whether the link was handled successfully.
  final bool handled;

  /// Optional error message if handling failed.
  final String? error;

  const SmartLinkResult({
    required this.link,
    this.routeMatch,
    this.handled = true,
    this.error,
  });

  /// Creates a failed result.
  factory SmartLinkResult.failure(SmartLink link, String error) =>
      SmartLinkResult(link: link, handled: false, error: error);

  bool get hasRoute => routeMatch != null;

  @override
  String toString() =>
      'SmartLinkResult(path: ${link.path}, handled: $handled, route: ${routeMatch?.routeName})';
}
