import 'package:tomato_deeplio/src/analytics/analytics_adapter.dart';
import 'package:tomato_deeplio/src/models/analytics_event.dart';

/// A simple [AnalyticsAdapter] that prints events to the console.
///
/// Useful during development and debugging. Replace with a real adapter
/// in production.
class ConsoleAnalyticsAdapter implements AnalyticsAdapter {
  final bool verbose;

  const ConsoleAnalyticsAdapter({this.verbose = false});

  @override
  Future<void> track(SmartLinkAnalyticsEvent event) async {
    if (verbose) {
      // ignore: avoid_print
      print('[TomatoDeeplio Analytics] ${event.toMap()}');
    } else {
      // ignore: avoid_print
      print('[TomatoDeeplio Analytics] ${event.type.name}: ${event.path ?? event.url}');
    }
  }
}
