import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/config/app_theme.dart';
import '../controllers/doctor_controllers.dart';
import '../../shared/controllers/notification_controller.dart';
import 'doctor_home_screen.dart';
import 'doctor_all_screens.dart';

class DoctorShell extends StatefulWidget {
  const DoctorShell({super.key});
  @override
  State<DoctorShell> createState() => DoctorShellState();
}

class DoctorShellState extends State<DoctorShell> {
  int _idx = 0;
  static DoctorShellState? _instance;

  @override
  void initState() { super.initState(); _instance = this; }
  @override
  void dispose() { _instance = null; super.dispose(); }

  static Future<void> refreshCurrentTab() async {
    final idx = _instance?._idx ?? 0;
    try {
      switch (idx) {
        case 0: await Get.find<DoctorHomeController>().loadData(); break;
        case 1: await Get.find<DoctorAppointmentsController>().loadAppointments(); break;
        case 2: await Get.find<ScheduleController>().loadAll(); break;
      }
      try { Get.find<NotificationController>().loadNotifications(); } catch (_) {}
    } catch (_) {}
  }

  final _screens = const [DoctorHomeScreen(), DoctorAppointmentsScreen(), ScheduleScreen(), DoctorProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        decoration: BoxDecoration(color: AppTheme.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, -4))]),
        child: SafeArea(top: false, child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _nav(0, Icons.home_outlined, Icons.home_rounded, 'الرئيسية'),
          _nav(1, Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'المواعيد'),
          _nav(2, Icons.schedule_outlined, Icons.schedule_rounded, 'الجدول'),
          _nav(3, Icons.person_outline_rounded, Icons.person_rounded, 'حسابي'),
        ])),
      ),
    );
  }

  Widget _nav(int i, IconData icon, IconData active, String label) {
    final a = _idx == i;
    return GestureDetector(
      onTap: () => setState(() => _idx = i),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: a ? 16 : 12, vertical: 8),
        decoration: BoxDecoration(color: a ? AppTheme.primaryLight : Colors.transparent, borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(a ? active : icon, color: a ? AppTheme.primary : AppTheme.textHint, size: 22),
          if (a) ...[const SizedBox(width: 6), Text(label, style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w700))],
        ]),
      ),
    );
  }
}