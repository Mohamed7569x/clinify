import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../data/models/other_models.dart';
import '../../../data/repositories/all_repositories.dart';
import '../../auth/controllers/auth_controller.dart';

class NotificationController extends GetxController {
  final NotificationRepository _repo = NotificationRepository();

  final notifications = <NotificationModel>[].obs;
  final unreadCount = 0.obs;
  final isLoading = false.obs;

  int _lastAcceptedClinicVersion = 0;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
    fetchUnreadCount();
  }

  Future<void> loadNotifications({
    bool forceRefresh = false,
    int? clinicVersion,
  }) async {
    final auth = Get.find<AuthController>();
    final requestVersion = clinicVersion ?? auth.clinicReloadVersion;
    final requestClinicId = auth.selectedClinic.value?.clinicId;

    isLoading.value = true;

    try {
      final result = await _repo.list(forceRefresh: forceRefresh);

      final currentClinicId = auth.selectedClinic.value?.clinicId;
      final currentVersion = auth.clinicReloadVersion;

      final isStale =
          requestClinicId != currentClinicId ||
              requestVersion != currentVersion ||
              requestVersion < _lastAcceptedClinicVersion;

      if (isStale) {
        debugPrint(
          'NotificationController ignored stale notifications response '
              'requestClinic=$requestClinicId currentClinic=$currentClinicId '
              'requestVersion=$requestVersion currentVersion=$currentVersion',
        );
        return;
      }

      _lastAcceptedClinicVersion = requestVersion;
      notifications.assignAll(result);
    } catch (e) {
      final currentClinicId = auth.selectedClinic.value?.clinicId;
      final currentVersion = auth.clinicReloadVersion;

      final isStale =
          requestClinicId != currentClinicId ||
              requestVersion != currentVersion;

      if (isStale) {
        debugPrint('NotificationController ignored stale notifications error: $e');
        return;
      }
    } finally {
      final currentVersion = auth.clinicReloadVersion;
      if (requestVersion == currentVersion) {
        isLoading.value = false;
      }
    }
  }

  Future<void> fetchUnreadCount({
    bool forceRefresh = false,
    int? clinicVersion,
  }) async {
    final auth = Get.find<AuthController>();
    final requestVersion = clinicVersion ?? auth.clinicReloadVersion;
    final requestClinicId = auth.selectedClinic.value?.clinicId;

    try {
      final result = await _repo.unreadCount(forceRefresh: forceRefresh);

      final currentClinicId = auth.selectedClinic.value?.clinicId;
      final currentVersion = auth.clinicReloadVersion;

      final isStale =
          requestClinicId != currentClinicId ||
              requestVersion != currentVersion ||
              requestVersion < _lastAcceptedClinicVersion;

      if (isStale) {
        debugPrint(
          'NotificationController ignored stale unreadCount response '
              'requestClinic=$requestClinicId currentClinic=$currentClinicId '
              'requestVersion=$requestVersion currentVersion=$currentVersion',
        );
        return;
      }

      unreadCount.value = result;
    } catch (e) {
      final currentClinicId = auth.selectedClinic.value?.clinicId;
      final currentVersion = auth.clinicReloadVersion;

      final isStale =
          requestClinicId != currentClinicId ||
              requestVersion != currentVersion;

      if (isStale) {
        debugPrint('NotificationController ignored stale unreadCount error: $e');
        return;
      }
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _repo.markRead(id);

      final idx = notifications.indexWhere((n) => n.id == id);
      if (idx != -1) {
        final n = notifications[idx];
        notifications[idx] = NotificationModel(
          id: n.id,
          userId: n.userId,
          type: n.type,
          title: n.title,
          body: n.body,
          isRead: true,
          relatedId: n.relatedId,
          createdAt: n.createdAt,
        );
      }

      unreadCount.value = notifications.where((n) => !n.isRead).length;
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _repo.markAllRead();

      notifications.value = notifications.map((n) {
        return NotificationModel(
          id: n.id,
          userId: n.userId,
          type: n.type,
          title: n.title,
          body: n.body,
          isRead: true,
          relatedId: n.relatedId,
          createdAt: n.createdAt,
        );
      }).toList();

      unreadCount.value = 0;
    } catch (_) {}
  }
}