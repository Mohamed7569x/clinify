import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/errors/api_exceptions.dart';
import '../../../data/models/doctor_model.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/models/other_models.dart';
import '../../../data/models/specialty_model.dart';
import '../../../data/repositories/doctor_repository.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/all_repositories.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../app/config/app_theme.dart';

// ═══════════════════════════════════════════
// Patient Home
// ═══════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/errors/api_exceptions.dart';
import '../../../data/models/doctor_model.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/models/other_models.dart';
import '../../../data/models/specialty_model.dart';
import '../../../data/repositories/doctor_repository.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/all_repositories.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../app/config/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';

// ═══════════════════════════════════════════
// Patient Home
// ═══════════════════════════════════════════

class PatientHomeController extends GetxController {
  final AppointmentRepository _apptRepo = AppointmentRepository();
  final AnnouncementRepository _annoRepo = AnnouncementRepository();
  final PatientRepository _patRepo = PatientRepository();
  final DoctorRepository _docRepo = DoctorRepository();

  final upcomingAppointments = <AppointmentModel>[].obs;
  final completedAppointments = <AppointmentModel>[].obs;
  final announcements = <AnnouncementModel>[].obs;
  final userName = ''.obs;
  final isLoading = false.obs;

  List<DoctorModel> _allDoctors = [];

  final searchResults = <DoctorModel>[].obs;
  final searchQuery = ''.obs;
  final isSearching = false.obs;
  final searchCtrl = TextEditingController();

  Timer? _searchDebounce;

  // Guards against stale clinic responses
  int _lastAcceptedClinicVersion = 0;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.onClose();
  }

  Future<void> loadData({
    bool forceRefresh = false,
    int? clinicVersion,
  }) async {
    final auth = Get.find<AuthController>();
    final requestVersion = clinicVersion ?? auth.clinicReloadVersion;
    final requestClinicId = auth.selectedClinic.value?.clinicId;

    isLoading.value = true;

    try {
      final results = await Future.wait([
        _patRepo.getMyProfile(),
        _apptRepo.listAppointments(forceRefresh: forceRefresh),
        _annoRepo.list(forceRefresh: forceRefresh),
        _docRepo.listDoctors(forceRefresh: forceRefresh),
      ]);

      final currentClinicId = auth.selectedClinic.value?.clinicId;
      final currentVersion = auth.clinicReloadVersion;

      final isStale =
          requestClinicId != currentClinicId ||
              requestVersion != currentVersion ||
              requestVersion < _lastAcceptedClinicVersion;

      if (isStale) {
        debugPrint(
          'PatientHomeController ignored stale response '
              'requestClinic=$requestClinicId currentClinic=$currentClinicId '
              'requestVersion=$requestVersion currentVersion=$currentVersion',
        );
        return;
      }

      _lastAcceptedClinicVersion = requestVersion;

      final profile = results[0] as PatientModel;
      final appts = results[1] as List<AppointmentModel>;
      final annos = results[2] as List<AnnouncementModel>;
      final doctors = results[3] as List<DoctorModel>;

      userName.value = profile.user.name;
      upcomingAppointments.assignAll(appts.where((a) => a.isUpcoming));
      completedAppointments.assignAll(appts.where((a) => a.isCompleted));
      announcements.assignAll(annos);
      _allDoctors = doctors;

      await Get.find<StorageProvider>().saveUserInfo(
        clinicId: profile.user.clinicId,
        role: profile.user.role,
        name: profile.user.name,
        email: profile.user.email,
      );

      if (searchQuery.value.trim().isNotEmpty) {
        _runFilter(searchQuery.value.trim().toLowerCase());
      } else {
        searchResults.clear();
        isSearching.value = false;
      }
    } catch (e) {
      final currentClinicId = auth.selectedClinic.value?.clinicId;
      final currentVersion = auth.clinicReloadVersion;

      final isStale =
          requestClinicId != currentClinicId ||
              requestVersion != currentVersion;

      if (isStale) {
        debugPrint('PatientHomeController ignored stale error: $e');
        return;
      }

      rethrow;
    } finally {
      final currentVersion = auth.clinicReloadVersion;
      if (requestVersion == currentVersion) {
        isLoading.value = false;
      }
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;

    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }

    isSearching.value = true;

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _runFilter(query.trim().toLowerCase());
    });
  }

  void _runFilter(String lower) {
    searchResults.value = _allDoctors.where((d) {
      return d.user.name.toLowerCase().contains(lower) ||
          (d.specialty?.name.toLowerCase().contains(lower) ?? false);
    }).toList();
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    searchCtrl.clear();
    searchQuery.value = '';
    isSearching.value = false;
    searchResults.clear();
  }
}

// ═══════════════════════════════════════════
// Doctor List (browsing & booking)
// ═══════════════════════════════════════════
class DoctorListController extends GetxController {
  final DoctorRepository _repo = DoctorRepository();
  final SpecialtyRepository _specRepo = SpecialtyRepository();

  final filteredDoctors = <DoctorModel>[].obs;
  final specialties = <SpecialtyModel>[].obs;
  final selectedSpecialty = Rxn<String>();
  final searchQuery = ''.obs;
  final isLoading = false.obs;

  List<DoctorModel> _doctors = [];
  Timer? _debounce;

  int _lastAcceptedClinicVersion = 0;

  @override
  void onInit() {
    super.onInit();
    loadDoctors();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
  String? _loadedClinicId;

  bool needsClinicRefresh() {
    final currentClinicId =
        Get.find<AuthController>().selectedClinic.value?.clinicId;
    return _loadedClinicId != currentClinicId;
  }
  Future<void> loadDoctors({
    bool forceRefresh = false,
    int? clinicVersion,
  }) async {
    final auth = Get.find<AuthController>();
    final currentClinicId = auth.selectedClinic.value?.clinicId;

    isLoading.value = true;

    try {
      final results = await Future.wait([
        _repo.listDoctors(forceRefresh: forceRefresh),
        _specRepo.list(forceRefresh: forceRefresh),
      ]);

      _doctors = List<DoctorModel>.from(results[0] as List<DoctorModel>);
      specialties.assignAll(results[1] as List<SpecialtyModel>);
      _loadedClinicId = currentClinicId;

      if (forceRefresh) {
        searchQuery.value = '';
        selectedSpecialty.value = null;
        _debounce?.cancel();
      }

      _applyFilters();
    } catch (e) {
      debugPrint('DoctorListController loadDoctors error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void setSearch(String query) {
    searchQuery.value = query;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _applyFilters);
  }

  void setSpecialtyFilter(String? specId) {
    selectedSpecialty.value = specId;
    _applyFilters();
  }

  void _applyFilters() {
    var result = _doctors.toList();

    final q = searchQuery.value.toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((d) {
        return d.user.name.toLowerCase().contains(q) ||
            (d.specialty?.name.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    final spec = selectedSpecialty.value;
    if (spec != null) {
      result = result.where((d) => d.profile.specialtyId == spec).toList();
    }

    filteredDoctors.assignAll(result);
  }
}

// ═══════════════════════════════════════════
// Booking
// ═══════════════════════════════════════════

class BookingController extends GetxController {
  final DoctorRepository _docRepo = DoctorRepository();
  final AppointmentRepository _apptRepo = AppointmentRepository();

  late final DoctorModel doctor;
  final selectedDate = Rxn<DateTime>();
  final availableSlots = <AvailableSlotModel>[].obs;
  final selectedSlot = Rxn<AvailableSlotModel>();
  final isLoadingSlots = false.obs;
  final isBooking = false.obs;

  void setDoctor(DoctorModel doc) => doctor = doc;

  Future<void> selectDate(DateTime date) async {
    selectedDate.value = date;
    selectedSlot.value = null;
    await _loadSlots(date);
  }

  Future<void> _loadSlots(DateTime date) async {
    isLoadingSlots.value = true;
    try {
      availableSlots.value = await _docRepo.getAvailableSlots(
        doctorId: doctor.profile.id,
        date: _formatDate(date),
      );
    } catch (_) {
      availableSlots.clear();
    } finally {
      // FIX 4: finally block.
      isLoadingSlots.value = false;
    }
  }

  void selectSlot(AvailableSlotModel slot) => selectedSlot.value = slot;

  Future<bool> confirmBooking() async {
    if (selectedDate.value == null || selectedSlot.value == null) return false;

    isBooking.value = true;
    try {
      await _apptRepo.bookAppointment(
        doctorId: doctor.profile.id,
        date: _formatDate(selectedDate.value!),
        startTime: selectedSlot.value!.startTime,
      );

      // FIX 5: reload slots after success so the booked slot disappears.
      selectedSlot.value = null;
      await _loadSlots(selectedDate.value!);
      return true;
    } on ApiException catch (e) {
      Get.snackbar(
        'فشل الحجز', e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.errorSoft,
        colorText: AppTheme.error,
      );

      // FIX 5: reload on failure too — another user may have taken the slot.
      if (selectedDate.value != null) await _loadSlots(selectedDate.value!);
      return false;
    } finally {
      isBooking.value = false;
    }
  }

  // Date formatting moved here (controller logic, not UI concern).
  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ═══════════════════════════════════════════
// Patient Appointments
// ═══════════════════════════════════════════


// ═══════════════════════════════════════════
// Patient Appointments
// ═══════════════════════════════════════════

class PatientAppointmentsController extends GetxController {
  final AppointmentRepository _repo = AppointmentRepository();

  final appointments = <AppointmentModel>[].obs;
  final statusFilter = ''.obs;
  final isLoading = false.obs;
  String? _loadedClinicId;

  List<AppointmentModel> _all = [];

  @override
  void onInit() {
    super.onInit();
    debugPrint('PatientAppointmentsController onInit = ${identityHashCode(this)}');
    loadAppointments();
  }

  Future<void> loadAppointments({
    bool forceRefresh = false,
    int? clinicVersion,
  }) async {
    final auth = Get.find<AuthController>();
    final currentClinicId = auth.selectedClinic.value?.clinicId;

    debugPrint(
      'PatientAppointmentsController loadAppointments = ${identityHashCode(this)} '
          'clinic=$currentClinicId forceRefresh=$forceRefresh',
    );

    isLoading.value = true;

    try {
      final result = await _repo.listAppointments(forceRefresh: forceRefresh);

      _all = List<AppointmentModel>.from(result);
      _loadedClinicId = currentClinicId;

      if (forceRefresh) {
        statusFilter.value = '';
      }

      _applyFilter();

      debugPrint(
        'PatientAppointmentsController applied ${appointments.length} visible items '
            'for clinic=$currentClinicId',
      );
    } catch (e) {
      debugPrint('PatientAppointmentsController loadAppointments error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  bool needsClinicRefresh() {
    final currentClinicId =
        Get.find<AuthController>().selectedClinic.value?.clinicId;
    return _loadedClinicId != currentClinicId;
  }



  void setFilter(String status) {
    statusFilter.value = status;
    _applyFilter();
  }

  void _applyFilter() {
    final filtered = statusFilter.value.isEmpty
        ? _all
        : _all.where((a) => a.status == statusFilter.value).toList();

    appointments.assignAll(filtered);
    appointments.refresh();
  }

  Future<void> cancelAppointment(String id, {String? reason}) async {
    try {
      await _repo.updateStatus(
        appointmentId: id,
        status: 'CANCELLED',
        cancellationReason: reason,
      );

      Get.snackbar(
        'تم الإلغاء',
        'تم إلغاء الموعد بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successSoft,
        colorText: AppTheme.success,
      );

      await loadAppointments(forceRefresh: true);
    } catch (e) {
      debugPrint('cancelAppointment error: $e');
    }
  }
}

// ═══════════════════════════════════════════
// Patient Profile
// ═══════════════════════════════════════════

class PatientProfileController extends GetxController {
  final PatientRepository _repo = PatientRepository();

  final profile = Rxn<PatientModel>();
  final isLoading = false.obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    try {
      profile.value = await _repo.getMyProfile();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    isSaving.value = true;
    try {
      profile.value = await _repo.updateMyProfile(data);
      Get.snackbar(
        'تم الحفظ', 'تم تحديث الملف الشخصي',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successSoft,
        colorText: AppTheme.success,
      );
    } finally {
      isSaving.value = false;
    }
  }
}

// ═══════════════════════════════════════════
// Patient Chat
// ═══════════════════════════════════════════
class PatientShellController extends GetxController {
  final currentIndex = 0.obs;

  void changeTab(int index) {
    debugPrint('Changing tab to $index');
    currentIndex.value = index;
  }
}

class PatientChatController extends GetxController {
  final ChatRepository _repo = ChatRepository();

  final messages = <ChatMessageModel>[].obs;
  final isLoading = false.obs;
  final isSending = false.obs;
  final messageCtrl = TextEditingController();

  late String _appointmentId;

  // FIX 7: poll timer so new messages from the doctor appear automatically.
  // Original called loadMessages() only once in setAppointmentId(). Any reply
  // the doctor sent after that was invisible until the screen was reopened.
  Timer? _pollTimer;

  @override
  void onClose() {
    messageCtrl.dispose();
    // FIX 7: cancel timer — a leaked timer calls update() on a disposed
    // controller and throws "Cannot use GetxController after closed."
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

      // FIX 7: deduplicate by message id.
      // When a poll fires while a previous request is still in flight,
      // both responses arrive and the list would render duplicate bubbles.
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