/// flutter_smart_links
///
/// A production-ready Flutter package for App Links, Universal Links,
/// Deep Links, Deferred Deep Links, and dynamic routing.
///
/// Modern replacement for Firebase Dynamic Links.
library flutter_smart_links;

// Analytics
export 'src/analytics/analytics_adapter.dart';
export 'src/analytics/console_analytics_adapter.dart';

// Exceptions
export 'src/exceptions/smart_links_exception.dart';

// Models
export 'src/models/analytics_event.dart';
export 'src/models/deferred_link_data.dart';
export 'src/models/route_match.dart';
export 'src/models/smart_link.dart';
export 'src/models/smart_link_result.dart';

// Router
export 'src/router/route_definition.dart';
export 'src/router/smart_link_router.dart';

// Core public API
export 'src/smart_links.dart';
export 'src/smart_links_config.dart';
