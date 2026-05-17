import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The platform interface that all platform implementations must implement.
abstract class SmartLinksPlatformInterface extends PlatformInterface {
  SmartLinksPlatformInterface() : super(token: _token);

  static final Object _token = Object();

  static SmartLinksPlatformInterface _instance =
      _UnimplementedSmartLinksPlatform();

  /// The current platform instance.
  static SmartLinksPlatformInterface get instance => _instance;

  /// Sets the platform instance. Only plugin implementations should call this.
  static set instance(SmartLinksPlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns the initial link URL that launched the app, if any.
  Future<String?> getInitialLink();

  /// A stream of incoming link URLs while the app is running.
  Stream<String> get linkStream;

  /// Stores a deferred link token for first-open recovery.
  Future<void> storeDeferredToken(String token);

  /// Retrieves the stored deferred link token, if any.
  Future<String?> getDeferredToken();

  /// Clears the stored deferred link token.
  Future<void> clearDeferredToken();
}

/// Fallback implementation that throws on every call.
class _UnimplementedSmartLinksPlatform extends SmartLinksPlatformInterface {
  @override
  Future<String?> getInitialLink() => throw UnimplementedError(
      'getInitialLink() has not been implemented on this platform.');

  @override
  Stream<String> get linkStream => throw UnimplementedError(
      'linkStream has not been implemented on this platform.');

  @override
  Future<void> storeDeferredToken(String token) => throw UnimplementedError(
      'storeDeferredToken() has not been implemented on this platform.');

  @override
  Future<String?> getDeferredToken() => throw UnimplementedError(
      'getDeferredToken() has not been implemented on this platform.');

  @override
  Future<void> clearDeferredToken() => throw UnimplementedError(
      'clearDeferredToken() has not been implemented on this platform.');
}
