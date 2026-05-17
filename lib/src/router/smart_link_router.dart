import 'package:flutter_smart_links/src/models/route_match.dart';
import 'package:flutter_smart_links/src/models/smart_link.dart';
import 'package:flutter_smart_links/src/router/route_definition.dart';

/// Routes incoming [SmartLink]s to registered [RouteDefinition]s.
///
/// Routes are evaluated in registration order; the first match wins.
class SmartLinkRouter {
  final List<RouteDefinition> _routes = [];

  /// Registers a [RouteDefinition].
  void addRoute(RouteDefinition route) {
    _routes.add(route);
  }

  /// Registers multiple [RouteDefinition]s at once.
  void addRoutes(List<RouteDefinition> routes) {
    _routes.addAll(routes);
  }

  /// Removes a route by name.
  void removeRoute(String name) {
    _routes.removeWhere((r) => r.name == name);
  }

  /// Returns all registered routes (read-only).
  List<RouteDefinition> get routes => List.unmodifiable(_routes);

  /// Attempts to match [link] against registered routes.
  ///
  /// Returns the first [RouteMatch] found, or `null` if no route matches.
  RouteMatch? match(SmartLink link) {
    for (final route in _routes) {
      final result = route.match(link.path, link.queryParams);
      if (result != null) {
        // Invoke the handler if one is registered
        route.handler?.call(result);
        return result;
      }
    }
    return null;
  }

  /// Clears all registered routes.
  void clear() => _routes.clear();

  @override
  String toString() => 'SmartLinkRouter(${_routes.length} routes)';
}
