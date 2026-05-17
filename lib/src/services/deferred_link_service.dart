import 'dart:convert';

import 'package:flutter_smart_links/src/models/deferred_link_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages persistence and recovery of deferred deep links.
///
/// Strategy:
/// 1. The web redirect page writes an install token to a known URL param.
/// 2. On first open, the app reads the token from the platform channel.
/// 3. This service looks up the stored [DeferredLinkData] by token.
/// 4. Once consumed, the data is marked so it is not replayed.
class DeferredLinkService {
  static const _storageKey = 'flutter_smart_links_deferred';
  static const _firstOpenKey = 'flutter_smart_links_first_open';

  final SharedPreferences _prefs;

  DeferredLinkService(this._prefs);

  /// Creates an instance by loading [SharedPreferences].
  static Future<DeferredLinkService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return DeferredLinkService(prefs);
  }

  /// Returns true if this is the first time the app has been opened.
  bool get isFirstOpen => !_prefs.containsKey(_firstOpenKey);

  /// Marks the app as having been opened at least once.
  Future<void> markOpened() => _prefs.setBool(_firstOpenKey, true);

  /// Stores [data] for later recovery.
  Future<void> store(DeferredLinkData data) async {
    final json = jsonEncode(data.toJson());
    await _prefs.setString(_storageKey, json);
  }

  /// Retrieves stored [DeferredLinkData], or `null` if none exists.
  DeferredLinkData? retrieve() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) return null;
    try {
      return DeferredLinkData.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Marks the stored deferred link as consumed so it is not replayed.
  Future<void> markConsumed() async {
    final data = retrieve();
    if (data == null) return;
    await store(data.markConsumed());
  }

  /// Clears all stored deferred link data.
  Future<void> clear() async {
    await _prefs.remove(_storageKey);
  }

  /// Returns the pending (unconsumed) deferred link, if any.
  DeferredLinkData? getPending() {
    final data = retrieve();
    if (data == null || data.consumed) return null;
    return data;
  }

  /// Stores a deferred link from a URL string and optional token.
  Future<void> storeFromUrl(String url, {String? token, String? referrer}) =>
      store(DeferredLinkData(
        url: url,
        capturedAt: DateTime.now(),
        installToken: token,
        referrer: referrer,
      ));
}
