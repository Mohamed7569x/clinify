import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/errors/api_exceptions.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/models/schedule_model.dart';
import '../../../data/models/other_models.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/all_repositories.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../app/config/app_theme.dart';

// ═══════════════════════════════════════════
// Doctor Home
// ═══════════════════════════════════════════

class DoctorHomeController extends GetxController {
  final AppointmentRepository _apptRepo = AppointmentRepository();

  final todayAppointments = <AppointmentModel>[].obs;
  final pendingCount   = 0.obs;
  final completedCount = 0.obs;
  final totalCount     = 0.obs;
  final doctorName     = ''.obs;
  final isLoading      = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData({
    bool forceRefresh = false,
    int? clinicVersion,
  }) async {
    isLoading.value = true;

    try {
      await Future.wait([
        _loadName(),
        _loadAppointments(forceRefresh: forceRefresh),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadName() async {
    try {
      doctorName.value =
          await Get.find<StorageProvider>().getUserName() ?? '';
    } catch (_) {}
  }

  Future<void> _loadAppointments({bool forceRefresh = false}) async {
    try {
      final all  = await _apptRepo.listAppointments(forceRefresh: forceRefresh);
      final now  = DateTime.now();
      final today = _formatDate(now);

      todayAppointments.value = all.where((a) => a.date == today).toList();
      pendingCount.value   = all.where((a) => a.isPending).length;
      completedCount.value = all.where((a) => a.isCompleted).length;
      totalCount.value     = all.length;
    } catch (_) {}
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ═══════════════════════════════════════════
// Doctor Appointments
// ═══════════════════════════════════════════

class DoctorAppointmentsController extends GetxController {
  final AppointmentRepository _repo = AppointmentRepository();

  final appointments = <AppointmentModel>[].obs;
  final statusFilter = ''.obs;
  final isLoading    = false.obs;

  // FIX 3: local cache so setFilter() never hits the network.
  // Original passed statusFilter as a query param and called loadAppointments()
  // on every tab tap — one API round trip per tap.
  // Fix: fetch all once, filter locally in O(n).
  List<AppointmentModel> _all = [];

  @override
  void onInit() {
    super.onInit();
    loadAppointments();
  }

  Future<void> loadAppointments({
    bool forceRefresh = false,
    int? clinicVersion,
  }) async {
    isLoading.value = true;

    try {
      _all = await _repo.listAppointments(
        forceRefresh: forceRefresh,
      );

      appointments.value = List.of(_all);
      _applyFilter();
    } finally {
      isLoading.value = false;
    }
  }

  void setFilter(String status) {
    statusFilter.value = status;
    _applyFilter(); // no network call
  }

  void _applyFilter() {
    appointments.value = statusFilter.value.isEmpty
        ? List.of(_all)
        : _all.where((a) => a.status == statusFilter.value).toList();
  }

  Future<void> updateStatus(String id, String status, {String? notes}) async {
    try {
      await _repo.updateStatus(
        appointmentId: id,
        status: status,
        consultationNotes: status == 'COMPLETED' ? notes : null,
        cancellationReason: status == 'CANCELLED' ? notes : null,
      );
      Get.snackbar(
        'تم التحديث', 'تم تحديث حالة الموعد',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successSoft,
        colorText: AppTheme.success,
      );
      await loadAppointments();
    } catch (_) {}
  }
}

// ═══════════════════════════════════════════
// Schedule
// ═══════════════════════════════════════════

class ScheduleController extends GetxController {
  final ScheduleRepository _repo = ScheduleRepository();

  final schedules    = <ScheduleModel>[].obs;
  final blockedSlots = <BlockedSlotModel>[].obs;
  final isLoading    = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      // FIX 4: parallel — schedules and blocked slots loaded simultaneously.
      // Original awaited _repo.list() then _repo.listBlocked() in sequence.
      final results = await Future.wait([
        _repo.list(),
        _repo.listBlocked(),
      ]);
      schedules.value    = results[0] as List<ScheduleModel>;
      blockedSlots.value = results[1] as List<BlockedSlotModel>;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createSchedule({
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    int slotDuration = 30,
  }) async {
    try {
      await _repo.create({
        'day_of_week':    dayOfWeek,
        'start_time':     startTime,
        'end_time':       endTime,
        'slot_duration':  slotDuration,
      });
      // Reload only the schedules list — no need to refetch blocked slots.
      schedules.value = await _repo.list();
      Get.snackbar(
        'تمت الإضافة', 'تم إنشاء الجدول',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successSoft,
        colorText: AppTheme.success,
      );
    } on ApiException catch (e) {
      Get.snackbar(
        'خطأ', e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.errorSoft,
        colorText: AppTheme.error,
      );
    }
  }

  Future<void> updateSchedule(String id, Map<String, dynamic> data) async {
    try {
      await _repo.update(id, data);
      schedules.value = await _repo.list();
    } catch (_) {}
  }

  Future<void> deleteSchedule(String id) async {
    try {
      await _repo.delete(id);
      // Optimistic removal — no reload needed.
      schedules.removeWhere((s) => s.id == id);
    } catch (_) {}
  }

  Future<void> addBlockedSlot({
    required String date,
    String? startTime,
    String? endTime,
    String? reason,
  }) async {
    try {
      final body = <String, dynamic>{'date': date};
      if (startTime != null) body['start_time'] = startTime;
      if (endTime   != null) body['end_time']   = endTime;
      if (reason    != null) body['reason']      = reason;

      await _repo.createBlocked(body);
      // Reload only the blocked slots list.
      blockedSlots.value = await _repo.listBlocked();
      Get.snackbar(
        'تم الحظر', 'تم حظر الوقت',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successSoft,
        colorText: AppTheme.success,
      );
    } catch (_) {}
  }

  Future<void> removeBlockedSlot(String id) async {
    try {
      await _repo.deleteBlocked(id);
      // Optimistic removal — no reload needed.
      blockedSlots.removeWhere((b) => b.id == id);
    } catch (_) {}
  }
}

// ═══════════════════════════════════════════
// Doctor Profile
// ═══════════════════════════════════════════

class DoctorProfileController extends GetxController {}

// ═══════════════════════════════════════════
// Doctor Chat
// ═══════════════════════════════════════════

class DoctorChatController extends GetxController {
  final ChatRepository _repo = ChatRepository();

  final messages  = <ChatMessageModel>[].obs;
  final isLoading = false.obs;
  final isSending = false.obs;
  final messageCtrl = TextEditingController();

  late String _appointmentId;

  // FIX 5: poll timer — identical reasoning to PatientChatController.
  // Original only loaded messages once; replies were never shown.
  Timer? _pollTimer;

  @override
  void onClose() {
    messageCtrl.dispose();
    // FIX 5: always cancel to prevent post-dispose callback.
    _pollTimer?.cancel();
    super.onClose();
  }

  void setAppointmentId(String id) {
    _appointmentId = id;
    loadMessages();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
          (_) => loadMessages(),
    );
  }

  Future<void> loadMessages() async {
    isLoading.value = true;
    try {
      final fetched = await _repo.listMessages(_appointmentId);
      await _repo.markRead(_appointmentId);

      // FIX 5: deduplicate by id — same race condition as patient chat.
      final seen = <String>{};
      messages.value = fetched.where((m) => seen.add(m.id)).toList();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendMessage() async {
    final text = messageCtrl.text.trim();
    if (text.isEmpty || isSending.value) return;

    isSending.value = true;
    messageCtrl.clear();
    try {
      final msg = await _repo.sendMessage(
        appointmentId: _appointmentId,
        message: text,
      );
      messages.add(msg);
    } finally {
      isSending.value = false;
    }
  }
}

// ═══════════════════════════════════════════
// Add Prescription
// ═══════════════════════════════════════════
class AddPrescriptionController extends GetxController {
  final PrescriptionRepository _repo = PrescriptionRepository();

  final isSaving = false.obs;
  final isLoading = false.obs;

  Map<String, dynamic>? _buildBodyFromValues({
    required String medication,
    String? dosage,
    String? frequency,
    String? duration,
    String? notes,
  }) {
    final med = medication.trim();
    if (med.isEmpty) return null;

    final body = <String, dynamic>{
      'medication': med,
    };

    final d1 = (dosage ?? '').trim();
    final d2 = (frequency ?? '').trim();
    final d3 = (duration ?? '').trim();
    final d4 = (notes ?? '').trim();

    if (d1.isNotEmpty) body['dosage'] = d1;
    if (d2.isNotEmpty) body['frequency'] = d2;
    if (d3.isNotEmpty) body['duration'] = d3;
    if (d4.isNotEmpty) body['notes'] = d4;

    return body;
  }

  Future<List<PrescriptionModel>> loadForAppointment(String appointmentId) async {
    isLoading.value = true;
    try {
      return await _repo.listForAppointment(appointmentId);
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر تحميل الوصفات',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.errorSoft,
        colorText: AppTheme.error,
      );
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> replaceAll(
      String appointmentId,
      List<Map<String, String>> prescriptions,
      ) async {
    final items = prescriptions
        .map((e) => _buildBodyFromValues(
      medication: e['medicationName'] ?? '',
      dosage: e['dosage'],
      frequency: e['frequency'],
      duration: e['duration'],
      notes: e['notes'],
    ))
        .whereType<Map<String, dynamic>>()
        .toList();

    if (items.isEmpty) {
      Get.snackbar(
        'خطأ',
        'أدخل اسم دواء واحد على الأقل',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.errorSoft,
        colorText: AppTheme.error,
      );
      return false;
    }

    isSaving.value = true;
    try {
      await _repo.replaceBulk(
        appointmentId: appointmentId,
        items: items,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر حفظ التعديلات على الوصفات',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.errorSoft,
        colorText: AppTheme.error,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}