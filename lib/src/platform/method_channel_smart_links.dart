import 'dart:async';
import 'package:flutter/services.dart';
import 'package:tomato_deeplio/src/platform/smart_links_platform_interface.dart';

/// Method channel implementation of [TomatoDeeplioPlatformInterface].
///
/// Communicates with the native Android (Kotlin) and iOS (Swift) plugins.
class MethodChannelTomatoDeeplio extends TomatoDeeplioPlatformInterface {
  static const _channel = MethodChannel('tomato_deeplio');
  static const _eventChannel = EventChannel('tomato_deeplio/events');

  Stream<String>? _linkStream;

  @override
  Future<String?> getInitialLink() async {
    try {
      final link = await _channel.invokeMethod<String>('getInitialLink');
      return link;
    } on PlatformException catch (e) {
      // Gracefully return null if the platform has no initial link
      if (e.code == 'NO_INITIAL_LINK') return null;
      rethrow;
    }
  }

  @override
  Stream<String> get linkStream {
    _linkStream ??= _eventChannel
        .receiveBroadcastStream()
        .where((event) => event != null)
        .map((event) => event as String);
    return _linkStream!;
  }

  @override
  Future<void> storeDeferredToken(String token) async {
    await _channel.invokeMethod<void>('storeDeferredToken', {'token': token});
  }

  @override
  Future<String?> getDeferredToken() async {
    return _channel.invokeMethod<String>('getDeferredToken');
  }

  @override
  Future<void> clearDeferredToken() async {
    await _channel.invokeMethod<void>('clearDeferredToken');
  }
}
