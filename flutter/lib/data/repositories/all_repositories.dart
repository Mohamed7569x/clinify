import 'package:get/get.dart';
import '../../app/config/api_config.dart';
import '../../modules/auth/controllers/auth_controller.dart';
import '../models/patient_model.dart';
import '../models/other_models.dart';
import '../models/schedule_model.dart';
import '../models/specialty_model.dart';
import '../providers/api_provider.dart';
import '../providers/cache_service.dart';

// ═══════════════════════════════════════════
// Patient
// ═══════════════════════════════════════════

class PatientRepository {
  final _api = Get.find<ApiProvider>();
  final _c = Get.find<CacheService>();

  Future<PatientModel> getMyProfile() async {
    final data = await _c.cacheFirst(
      key: CK.profile,
      fetch: () => _api.get(ApiConfig.patientMe),
      maxAge: const Duration(minutes: 10),
    );
    return PatientModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<PatientModel> updateMyProfile(Map<String, dynamic> body) async {
    final data = await _api.put(ApiConfig.patientMe, body: body);
    await _c.put(CK.profile, data); // Update cache
    return PatientModel.fromJson(data);
  }
}

// ═══════════════════════════════════════════
// Prescription
// ═══════════════════════════════════════════

class PrescriptionRepository {
  final _api = Get.find<ApiProvider>();
  final _c = Get.find<CacheService>();

  Future<List<PrescriptionModel>> listForAppointment(String apptId) async {
    try {
      print('Fetching prescriptions for appointment: $apptId');

      final data = await _c.cacheFirst(
        key: CK.rx(apptId),
        fetch: () async {
          final res = await _api.get(
            '${ApiConfig.appointments}/$apptId/prescriptions/',
          );

          print('RAW RESPONSE: $res');
          return res;
        },
      );

      print('PARSED DATA: $data');

      return (data as List)
          .map(
            (j) => PrescriptionModel.fromJson(
          Map<String, dynamic>.from(j),
        ),
      )
          .toList();
    } catch (e, s) {
      print('ERROR IN listForAppointment: $e');
      print('STACKTRACE: $s');

      rethrow;
    }
  }

  Future<PrescriptionModel> create({
    required String appointmentId,
    required Map<String, dynamic> body,
  }) async {
    final data = await _api.post(
      '${ApiConfig.appointments}/$appointmentId/prescriptions/',
      body: body,
    );

    await _c.remove(CK.rx(appointmentId));
    return PrescriptionModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<PrescriptionModel>> createBulk({
    required String appointmentId,
    required List<Map<String, dynamic>> items,
  }) async {
    final data = await _api.post(
      '${ApiConfig.appointments}/$appointmentId/prescriptions/bulk',
      body: {
        'items': items,
      },
    );

    await _c.remove(CK.rx(appointmentId));

    final rawItems = (data['items'] as List?) ?? const [];
    return rawItems
        .map((j) => PrescriptionModel.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  Future<List<PrescriptionModel>> replaceBulk({
    required String appointmentId,
    required List<Map<String, dynamic>> items,
  }) async {
    final data = await _api.put(
      '${ApiConfig.appointments}/$appointmentId/prescriptions/bulk',
      body: {
        'items': items,
      },
    );

    await _c.remove(CK.rx(appointmentId));

    final rawItems = (data['items'] as List?) ?? const [];
    return rawItems
        .map((j) => PrescriptionModel.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }
}
// ═══════════════════════════════════════════
// Review
// ═══════════════════════════════════════════

class ReviewRepository {
  final _api = Get.find<ApiProvider>();

  Future<ReviewModel?> getForAppointment(String apptId) async {
    try {
      final data = await _api.get('${ApiConfig.appointments}/$apptId/review/');
      return ReviewModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<ReviewModel> create({required String appointmentId, required int rating, String? comment}) async {
    final body = <String, dynamic>{'rating': rating};
    if (comment != null && comment.isNotEmpty) body['comment'] = comment;
    final data = await _api.post('${ApiConfig.appointments}/$appointmentId/review/', body: body);
    return ReviewModel.fromJson(data);
  }
}

// ═══════════════════════════════════════════
// Chat
// ═══════════════════════════════════════════

class ChatRepository {
  final _api = Get.find<ApiProvider>();
  final _c = Get.find<CacheService>();

  Future<List<ChatMessageModel>> listMessages(String apptId) async {
    final data = await _c.cacheFirst(
      key: CK.chat(apptId),
      fetch: () => _api.get('${ApiConfig.appointments}/$apptId/chat/'),
      maxAge: const Duration(seconds: 30), // Chat = short TTL
    );
    return (data as List).map((j) => ChatMessageModel.fromJson(Map<String, dynamic>.from(j))).toList();
  }

  Future<ChatMessageModel> sendMessage({required String appointmentId, required String message}) async {
    final data = await _api.post('${ApiConfig.appointments}/$appointmentId/chat/', body: {'message': message});
    await _c.remove(CK.chat(appointmentId));
    return ChatMessageModel.fromJson(data);
  }

  Future<void> markRead(String apptId) async {
    await _api.patch('${ApiConfig.appointments}/$apptId/chat/read');
  }
}

// ═══════════════════════════════════════════
// Notification
// ═══════════════════════════════════════════


class NotificationRepository {
  final _api = Get.find<ApiProvider>();
  final _c = Get.find<CacheService>();

  String _notificationsKey() {
    final auth = Get.find<AuthController>();
    final clinicId = auth.selectedClinic.value?.clinicId?.trim();

    if (clinicId == null || clinicId.isEmpty) {
      throw Exception('No active clinic selected');
    }

    return CK.notifications(clinicId);
  }

  String _unreadCountKey() {
    final auth = Get.find<AuthController>();
    final clinicId = auth.selectedClinic.value?.clinicId?.trim();

    if (clinicId == null || clinicId.isEmpty) {
      throw Exception('No active clinic selected');
    }

    return CK.unreadCount(clinicId);
  }

  Future<List<NotificationModel>> list({
    bool unreadOnly = false,
    bool forceRefresh = false,
  }) async {
    final params = <String, dynamic>{};
    if (unreadOnly) {
      params['unread_only'] = 'true';
    }

    final useCache = !unreadOnly;

    if (useCache) {
      final data = await _c.cacheFirst(
        key: _notificationsKey(),
        forceRefresh: forceRefresh,
        fetch: () => _api.get(
          ApiConfig.notifications,
          queryParams: params,
        ),
        maxAge: const Duration(minutes: 2),
      );

      return (data as List)
          .map(
            (j) => NotificationModel.fromJson(
          Map<String, dynamic>.from(j),
        ),
      )
          .toList();
    }

    final data = await _api.get(
      ApiConfig.notifications,
      queryParams: params,
    );

    return (data as List)
        .map(
          (j) => NotificationModel.fromJson(
        Map<String, dynamic>.from(j),
      ),
    )
        .toList();
  }

  Future<int> unreadCount({bool forceRefresh = false}) async {
    final data = await _c.cacheFirst(
      key: _unreadCountKey(),
      forceRefresh: forceRefresh,
      fetch: () => _api.get(ApiConfig.notificationsUnreadCount),
      maxAge: const Duration(minutes: 2),
    );

    return (data is Map<String, dynamic>)
        ? (data['unread_count'] ?? 0) as int
        : 0;
  }

  Future<void> markRead(String id) async {
    await _api.patch('${ApiConfig.notifications}/$id/read');
    await _c.remove(_notificationsKey());
    await _c.remove(_unreadCountKey());
  }

  Future<void> markAllRead() async {
    await _api.patch(ApiConfig.notificationsReadAll);
    await _c.remove(_notificationsKey());
    await _c.remove(_unreadCountKey());
  }
}

// ═══════════════════════════════════════════
// Announcement
// ═══════════════════════════════════════════
class AnnouncementRepository {
  final _api = Get.find<ApiProvider>();
  final _c = Get.find<CacheService>();

  String _key() {
    final clinicId =
    Get.find<AuthController>().selectedClinic.value?.clinicId?.trim();

    if (clinicId == null || clinicId.isEmpty) {
      throw Exception('No active clinic selected');
    }

    return CK.announcements(clinicId);
  }

  Future<List<AnnouncementModel>> list({
    bool forceRefresh = false,
  }) async {
    final data = await _c.cacheFirst(
      key: _key(),
      fetch: () => _api.get(ApiConfig.announcements),
      maxAge: const Duration(minutes: 10),
      forceRefresh: forceRefresh,
    );

    return (data as List)
        .map((j) => AnnouncementModel.fromJson(
      Map<String, dynamic>.from(j),
    ))
        .toList();
  }
}

// ═══════════════════════════════════════════
// Schedule (Doctor)
// ═══════════════════════════════════════════
class ScheduleRepository {
  final _api = Get.find<ApiProvider>();
  final _c = Get.find<CacheService>();

  String _schedulesKey() {
    final clinicId =
    Get.find<AuthController>().selectedClinic.value?.clinicId?.trim();

    if (clinicId == null || clinicId.isEmpty) {
      throw Exception('No active clinic selected');
    }

    return CK.schedules(clinicId);
  }

  String _blockedKey() {
    final clinicId =
    Get.find<AuthController>().selectedClinic.value?.clinicId?.trim();

    if (clinicId == null || clinicId.isEmpty) {
      throw Exception('No active clinic selected');
    }

    return CK.blockedSlots(clinicId);
  }

  Future<List<ScheduleModel>> list({
    bool forceRefresh = false,
  }) async {
    final data = await _c.cacheFirst(
      key: _schedulesKey(),
      fetch: () => _api.get(ApiConfig.schedules),
      forceRefresh: forceRefresh,
    );

    return (data as List)
        .map((j) => ScheduleModel.fromJson(
      Map<String, dynamic>.from(j),
    ))
        .toList();
  }

  Future<ScheduleModel> create(Map<String, dynamic> body) async {
    final data = await _api.post('${ApiConfig.schedules}/', body: body);
    await _c.remove(_schedulesKey());
    return ScheduleModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<ScheduleModel> update(String id, Map<String, dynamic> body) async {
    final data = await _api.put('${ApiConfig.schedules}/$id', body: body);
    await _c.remove(_schedulesKey());
    return ScheduleModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> delete(String id) async {
    await _api.delete('${ApiConfig.schedules}/$id');
    await _c.remove(_schedulesKey());
  }

  Future<List<BlockedSlotModel>> listBlocked({
    bool forceRefresh = false,
  }) async {
    final data = await _c.cacheFirst(
      key: _blockedKey(),
      fetch: () => _api.get(ApiConfig.blockedSlots),
      forceRefresh: forceRefresh,
    );

    return (data as List)
        .map((j) => BlockedSlotModel.fromJson(
      Map<String, dynamic>.from(j),
    ))
        .toList();
  }

  Future<BlockedSlotModel> createBlocked(Map<String, dynamic> body) async {
    final data = await _api.post('${ApiConfig.blockedSlots}/', body: body);
    await _c.remove(_blockedKey());
    return BlockedSlotModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteBlocked(String id) async {
    await _api.delete('${ApiConfig.blockedSlots}/$id');
    await _c.remove(_blockedKey());
  }
}
// ═══════════════════════════════════════════
// Specialty (long TTL — rarely changes)
// ═══════════════════════════════════════════
class SpecialtyRepository {
  final _api = Get.find<ApiProvider>();
  final _c = Get.find<CacheService>();

  String _key() {
    final clinicId =
    Get.find<AuthController>().selectedClinic.value?.clinicId?.trim();

    if (clinicId == null || clinicId.isEmpty) {
      throw Exception('No active clinic selected');
    }

    return CK.specialties(clinicId);
  }

  Future<List<SpecialtyModel>> list({
    bool forceRefresh = false,
  }) async {
    final data = await _c.cacheFirst(
      key: _key(),
      fetch: () => _api.get(ApiConfig.specialties),
      maxAge: const Duration(minutes: 10),
      forceRefresh: forceRefresh,
    );

    return (data as List)
        .map((j) => SpecialtyModel.fromJson(
      Map<String, dynamic>.from(j),
    ))
        .toList();
  }
}