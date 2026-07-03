import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/config/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/patient_controllers.dart';
import 'patient_home_screen.dart';
import 'doctor_list_screen.dart';
import 'patient_appointments_screen.dart';
import 'patient_profile_screen.dart';

class PatientShell extends StatefulWidget {
  const PatientShell({super.key});

  @override
  State<PatientShell> createState() => PatientShellState();
}

class PatientShellState extends State<PatientShell> {
  int _idx = 0;
  static PatientShellState? _instance;

  @override
  void initState() {
    super.initState();
    _instance = this;
  }

  @override
  void dispose() {
    _instance = null;
    super.dispose();
  }

  static void switchTab(int index) {
    _instance?._setTab(index);
  }

  /// Refresh only the currently visible tab.
  /// Keep this for pull-to-refresh / explicit refresh use only.
  static Future<void> refreshCurrentTab() async {
    final idx = _instance?._idx ?? 0;

    try {
      switch (idx) {
        case 0:
          await Get.find<PatientHomeController>().loadData(forceRefresh: true);
          break;
        case 1:
          await Get.find<DoctorListController>().loadDoctors(forceRefresh: true);
          break;
        case 2:
          await Get.find<PatientAppointmentsController>().loadAppointments(
            forceRefresh: true,
          );
          break;
        case 3:
          await Get.find<PatientProfileController>().loadProfile();
          break;
      }
    } catch (e) {
      debugPrint('refreshCurrentTab error: $e');
    }
  }

  Future<void> _setTab(int index) async {
    if (!mounted) return;

    debugPrint('Changing tab to $index');

    if (_idx != index) {
      setState(() => _idx = index);
    }

    try {
      switch (index) {
        case 0:
          final ctrl = Get.find<PatientHomeController>();
          // optional similar helper there later
          break;

        case 1:
          final ctrl = Get.find<DoctorListController>();
          if (ctrl.needsClinicRefresh()) {
            await ctrl.loadDoctors(forceRefresh: true);
          }
          break;

        case 2:
          final ctrl = Get.find<PatientAppointmentsController>();
          if (ctrl.needsClinicRefresh()) {
            await ctrl.loadAppointments(forceRefresh: true);
          }
          break;

        case 3:
          break;
      }
    } catch (e) {
      debugPrint('Error while switching tab: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Obx(() {
      final clinicId = auth.selectedClinic.value?.clinicId ?? 'no_clinic';

      return Scaffold(
        resizeToAvoidBottomInset: true,
        body: IndexedStack(
          key: ValueKey('patient_shell_$clinicId'),
          index: _idx,
          children: [
            KeyedSubtree(
              key: ValueKey('home_$clinicId'),
              child: PatientHomeScreen(
                onBookAppointment: () => _setTab(1),
              ),
            ),
            KeyedSubtree(
              key: ValueKey('doctors_$clinicId'),
              child: const DoctorListScreen(),
            ),
            KeyedSubtree(
              key: ValueKey('appointments_$clinicId'),
              child: const PatientAppointmentsScreen(),
            ),
            KeyedSubtree(
              key: ValueKey('profile_$clinicId'),
              child: const PatientProfileScreen(),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: AppTheme.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_outlined, Icons.home_rounded, 'الرئيسية'),
                _navItem(1, Icons.search_rounded, Icons.search_rounded, 'الأطباء'),
                _navItem(
                  2,
                  Icons.calendar_today_outlined,
                  Icons.calendar_today_rounded,
                  'المواعيد',
                ),
                _navItem(
                  3,
                  Icons.person_outline_rounded,
                  Icons.person_rounded,
                  'حسابي',
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _navItem(int idx, IconData icon, IconData activeIcon, String label) {
    final isActive = _idx == idx;

    return GestureDetector(
      onTap: () => _setTab(idx),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppTheme.primary : AppTheme.textHint,
              size: 22,
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}