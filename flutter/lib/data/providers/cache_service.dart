import 'dart:convert';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive-based cache service.
///
/// Pattern:
/// - Return cached data instantly if fresh
/// - Otherwise fetch from API and update cache
/// - If API fails and cache exists -> return stale cache
///
/// Multi-clinic ready:
/// Use clinic-scoped keys like:
///   CK.appointments(clinicId)
///   CK.doctors(clinicId)
class CacheService extends GetxService {
  late Box _box;

  /// Call in main() before runApp
  static Future<void> init() async {
    await Hive.initFlutter();
  }

  @override
  void onInit() {
    super.onInit();
    _openBox();
  }

  Future<void> _openBox() async {
    _box = await Hive.openBox('clinify_cache');
  }

  // ─────────────────────────────────────────────
  // High-level cache-first strategy
  // ─────────────────────────────────────────────

  Future<dynamic> cacheFirst({
    required String key,
    required Future<dynamic> Function() fetch,
    Duration maxAge = const Duration(minutes: 5),
    bool forceRefresh = false,
  }) async {
    // Use fresh cache if allowed
    if (!forceRefresh && isFresh(key, maxAge: maxAge)) {
      final cached = get(key);
      if (cached != null) {
        return cached;
      }
    }

    // Fetch fresh data
    try {
      final data = await fetch();
      await put(key, data);
      return data;
    } catch (e) {
      // Fallback to stale cache
      final cached = get(key);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // Basic cache ops
  // ─────────────────────────────────────────────

  Future<void> put(String key, dynamic value) async {
    final entry = {
      'data': jsonEncode(value),
      'ts': DateTime.now().millisecondsSinceEpoch,
    };

    await _box.put(key, jsonEncode(entry));
  }

  dynamic get(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;

    try {
      final entry = jsonDecode(raw as String);
      return jsonDecode(entry['data'] as String);
    } catch (_) {
      return null;
    }
  }

  bool isFresh(
      String key, {
        Duration maxAge = const Duration(minutes: 5),
      }) {
    final raw = _box.get(key);
    if (raw == null) return false;

    try {
      final entry = jsonDecode(raw as String);
      final ts = entry['ts'] as int;

      final age =
          DateTime.now().millisecondsSinceEpoch - ts;

      return age < maxAge.inMilliseconds;
    } catch (_) {
      return false;
    }
  }

  bool has(String key) => _box.containsKey(key);

  Future<void> remove(String key) async {
    await _box.delete(key);
  }

  Future<void> removeByPrefix(String prefix) async {
    final keys = _box.keys
        .where((k) => k.toString().startsWith(prefix))
        .toList();

    for (final k in keys) {
      await _box.delete(k);
    }
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  Future<void> clearClinicScopedCaches() async {
    await removeByPrefix('doctors_');
    await removeByPrefix('specialties_');
    await removeByPrefix('appointments_');
    await removeByPrefix('announcements_');
    await removeByPrefix('notifications_');
    await removeByPrefix('unread_count_');
    await removeByPrefix('schedules_');
    await removeByPrefix('blocked_slots_');
  }
}

// ─────────────────────────────────────────────
// Cache Keys
// ─────────────────────────────────────────────

class CK {
  static const profile = 'profile';
  static const selectedClinic = 'selected_clinic';

  static String doctors(String clinicId) =>
      'doctors_$clinicId';

  static String specialties(String clinicId) =>
      'specialties_$clinicId';

  static String appointments(String clinicId) =>
      'appointments_$clinicId';

  static String announcements(String clinicId) =>
      'announcements_$clinicId';

  static String notifications(String clinicId) =>
      'notifications_$clinicId';

  static String unreadCount(String clinicId) =>
      'unread_count_$clinicId';

  static String schedules(String clinicId) =>
      'schedules_$clinicId';

  static String blockedSlots(String clinicId) =>
      'blocked_slots_$clinicId';

  static String rx(String id) => 'rx_$id';

  static String chat(String id) => 'chat_$id';
}