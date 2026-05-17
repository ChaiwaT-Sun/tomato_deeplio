/// The result of matching a [SmartLink] against a [RouteDefinition].
class RouteMatch {
  /// The name of the matched route.
  final String routeName;

  /// Path parameters extracted from the URL pattern.
  /// e.g. pattern `/product/:id` + path `/product/123` → `{'id': '123'}`
  final Map<String, String> pathParams;

  /// Query parameters from the URL.
  final Map<String, String> queryParams;

  /// All params merged: path params take precedence over query params.
  Map<String, String> get allParams => {
        ...queryParams,
        ...pathParams,
      };

  const RouteMatch({
    required this.routeName,
    required this.pathParams,
    required this.queryParams,
  });

  @override
  String toString() =>
      'RouteMatch(route: $routeName, pathParams: $pathParams, queryParams: $queryParams)';
}
