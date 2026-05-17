import 'package:tomato_deeplio/src/models/route_match.dart';

/// Defines a route pattern that can be matched against incoming link paths.
///
/// Supports named path parameters using `:paramName` syntax.
///
/// Example:
/// ```dart
/// RouteDefinition(
///   name: 'product',
///   pattern: '/product/:id',
///   handler: (match) => ProductPage(id: match.pathParams['id']!),
/// )
/// ```
class RouteDefinition {
  /// Unique name for this route.
  final String name;

  /// URL path pattern, e.g. `/product/:id` or `/category/:slug/item/:id`.
  final String pattern;

  /// Optional handler called when this route is matched.
  final void Function(RouteMatch match)? handler;

  /// Metadata attached to this route (e.g. for analytics).
  final Map<String, dynamic> metadata;

  const RouteDefinition({
    required this.name,
    required this.pattern,
    this.handler,
    this.metadata = const {},
  });

  /// Attempts to match [path] against this route's [pattern].
  ///
  /// Returns a [RouteMatch] on success, or `null` if the path does not match.
  RouteMatch? match(String path, Map<String, String> queryParams) {
    final patternSegments = _segments(pattern);
    final pathSegments = _segments(path);

    if (patternSegments.length != pathSegments.length) return null;

    final extractedParams = <String, String>{};

    for (var i = 0; i < patternSegments.length; i++) {
      final p = patternSegments[i];
      final s = pathSegments[i];

      if (p.startsWith(':')) {
        // Named parameter
        extractedParams[p.substring(1)] = Uri.decodeComponent(s);
      } else if (p != s) {
        // Literal segment mismatch
        return null;
      }
    }

    return RouteMatch(
      routeName: name,
      pathParams: Map.unmodifiable(extractedParams),
      queryParams: Map.unmodifiable(queryParams),
    );
  }

  List<String> _segments(String path) =>
      path.split('/').where((s) => s.isNotEmpty).toList();

  @override
  String toString() => 'RouteDefinition(name: $name, pattern: $pattern)';
}
