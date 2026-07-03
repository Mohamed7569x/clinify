import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/config/app_constants.dart';
import '../../../app/config/app_theme.dart';
import '../../../core/errors/api_exceptions.dart';
import '../../../data/models/clinic_model.dart';
import '../../../data/providers/cache_service.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../deep_link_service.dart';
import '../../../firebase_service.dart';
import '../../doctor/controllers/doctor_controllers.dart';
import '../../patient/controllers/patient_controllers.dart';
import '../../patient/views/patient_shell.dart';
import '../../shared/controllers/notification_controller.dart';

class JoinBranchItem {
  final String clinicUuid;
  final String clinicId;
  final String clinicName;
  final String? clinicSlug;
  final String? address;
  final String? phone;
  final String? logoUrl;
  final String? groupId;
  final String? groupName;
  final String? groupSlug;
  final String? area;
  final String? branchName;

  JoinBranchItem({
    required this.clinicUuid,
    required this.clinicId,
    required this.clinicName,
    this.clinicSlug,
    this.address,
    this.phone,
    this.logoUrl,
    this.groupId,
    this.groupName,
    this.groupSlug,
    this.area,
    this.branchName,
  });

  Map<String, dynamic> toJson() => {
    'clinic_uuid': clinicUuid,
    'clinic_id': clinicId,
    'clinic_name': clinicName,
    'clinic_slug': clinicSlug,
    'address': address,
    'phone': phone,
    'logo_url': logoUrl,
    'group_id': groupId,
    'group_name': groupName,
    'group_slug': groupSlug,
    'area': area,
    'branch_name': branchName,
  };

  factory JoinBranchItem.fromJson(Map<String, dynamic> json) {
    return JoinBranchItem(
      clinicUuid: json['clinic_uuid'].toString(),
      clinicId: json['clinic_id'].toString(),
      clinicName: json['clinic_name'].toString(),
      clinicSlug: json['clinic_slug']?.toString(),
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      logoUrl: json['logo_url']?.toString(),
      groupId: json['group_id']?.toString(),
      groupName: json['group_name']?.toString(),
      groupSlug: json['group_slug']?.toString(),
      branchName: json['branch_name']?.toString(),
      area: json['area']?.toString(),
    );
  }

  factory JoinBranchItem.fromMyClinic(MyClinicItem c) => JoinBranchItem(
    clinicUuid: c.clinicUuid,
    clinicId: c.clinicId,
    clinicName: c.clinicName,
    clinicSlug: c.branchSlug,
    groupId: c.groupId,
    groupName: c.groupName,
    groupSlug: c.groupSlug,
    branchName: c.branchName,
    area: c.area,
  );
}

class AuthController extends GetxController {
  final AuthRepository _repo = AuthRepository();

  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final obscureConfirm = true.obs;

  final clinicId = ''.obs;

  final loginFormKey = GlobalKey<FormState>();
  final registerFormKey = GlobalKey<FormState>();
  final showClinicCodeInput = false.obs;

  final clinicIdCtrl = TextEditingController();
  final identifierCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final regPasswordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  final selectedClinic = Rxn<JoinBranchItem>();
  final isResolvingClinic = false.obs;
  final isSearchingClinics = false.obs;
  final clinicSearchResults = <JoinBranchItem>[].obs;
  final clinicSearchGroups = <Map<String, dynamic>>[].obs;
  final clinicQuery = ''.obs;
  final myClinics = <MyClinicItem>[].obs;
  final isSwitchingClinic = false.obs;
  final isLoadingMyClinics = false.obs;

  late final DeepLinkService _deepLinkService;
  bool _deepLinksStarted = false;
  bool _deepLinkHandled = false;

  // ─────────────────────────────────────────────
  // Clinic context versioning
  // Any in-flight request from an older clinic context must be ignored
  // by controllers/repositories that receive this version.
  // ─────────────────────────────────────────────
  final _clinicReloadVersion = 0.obs;

  int bumpClinicReloadVersion() {
    _clinicReloadVersion.value++;
    debugPrint('clinic reload version -> ${_clinicReloadVersion.value}');
    return _clinicReloadVersion.value;
  }

  int get clinicReloadVersion => _clinicReloadVersion.value;

  @override
  void onInit() {
    super.onInit();
    _deepLinkService = DeepLinkService();
  }

  @override
  void onClose() {
    clinicIdCtrl.dispose();
    identifierCtrl.dispose();
    passwordCtrl.dispose();
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    regPasswordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    _deepLinkService.dispose();
    super.onClose();
  }

  // ═══════════════════════════════════════════
  // Clinic-scoped data reload
  // ═══════════════════════════════════════════

  Future<void> _reloadClinicScopedData({required int version}) async {
    try {
      final cache = Get.find<CacheService>();

      // Since caches are now clinic-scoped, clearing by prefix is safer.
      // If you want to preserve each clinic's cache for later reuse,
      // you can remove this block entirely and rely on forceRefresh only.
      await cache.removeByPrefix('doctors_');
      await cache.removeByPrefix('specialties_');
      await cache.removeByPrefix('appointments_');
      await cache.removeByPrefix('announcements_');
      await cache.removeByPrefix('notifications_');
      await cache.removeByPrefix('unread_count_');
      await cache.removeByPrefix('schedules_');
      await cache.removeByPrefix('blocked_slots_');
    } catch (e) {
      debugPrint('cache clear failed: $e');
    }

    final futures = <Future<void>>[];

    if (Get.isRegistered<PatientHomeController>()) {
      futures.add(_safeReload(
        'PatientHome',
            () => Get.find<PatientHomeController>().loadData(
          forceRefresh: true,
          clinicVersion: version,
        ),
      ));
    }

    if (Get.isRegistered<NotificationController>()) {
      final notif = Get.find<NotificationController>();

      futures.add(_safeReload(
        'NotificationUnread',
            () => notif.fetchUnreadCount(
          forceRefresh: true,
          clinicVersion: version,
        ),
      ));

      futures.add(_safeReload(
        'NotificationList',
            () => notif.loadNotifications(
          forceRefresh: true,
          clinicVersion: version,
        ),
      ));
    }

    if (Get.isRegistered<PatientAppointmentsController>()) {
      futures.add(_safeReload(
        'PatientAppointments',
            () => Get.find<PatientAppointmentsController>().loadAppointments(
          forceRefresh: true,
          clinicVersion: version,
        ),
      ));
    }

    if (Get.isRegistered<DoctorHomeController>()) {
      futures.add(_safeReload(
        'DoctorHome',
            () => Get.find<DoctorHomeController>().loadData(
          forceRefresh: true,
          clinicVersion: version,
        ),
      ));
    }

    if (Get.isRegistered<DoctorAppointmentsController>()) {
      futures.add(_safeReload(
        'DoctorAppointments',
            () => Get.find<DoctorAppointmentsController>().loadAppointments(
          forceRefresh: true,
          clinicVersion: version,
        ),
      ));
    }

    if (Get.isRegistered<DoctorListController>()) {
      futures.add(_safeReload(
        'DoctorList',
            () => Get.find<DoctorListController>().loadDoctors(
          forceRefresh: true,
          clinicVersion: version,
        ),
      ));
    }

    await Future.wait(futures).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        debugPrint('_reloadClinicScopedData timed out');
        return [];
      },
    );
  }

  Future<void> _safeReload(
      String label,
      Future<void> Function() action,
      ) async {
    try {
      await action();
    } catch (e) {
      debugPrint('reload $label failed: $e');
    }
  }

  void _disposeClinicScopedControllers() {
    if (Get.isRegistered<PatientHomeController>()) {
      Get.delete<PatientHomeController>(force: true);
    }
    if (Get.isRegistered<PatientAppointmentsController>()) {
      Get.delete<PatientAppointmentsController>(force: true);
    }
    if (Get.isRegistered<DoctorHomeController>()) {
      Get.delete<DoctorHomeController>(force: true);
    }
    if (Get.isRegistered<DoctorAppointmentsController>()) {
      Get.delete<DoctorAppointmentsController>(force: true);
    }
    if (Get.isRegistered<DoctorListController>()) {
      Get.delete<DoctorListController>(force: true);
    }
    if (Get.isRegistered<NotificationController>()) {
      Get.delete<NotificationController>(force: true);
    }
  }

  // ═══════════════════════════════════════════
  // Splash / Session
  // ═══════════════════════════════════════════

  Future<void> checkSession() async {
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!_deepLinksStarted) {
      _deepLinksStarted = true;
      _deepLinkService.startListening((uri) async {
        await handleIncomingUri(uri);
      });
    }

    if (Get.currentRoute.startsWith('/join/')) {
      debugPrint('join route active, skip normal session routing');
      return;
    }

    final initialUri = await _deepLinkService.getInitialUri();
    debugPrint('initialUri: $initialUri');
    if (initialUri != null) {
      final handled = await handleIncomingUri(initialUri);
      if (handled) return;
    }

    final hasSession = await _repo.hasSession();
    debugPrint('hasSession: $hasSession');

    if (!hasSession) {
      await Get.offAllNamed('/clinic-id');
      return;
    }

    await restoreSelectedClinic();

    if (_deepLinkHandled || Get.currentRoute.startsWith('/join/')) {
      return;
    }

    final role = await _repo.getSavedRole();
    await _navigateByRole(role);
  }

  // ═══════════════════════════════════════════
  // Clinic selection
  // ═══════════════════════════════════════════

  String get resolvedClinicId =>
      selectedClinic.value?.clinicId ?? clinicId.value.trim().toUpperCase();

  bool get hasSelectedClinic => selectedClinic.value != null;

  String get selectedClinicDisplayName {
    final c = selectedClinic.value;
    if (c == null) return '';
    final area = (c.area ?? '').trim();
    if (area.isEmpty) return c.clinicName;
    return '${c.clinicName} - $area';
  }

  void openClinicCodeInput() {
    showClinicCodeInput.value = true;
    clinicSearchResults.clear();
    clinicSearchGroups.clear();
    clinicQuery.value = '';
  }

  void openSearchMode() {
    showClinicCodeInput.value = false;
    clinicIdCtrl.clear();
  }

  Future<void> loadMyClinics() async {
    try {
      isLoadingMyClinics.value = true;
      final data = await _repo.getMyClinics();
      final items = (data['items'] as List? ?? [])
          .map((e) => MyClinicItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      myClinics.assignAll(items);
    } catch (_) {
      myClinics.clear();
    } finally {
      isLoadingMyClinics.value = false;
    }
  }

  Future<void> switchClinic(
      MyClinicItem clinic, {
        bool showSuccessMessage = true,
        bool showLoadingOverlay = true,
        bool reloadScopedData = false, // default false now
      }) async {
    if (isSwitchingClinic.value) return;

    final currentClinicId = selectedClinic.value?.clinicId;
    if (currentClinicId == clinic.clinicId) {
      debugPrint('switchClinic skipped: already on same clinic');
      return;
    }

    if (showLoadingOverlay) _openLoadingOverlay();

    try {
      isSwitchingClinic.value = true;

      await _repo.switchClinic(clinic.clinicId);

      myClinics.value = myClinics
          .map((c) => c.copyWith(isCurrent: c.clinicId == clinic.clinicId))
          .toList();

      setSelectedClinic(JoinBranchItem.fromMyClinic(clinic));

      bumpClinicReloadVersion();
      await PatientShellState.refreshCurrentTab();

      try {
        await Get.find<NotificationController>().fetchUnreadCount(forceRefresh: true);
        await Get.find<NotificationController>().loadNotifications(forceRefresh: true);
      } catch (_) {}

      if (reloadScopedData) {
        await _reloadClinicScopedData(version: clinicReloadVersion);
      }

      if (showLoadingOverlay) _closeLoadingOverlay();

      if (showSuccessMessage) {
        _showSuccess('Clinic switched successfully');
      }
    } on ApiException catch (e) {
      if (showLoadingOverlay) _closeLoadingOverlay();
      _showError(e.message);
      rethrow;
    } catch (_) {
      if (showLoadingOverlay) _closeLoadingOverlay();
      _showError('Failed to switch clinic');
      rethrow;
    } finally {
      isSwitchingClinic.value = false;
    }
  }

  void _openLoadingOverlay() {
    if (Get.isDialogOpen ?? false) return;
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
      barrierColor: Colors.black38,
      name: 'clinic_switch_loader',
    );
  }

  void _closeLoadingOverlay() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  Future<void> restoreSelectedClinic() async {
    try {
      final cache = Get.find<CacheService>();
      final cached = cache.get(CK.selectedClinic);
      if (cached is Map) {
        final clinic = JoinBranchItem.fromJson(
          Map<String, dynamic>.from(cached),
        );
        selectedClinic.value = clinic;
        clinicId.value = clinic.clinicId.trim().toUpperCase();
        clinicIdCtrl.text = clinic.clinicId.trim().toUpperCase();
        debugPrint(
          'restored from cache: ${clinic.clinicId}, area="${clinic.area}"',
        );
      } else {
        debugPrint('no cached selected clinic');
      }
    } catch (e) {
      debugPrint('restoreSelectedClinic cache read error: $e');
    }

    unawaited(_refreshSelectedClinicFromServer());
  }

  Future<void> _refreshSelectedClinicFromServer() async {
    try {
      await loadMyClinics();
      if (myClinics.isEmpty) return;

      final savedClinicId = await _repo.getSavedClinicId();

      MyClinicItem? target = myClinics.firstWhereOrNull((c) => c.isCurrent);
      target ??= (savedClinicId != null && savedClinicId.isNotEmpty)
          ? myClinics.firstWhereOrNull((c) => c.clinicId == savedClinicId)
          : null;
      target ??= myClinics.length == 1 ? myClinics.first : null;

      if (target == null) {
        debugPrint('could not determine current clinic');
        return;
      }

      final current = selectedClinic.value;
      final shouldUpdate = current == null ||
          current.clinicId != target.clinicId ||
          current.area != target.area ||
          current.branchName != target.branchName;

      if (shouldUpdate) {
        setSelectedClinic(JoinBranchItem.fromMyClinic(target));
        debugPrint(
          'refreshed from server: ${target.clinicId}, area="${target.area}"',
        );
      }
    } catch (e) {
      debugPrint('_refreshSelectedClinicFromServer error: $e');
    }
  }

  void chooseClinic(JoinBranchItem clinic) {
    FocusManager.instance.primaryFocus?.unfocus();
    setSelectedClinic(clinic);
    clinicSearchResults.clear();
    clinicSearchGroups.clear();
    clinicQuery.value = '';
  }

  void setSelectedClinic(JoinBranchItem clinic) {
    selectedClinic.value = clinic;
    clinicId.value = clinic.clinicId.trim().toUpperCase();
    clinicIdCtrl.text = clinic.clinicId.trim().toUpperCase();
    try {
      Get.find<CacheService>().put(CK.selectedClinic, clinic.toJson());
    } catch (_) {}
  }

  void clearSelectedClinic() {
    selectedClinic.value = null;
    clinicId.value = '';
    clinicIdCtrl.clear();
    clinicSearchResults.clear();
    clinicSearchGroups.clear();
    clinicQuery.value = '';
    try {
      Get.find<CacheService>().remove(CK.selectedClinic);
    } catch (_) {}
  }

  Future<bool> resolveClinicByCode([String? rawCode]) async {
    final code = (rawCode ?? clinicIdCtrl.text).trim().toUpperCase();
    if (code.isEmpty) {
      _showError('Enter clinic code');
      return false;
    }

    try {
      isResolvingClinic.value = true;
      final data = await _repo.resolveClinicByCode(code);
      final clinic = JoinBranchItem.fromJson(
        Map<String, dynamic>.from(data['clinic'] as Map),
      );
      setSelectedClinic(clinic);
      return true;
    } on ApiException catch (e) {
      clearSelectedClinic();
      _showError(e.message);
      return false;
    } catch (_) {
      clearSelectedClinic();
      _showError('Failed to find clinic. Please try again.');
      return false;
    } finally {
      isResolvingClinic.value = false;
    }
  }

  Future<void> searchClinics(String query) async {
    final q = query.trim();
    clinicQuery.value = q;

    if (q.isEmpty) {
      clinicSearchResults.clear();
      clinicSearchGroups.clear();
      return;
    }

    try {
      isSearchingClinics.value = true;
      final data = await _repo.searchClinics(q);

      final rawGroups = (data['groups'] as List? ?? []);
      final rawBranches = (data['branches'] as List? ?? []);

      clinicSearchGroups.assignAll(
        rawGroups.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      );
      clinicSearchResults.assignAll(
        rawBranches
            .map((e) =>
            JoinBranchItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (e, s) {
      debugPrint('searchClinics error: $e\n$s');
      clinicSearchGroups.clear();
      clinicSearchResults.clear();
    } finally {
      isSearchingClinics.value = false;
    }
  }

  Future<bool> resolveBranchBySlug(String slug) async {
    final value = slug.trim();
    if (value.isEmpty) return false;

    try {
      isResolvingClinic.value = true;
      final data = await _repo.resolveBranchBySlug(value);
      final clinic = JoinBranchItem.fromJson(
        Map<String, dynamic>.from(data['clinic'] as Map),
      );
      setSelectedClinic(clinic);
      return true;
    } on ApiException catch (e) {
      _showError(e.message);
      return false;
    } catch (_) {
      _showError('Failed to open clinic link.');
      return false;
    } finally {
      isResolvingClinic.value = false;
    }
  }

  Future<Map<String, dynamic>?> resolveGroupBySlug(String slug) async {
    final value = slug.trim();
    if (value.isEmpty) return null;

    try {
      isResolvingClinic.value = true;
      return await _repo.resolveGroupBySlug(value);
    } on ApiException catch (e) {
      _showError(e.message);
      return null;
    } catch (_) {
      _showError('Failed to open clinic group.');
      return null;
    } finally {
      isResolvingClinic.value = false;
    }
  }

  Future<void> submitClinicId() async {
    final ok = await resolveClinicByCode(clinicIdCtrl.text);
    if (!ok) return;
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.lightImpact();
  }

  // ═══════════════════════════════════════════
  // Deep link handling
  // ═══════════════════════════════════════════

  Future<bool> handleIncomingUri(Uri uri) async {
    try {
      debugPrint('incoming deep link: $uri');

      final (type, value) = _parseJoinUri(uri);
      if (type == null || value == null) {
        debugPrint('deep link format not recognized');
        return false;
      }

      final targetClinic = await _resolveTargetClinic(type, value);
      if (targetClinic == null) return false;

      debugPrint('target clinic from link: ${targetClinic.clinicId}');

      final hasSession = await _repo.hasSession();

      if (!hasSession) {
        setSelectedClinic(targetClinic);
        _deepLinkHandled = true;
        await Get.offAllNamed('/login');
        return true;
      }

      final savedClinicId = await _repo.getSavedClinicId();
      if (savedClinicId == targetClinic.clinicId) {
        _deepLinkHandled = true;
        final role = await _repo.getSavedRole();
        await _navigateByRole(role);
        return true;
      }

      await loadMyClinics();
      final matchedClinic = myClinics.firstWhereOrNull(
            (c) => c.clinicId == targetClinic.clinicId,
      );

      if (matchedClinic != null) {
        try {
          // Do not reload old controller tree before navigation.
          await switchClinic(
            matchedClinic,
            showSuccessMessage: false,
            showLoadingOverlay: true,
            reloadScopedData: false,
          );
        } catch (_) {
          // Error already shown
        }

        _deepLinkHandled = true;
        final role = await _repo.getSavedRole();
        await _navigateByRole(role);

        // Wait until new route/controller tree is mounted
        // await Future.delayed(const Duration(milliseconds: 120));

        // final version = clinicReloadVersion;
        // await _reloadClinicScopedData(version: version);
        return true;
      }

      _deepLinkHandled = true;
      _showError('This account is not linked to that clinic yet');
      final role = await _repo.getSavedRole();
      await _navigateByRole(role);
      return true;
    } catch (e) {
      debugPrint('handleIncomingUri error: $e');
      return false;
    }
  }

  (String?, String?) _parseJoinUri(Uri uri) {
    final segments = uri.pathSegments;

    if (segments.length >= 3 && segments[0] == 'join') {
      return (segments[1], segments[2]);
    }

    if (uri.host == 'join' && segments.length >= 2) {
      return (segments[0], segments[1]);
    }

    return (null, null);
  }

  Future<JoinBranchItem?> _resolveTargetClinic(
      String type,
      String value,
      ) async {
    try {
      if (type == 'branch') {
        final data = await _repo.resolveBranchBySlug(value);
        return JoinBranchItem.fromJson(
          Map<String, dynamic>.from(data['clinic'] as Map),
        );
      }
      if (type == 'code') {
        final data = await _repo.resolveClinicByCode(value);
        return JoinBranchItem.fromJson(
          Map<String, dynamic>.from(data['clinic'] as Map),
        );
      }
      if (type == 'group') {
        final data = await _repo.resolveGroupBySlug(value);
        final branches = (data['branches'] as List? ?? []);
        if (branches.length == 1) {
          return JoinBranchItem.fromJson(
            Map<String, dynamic>.from(branches.first as Map),
          );
        }
        debugPrint('group deep link has multiple branches; picker not yet built');
        return null;
      }
      debugPrint('unsupported deep link type: $type');
      return null;
    } on ApiException catch (e) {
      _showError(e.message);
      return null;
    } catch (e) {
      debugPrint('_resolveTargetClinic error: $e');
      return null;
    }
  }

  Future<void> handleQrResult(String rawValue) async {
    try {
      final uri = Uri.parse(rawValue);
      final handled = await handleIncomingUri(uri);
      if (!handled) _showError('Invalid link');
    } catch (_) {
      _showError('Failed to read QR code');
    }
  }

  // ═══════════════════════════════════════════
  // Login
  // ═══════════════════════════════════════════

  Future<void> login() async {
    if (!loginFormKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      final result = await _repo.clinicLogin(
        clinicId: resolvedClinicId,
        identifier: identifierCtrl.text.trim(),
        password: passwordCtrl.text,
      );
      final role = result['role'] as String?;

      try {
        final firebase = Get.find<FirebaseService>();
        await firebase.sendSavedToken();
      } catch (_) {}

      _showSuccess('Logged in successfully');
      await _navigateByRole(role);
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // ═══════════════════════════════════════════
  // Register
  // ═══════════════════════════════════════════

  Future<void> registerPatient() async {
    if (!registerFormKey.currentState!.validate()) return;

    if (emailCtrl.text.trim().isEmpty && phoneCtrl.text.trim().isEmpty) {
      _showError('Please enter email or phone number');
      return;
    }

    isLoading.value = true;
    try {
      await _repo.registerPatient(
        clinicId: resolvedClinicId,
        name: nameCtrl.text.trim(),
        email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
        phoneNumber:
        phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
        password: regPasswordCtrl.text,
      );
      _showSuccess('Registered successfully. Please wait for clinic approval.');
      _clearRegisterFields();
      await Get.offNamed('/login');
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Registration failed. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // ═══════════════════════════════════════════
  // Logout
  // ═══════════════════════════════════════════

  Future<void> logout() async {
    await _repo.logout();
    try {
      Get.find<CacheService>().clearAll();
    } catch (_) {}
    _clearAllFields();
    await Get.offAllNamed('/clinic-id');
  }

  // ═══════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════

  Future<void> _navigateByRole(String? role) async {
    switch (role) {
      case AppConstants.roleDoctor:
        await Get.offAllNamed('/doctor');
        break;
      case AppConstants.rolePatient:
        await Get.offAllNamed('/patient');
        break;
      default:
        await Get.offAllNamed('/clinic-id');
    }
  }

  void _clearRegisterFields() {
    nameCtrl.clear();
    emailCtrl.clear();
    phoneCtrl.clear();
    regPasswordCtrl.clear();
    confirmPasswordCtrl.clear();
  }

  void _clearAuthFieldsOnly() {
    identifierCtrl.clear();
    passwordCtrl.clear();
    _clearRegisterFields();
  }

  void _clearAllFields() {
    _clearAuthFieldsOnly();
    clearSelectedClinic();
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.errorSoft,
      colorText: AppTheme.error,
      icon: const Icon(Icons.error_outline_rounded, color: AppTheme.error),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
      borderRadius: 12,
    );
  }

  void _showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.successSoft,
      colorText: AppTheme.success,
      icon: const Icon(
        Icons.check_circle_outline_rounded,
        color: AppTheme.success,
      ),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
      borderRadius: 12,
    );
  }
}