import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/config/app_theme.dart';
import '../../../widgets/shared_widgets.dart';
import '../../../data/providers/storage_provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/doctor_controllers.dart';

// ─────────────────────────────────────────────
// Shared constants
// ─────────────────────────────────────────────
const _kCardShadow = [
  BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 2)),
];
const _kCardDecoration = BoxDecoration(
  color: AppTheme.white,
  borderRadius: BorderRadius.all(Radius.circular(16)),
  boxShadow: _kCardShadow,
);
const _kSmallShadow = [
  BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 2)),
];
const _kMenuShadow = [
  BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2)),
];
const _kChatOtherShadow = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
];
const _kInputBarShadow = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, -2)),
];

// ─────────────────────────────────────────────
// Month helper — static, not per-instance
// ─────────────────────────────────────────────
String _monthAr(String d) {
  const months = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];
  try {
    return months[int.parse(d.split('-')[1]) - 1];
  } catch (_) {
    return '';
  }
}

// ═══════════════════════════════════════════
// Doctor Appointments Screen
// ═══════════════════════════════════════════
class DoctorAppointmentsScreen extends GetView<DoctorAppointmentsController> {
  const DoctorAppointmentsScreen({super.key});

  static const _tabs = ['', 'PENDING', 'CONFIRMED', 'COMPLETED', 'CANCELLED'];
  static const _labels = ['الكل', 'بانتظار', 'مؤكد', 'مكتمل', 'ملغي'];

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          // ── Header ──
          Container(
            color: AppTheme.white,
            padding: EdgeInsets.only(
              top: topPadding + 12,
              left: 20,
              right: 20,
              bottom: 12,
            ),
            child: const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'المواعيد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          // ── Filter tabs ──
          _DoctorFilterTabs(tabs: _tabs, labels: _labels, controller: controller),

          // ── Content ──
          Expanded(child: _DoctorAppointmentsList(controller: controller)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Filter tabs
// ─────────────────────────────────────────────
class _DoctorFilterTabs extends StatelessWidget {
  final List<String> tabs;
  final List<String> labels;
  final DoctorAppointmentsController controller;

  const _DoctorFilterTabs({
    required this.tabs,
    required this.labels,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.white,
      height: 44,
      child: Obx(() {
        final filter = controller.statusFilter.value;
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: tabs.length,
          addRepaintBoundaries: true,
          addAutomaticKeepAlives: false,
          itemBuilder: (_, i) => _TabChip(
            label: labels[i],
            selected: filter == tabs[i],
            onTap: () => controller.setFilter(tabs[i]),
          ),
        );
      }),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(left: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.inputBg,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Appointments list
// ─────────────────────────────────────────────
class _DoctorAppointmentsList extends StatelessWidget {
  final DoctorAppointmentsController controller;

  const _DoctorAppointmentsList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final appts = controller.appointments.toList();

      if (controller.isLoading.value && appts.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        );
      }

      if (appts.isEmpty) {
        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () => controller.loadAppointments(forceRefresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: const [
              SizedBox(height: 80),
              EmptyState(
                icon: Icons.calendar_today_outlined,
                title: 'لا توجد مواعيد',
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => controller.loadAppointments(forceRefresh: true),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          itemCount: appts.length,
          cacheExtent: 400,
          addRepaintBoundaries: true,
          addAutomaticKeepAlives: false,
          itemBuilder: (_, i) => _DoctorApptCard(
            key: ValueKey(appts[i].id.toString()),
            a: appts[i],
            controller: controller,
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────
// Doctor appointment card
// ─────────────────────────────────────────────
class _DoctorApptCard extends StatelessWidget {
  final dynamic a;
  final DoctorAppointmentsController controller;

  const _DoctorApptCard({
    super.key,
    required this.a,
    required this.controller,
  });

  String _time5(dynamic v) {
    final s = v?.toString() ?? '';
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = a.date?.toString() ?? '';
    final parts = dateStr.split('-');
    final day = parts.isNotEmpty ? parts.last : '';
    final month = _monthAr(dateStr);
    final startTime = _time5(a.startTime);
    final endTime = _time5(a.endTime);
    final patientName = a.patientName?.toString().trim().isNotEmpty == true
        ? a.patientName.toString()
        : 'مريض';
    final appointmentId = a.id.toString();
    final status = a.status.toString();

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: _kCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _DateBadge(day: day, month: month),
                const SizedBox(width: 12),
                Expanded(
                  child: _PatientInfo(
                    patientName: patientName,
                    startTime: startTime,
                    endTime: endTime,
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status),
              ],
            ),
            const SizedBox(height: 12),
            _DoctorActionButtons(
              a: a,
              appointmentId: appointmentId,
              patientName: patientName,
              controller: controller,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final String day;
  final String month;

  const _DateBadge({required this.day, required this.month});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
              height: 1,
            ),
          ),
          Text(
            month,
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientInfo extends StatelessWidget {
  final String patientName;
  final String startTime;
  final String endTime;

  const _PatientInfo({
    required this.patientName,
    required this.startTime,
    required this.endTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          patientName.isNotEmpty ? patientName : 'مريض',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          '$startTime – $endTime',
          textDirection: TextDirection.ltr,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Doctor action buttons
// ─────────────────────────────────────────────
class _DoctorActionButtons extends StatelessWidget {
  final dynamic a;
  final String appointmentId;
  final String patientName;
  final DoctorAppointmentsController controller;

  const _DoctorActionButtons({
    required this.a,
    required this.appointmentId,
    required this.patientName,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (a.isPending) ...[
          _ActionChip(
            label: 'تأكيد',
            icon: Icons.check_rounded,
            color: AppTheme.success,
            bg: AppTheme.successSoft,
            onTap: () => _showConfirmAction(
              context,
              title: 'تأكيد الموعد',
              message: 'هل تريد تأكيد موعد $patientName؟',
              newStatus: 'CONFIRMED',
              a: a,
            ),
          ),
          _ActionChip(
            label: 'إلغاء',
            icon: Icons.close_rounded,
            color: AppTheme.error,
            bg: AppTheme.errorSoft,
            onTap: () => _showNotesDialog(
              context,
              id: appointmentId,
              status: 'CANCELLED',
              hint: 'سبب الإلغاء',
              patientName: patientName,
            ),
          ),
        ],
        if (a.isConfirmed) ...[
          _ActionChip(
            label: 'إتمام',
            icon: Icons.done_all_rounded,
            color: AppTheme.success,
            bg: AppTheme.successSoft,
            onTap: () => _showNotesDialog(
              context,
              id: appointmentId,
              status: 'COMPLETED',
              hint: 'ملاحظات الكشف',
              patientName: patientName,
            ),
          ),
          _ActionChip(
            label: 'لم يحضر',
            icon: Icons.person_off_outlined,
            color: AppTheme.warning,
            bg: AppTheme.warningSoft,
            onTap: () => _showConfirmAction(
              context,
              title: 'لم يحضر',
              message: 'هل تريد تسجيل عدم حضور $patientName؟',
              newStatus: 'NO_SHOW',
              a: a,
            ),
          ),
          _ActionChip(
            label: 'محادثة',
            icon: Icons.chat_bubble_outline,
            color: AppTheme.primary,
            bg: AppTheme.primaryLight,
            onTap: () => Get.toNamed('/doctor/chat', arguments: appointmentId),
          ),
          _ActionChip(
            label: 'وصفة',
            icon: Icons.medication_outlined,
            color: AppTheme.purple,
            bg: AppTheme.purpleSoft,
            onTap: () => Get.toNamed('/doctor/add-prescription', arguments: appointmentId),
          ),
        ],
        if (a.isCompleted) ...[
          _ActionChip(
            label: 'محادثة',
            icon: Icons.chat_bubble_outline,
            color: AppTheme.primary,
            bg: AppTheme.primaryLight,
            onTap: () => Get.toNamed('/doctor/chat', arguments: appointmentId),
          ),
          _ActionChip(
            label: 'الوصفات',
            icon: Icons.medication_outlined,
            color: AppTheme.purple,
            bg: AppTheme.purpleSoft,
            onTap: () => Get.toNamed('/doctor/prescriptions', arguments: appointmentId),
          ),
        ],
      ],
    );
  }

  void _showConfirmAction(
      BuildContext ctx, {
        required String title,
        required String message,
        required String newStatus,
        required dynamic a,
      }) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppTheme.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _ConfirmActionSheet(
        title: title,
        message: message,
        newStatus: newStatus,
        onConfirm: () {
          Get.back();
          final previousStatus = a.status.toString();
          controller.updateStatus(a.id.toString(), newStatus);
          _showUndo(ctx, a.id.toString(), previousStatus);
        },
      ),
    );
  }

  void _showNotesDialog(
      BuildContext ctx, {
        required String id,
        required String status,
        required String hint,
        required String patientName,
      }) {
    final nc = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => _NotesDialog(
        status: status,
        hint: hint,
        patientName: patientName,
        notesController: nc,
        onConfirm: () {
          Get.back();
          controller.updateStatus(
            id,
            status,
            notes: nc.text.trim().isNotEmpty ? nc.text.trim() : null,
          );
        },
      ),
    );
  }

  void _showUndo(BuildContext ctx, String apptId, String previousStatus) {
    Get.snackbar(
      'تم التحديث',
      'تم تحديث حالة الموعد',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.successSoft,
      colorText: AppTheme.success,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 5),
      mainButton: TextButton(
        onPressed: () {
          Get.closeCurrentSnackbar();
          controller.updateStatus(apptId, previousStatus);
        },
        child: const Text(
          'تراجع',
          style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Confirm action bottom sheet
// ─────────────────────────────────────────────
class _ConfirmActionSheet extends StatelessWidget {
  final String title;
  final String message;
  final String newStatus;
  final VoidCallback onConfirm;

  const _ConfirmActionSheet({
    required this.title,
    required this.message,
    required this.newStatus,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final isNoShow = newStatus == 'NO_SHOW';
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isNoShow ? AppTheme.warningSoft : AppTheme.successSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isNoShow
                  ? Icons.person_off_outlined
                  : Icons.check_circle_outline_rounded,
              color: isNoShow ? AppTheme.warning : AppTheme.success,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: Get.back,
                  child: const Text('إلغاء'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  child: const Text('تأكيد'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Notes dialog (cancel / complete)
// ─────────────────────────────────────────────
class _NotesDialog extends StatelessWidget {
  final String status;
  final String hint;
  final String patientName;
  final TextEditingController notesController;
  final VoidCallback onConfirm;

  const _NotesDialog({
    required this.status,
    required this.hint,
    required this.patientName,
    required this.notesController,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == 'COMPLETED';
    return Dialog(
      backgroundColor: AppTheme.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isCompleted ? AppTheme.successSoft : AppTheme.errorSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isCompleted
                    ? Icons.check_circle_outline_rounded
                    : Icons.cancel_outlined,
                color: isCompleted ? AppTheme.success : AppTheme.error,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isCompleted ? 'إتمام الموعد' : 'إلغاء الموعد',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isCompleted
                  ? 'إتمام موعد $patientName'
                  : 'إلغاء موعد $patientName',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(hintText: hint),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: Get.back,
                    child: const Text('رجوع'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      isCompleted ? AppTheme.primary : AppTheme.error,
                    ),
                    child: Text(isCompleted ? 'إتمام' : 'إلغاء'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Schedule Screen
// ═══════════════════════════════════════════
class ScheduleScreen extends GetView<ScheduleController> {
  const ScheduleScreen({super.key});

  static const _days = [
    'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY',
    'FRIDAY', 'SATURDAY', 'SUNDAY',
  ];
  static const _dayAr = [
    'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس',
    'الجمعة', 'السبت', 'الأحد',
  ];

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }
        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: controller.loadAll,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  color: AppTheme.white,
                  padding: EdgeInsets.only(
                    top: topPadding + 12,
                    left: 20,
                    right: 20,
                    bottom: 16,
                  ),
                  child: const Text(
                    'جدول العمل',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              // ── Weekly header ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'الجدول الأسبوعي',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // ── Weekly list ──
              if (controller.schedules.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: EmptyState(
                      icon: Icons.schedule_outlined,
                      title: 'لا يوجد جدول',
                      subtitle: 'اضغط + لتحديد مواعيد عملك',
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (_, i) => _ScheduleItem(
                        schedule: controller.schedules[i],
                        days: _days,
                        dayAr: _dayAr,
                        onDelete: () =>
                            _confirmDelete(context, controller.schedules[i].id.toString()),
                      ),
                      childCount: controller.schedules.length,
                      addRepaintBoundaries: true,
                      addAutomaticKeepAlives: false,
                    ),
                  ),
                ),

              // ── Blocked header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'أوقات محظورة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAddBlocked(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          'إضافة',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Blocked list ──
              if (controller.blockedSlots.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Center(
                      child: Text(
                        'لا توجد أوقات محظورة',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (_, i) => _BlockedSlotItem(
                        slot: controller.blockedSlots[i],
                        onRemove: () => controller.removeBlockedSlot(
                          controller.blockedSlots[i].id.toString(),
                        ),
                      ),
                      childCount: controller.blockedSlots.length,
                      addRepaintBoundaries: true,
                      addAutomaticKeepAlives: false,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      }),
    );
  }

  void _showAddDialog(BuildContext ctx) {
    String day = 'MONDAY';
    final sc = TextEditingController(text: '09:00');
    final ec = TextEditingController(text: '17:00');
    final dc = TextEditingController(text: '30');

    showDialog(
      context: ctx,
      builder: (_) => _AddScheduleDialog(
        days: _days,
        dayAr: _dayAr,
        startCtrl: sc,
        endCtrl: ec,
        durationCtrl: dc,
        initialDay: day,
        onDayChanged: (v) => day = v,
        onConfirm: () {
          Get.back();
          controller.createSchedule(
            dayOfWeek: day,
            startTime: sc.text.trim(),
            endTime: ec.text.trim(),
            slotDuration: int.tryParse(dc.text.trim()) ?? 30,
          );
        },
      ),
    );
  }

  void _showAddBlocked(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => _AddBlockedDialog(
        onConfirm: (date, reason) {
          Get.back();
          controller.addBlockedSlot(date: date, reason: reason);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, String id) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.white,
        title: const Text('حذف الجدول؟'),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteSchedule(id);
            },
            child: const Text(
              'حذف',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Schedule list item
// ─────────────────────────────────────────────
class _ScheduleItem extends StatelessWidget {
  final dynamic schedule;
  final List<String> days;
  final List<String> dayAr;
  final VoidCallback onDelete;

  const _ScheduleItem({
    required this.schedule,
    required this.days,
    required this.dayAr,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final di = days.indexOf(schedule.dayOfWeek.toString());
    final isActive = schedule.isActive as bool;
    final startTime = schedule.startTime.toString().substring(0, 5);
    final endTime = schedule.endTime.toString().substring(0, 5);
    final slotDuration = schedule.slotDuration.toString();
    final dayLabel = di >= 0 ? dayAr[di] : schedule.dayOfWeek.toString();
    final dayShort = di >= 0 ? dayAr[di].substring(0, 3) : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _kSmallShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryLight : AppTheme.errorSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                dayShort,
                style: TextStyle(
                  color: isActive ? AppTheme.primary : AppTheme.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$startTime – $endTime  •  $slotDuration دقيقة',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppTheme.textHint,
              size: 20,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Blocked slot item
// ─────────────────────────────────────────────
class _BlockedSlotItem extends StatelessWidget {
  final dynamic slot;
  final VoidCallback onRemove;

  const _BlockedSlotItem({required this.slot, required this.onRemove});

  static const _border = Border.fromBorderSide(
    BorderSide(color: Color(0x26EF4444)), // AppTheme.error @ 15%
  );

  @override
  Widget build(BuildContext context) {
    final startTime = slot.startTime?.toString().substring(0, 5);
    final endTime = slot.endTime?.toString().substring(0, 5);
    final reason = slot.reason?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorSoft,
        borderRadius: BorderRadius.circular(12),
        border: _border,
      ),
      child: Row(
        children: [
          const Icon(Icons.block_rounded, color: AppTheme.error, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.date.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (startTime != null)
                  Text(
                    '$startTime – ${endTime ?? ''}',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  )
                else
                  const Text(
                    'يوم كامل',
                    style: TextStyle(color: AppTheme.error, fontSize: 12),
                  ),
                if (reason != null)
                  Text(
                    reason,
                    style: const TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: AppTheme.error,
              size: 18,
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Add schedule dialog
// ─────────────────────────────────────────────
class _AddScheduleDialog extends StatelessWidget {
  final List<String> days;
  final List<String> dayAr;
  final TextEditingController startCtrl;
  final TextEditingController endCtrl;
  final TextEditingController durationCtrl;
  final String initialDay;
  final ValueChanged<String> onDayChanged;
  final VoidCallback onConfirm;

  const _AddScheduleDialog({
    required this.days,
    required this.dayAr,
    required this.startCtrl,
    required this.endCtrl,
    required this.durationCtrl,
    required this.initialDay,
    required this.onDayChanged,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إضافة جدول',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: initialDay,
              decoration: const InputDecoration(labelText: 'اليوم'),
              dropdownColor: AppTheme.white,
              items: List.generate(
                7,
                    (i) => DropdownMenuItem(value: days[i], child: Text(dayAr[i])),
              ),
              onChanged: (v) { if (v != null) onDayChanged(v); },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: startCtrl,
                    decoration: const InputDecoration(labelText: 'من (HH:MM)'),
                    textDirection: TextDirection.ltr,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: endCtrl,
                    decoration: const InputDecoration(labelText: 'إلى (HH:MM)'),
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: durationCtrl,
              keyboardType: TextInputType.number,
              decoration:
              const InputDecoration(labelText: 'مدة الموعد (دقائق)'),
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: Get.back,
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    child: const Text('إضافة'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Add blocked slot dialog
// ─────────────────────────────────────────────
class _AddBlockedDialog extends StatefulWidget {
  final void Function(String date, String? reason) onConfirm;

  const _AddBlockedDialog({required this.onConfirm});

  @override
  State<_AddBlockedDialog> createState() => _AddBlockedDialogState();
}

class _AddBlockedDialogState extends State<_AddBlockedDialog> {
  DateTime? _pickedDate;
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final formatted = _pickedDate != null ? _formatDate(_pickedDate!) : null;

    return Dialog(
      backgroundColor: AppTheme.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'حظر يوم',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _pickedDate = d);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.inputBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  formatted ?? 'اختر التاريخ',
                  style: TextStyle(
                    color: formatted != null
                        ? AppTheme.textPrimary
                        : AppTheme.textHint,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(hintText: 'السبب (اختياري)'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: Get.back,
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _pickedDate == null
                        ? null
                        : () => widget.onConfirm(
                      _formatDate(_pickedDate!),
                      _reasonCtrl.text.trim().isNotEmpty
                          ? _reasonCtrl.text.trim()
                          : null,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                    ),
                    child: const Text('حظر اليوم'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Doctor Profile Screen
// ═══════════════════════════════════════════
class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final storage = Get.find<StorageProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: FutureBuilder<String?>(
        future: storage.getUserName(),
        builder: (_, snap) {
          final name = snap.data ?? 'دكتور';
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  color: AppTheme.white,
                  padding: EdgeInsets.only(
                    top: topPadding + 12,
                    bottom: 24,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'حسابي',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            InkWell(
                              onTap: () => _showLogoutSheet(context),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppTheme.errorSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.logout_rounded,
                                  color: AppTheme.error,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      UserAvatar(name: name, size: 68),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'طبيب',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ProfileMenuItem(
                      icon: Icons.campaign_outlined,
                      label: 'الإعلانات',
                      onTap: () => Get.toNamed('/doctor/announcements'),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.notifications_outlined,
                      label: 'الإشعارات',
                      onTap: () => Get.toNamed('/doctor/notifications'),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppTheme.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _LogoutSheet(),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _kMenuShadow,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_back_ios_rounded,
              color: AppTheme.textHint,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutSheet extends StatelessWidget {
  const _LogoutSheet();

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.errorSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: AppTheme.error,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'تسجيل الخروج',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'هل تريد تسجيل الخروج؟',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: Get.back,
                  child: const Text('إلغاء'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    Get.find<AuthController>().logout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                  ),
                  child: const Text('خروج'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// ═══════════════════════════════════════════
// Doctor Chat Screen - Optimized
// ═══════════════════════════════════════════

class DoctorChatScreen extends StatefulWidget {
  const DoctorChatScreen({super.key});

  @override
  State<DoctorChatScreen> createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends State<DoctorChatScreen>
    with WidgetsBindingObserver {
  late final DoctorChatController ctrl;
  final ScrollController _scrollController = ScrollController();

  Worker? _messagesWorker;
  Worker? _loadingWorker;

  int _lastMessageCount = 0;
  bool _didInitialJump = false;

  static const double _bubbleMaxWidthFactor = 0.75;
  static const EdgeInsets _listPadding = EdgeInsets.fromLTRB(16, 16, 16, 12);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    ctrl = Get.put(DoctorChatController());
    ctrl.setAppointmentId(Get.arguments as String);

    _lastMessageCount = ctrl.messages.length;

    _messagesWorker = ever(ctrl.messages, (_) {
      final newCount = ctrl.messages.length;
      final hasNewMessage = newCount != _lastMessageCount;
      _lastMessageCount = newCount;

      if (hasNewMessage) {
        _scheduleSmartScroll(animated: true);
      }
    });

    _loadingWorker = ever(ctrl.isLoading, (_) {
      if (!_didInitialJump &&
          !ctrl.isLoading.value &&
          ctrl.messages.isNotEmpty) {
        _didInitialJump = true;
        _scheduleSmartScroll(animated: false);
      }
    });
  }

  @override
  void didChangeMetrics() {
    // يحصل عند فتح/غلق الكيبورد
    final bottomInset =
        WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;
    if (bottomInset > 0 && _isNearBottom()) {
      _scheduleSmartScroll(animated: false);
    }
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    final distance = position.maxScrollExtent - position.pixels;
    return distance < 120;
  }

  void _scheduleSmartScroll({required bool animated}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      if (!_isNearBottom() && animated) return;

      final target = _scrollController.position.maxScrollExtent;

      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messagesWorker?.dispose();
    _loadingWorker?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * _bubbleMaxWidthFactor;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('محادثة مع المريض'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: Get.back,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: ctrl.loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _MessagesSection(
              ctrl: ctrl,
              scrollController: _scrollController,
              maxWidth: maxWidth,
            ),
          ),
          _ChatInputBar(
            ctrl: ctrl,
            onFocusTap: () => _scheduleSmartScroll(animated: false),
          ),
        ],
      ),
    );
  }
}

class _MessagesSection extends StatelessWidget {
  final DoctorChatController ctrl;
  final ScrollController scrollController;
  final double maxWidth;

  const _MessagesSection({
    required this.ctrl,
    required this.scrollController,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoading.value && ctrl.messages.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        );
      }

      if (ctrl.messages.isEmpty) {
        return const Center(
          child: EmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'لا توجد رسائل',
            subtitle: 'ابدأ محادثة مع المريض',
          ),
        );
      }

      final messages = ctrl.messages;

      return ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: messages.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        cacheExtent: 500,
        itemBuilder: (_, i) {
          final message = messages[i];
          return RepaintBoundary(
            child: _ChatBubble(
              key: ValueKey(
                message.id?.toString() ??
                    '${message.createdAt}_${message.senderRole}_$i',
              ),
              message: message,
              maxWidth: maxWidth,
            ),
          );
        },
      );
    });
  }
}

class _ChatBubble extends StatelessWidget {
  final dynamic message;
  final double maxWidth;

  const _ChatBubble({
    super.key,
    required this.message,
    required this.maxWidth,
  });

  static const TextStyle _patientLabelStyle = TextStyle(
    color: AppTheme.primary,
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle _myMessageStyle = TextStyle(
    color: Colors.white,
    fontSize: 14,
    height: 1.4,
  );

  static const TextStyle _otherMessageStyle = TextStyle(
    color: AppTheme.textPrimary,
    fontSize: 14,
    height: 1.4,
  );

  static const TextStyle _myTimeStyle = TextStyle(
    color: Color(0x99FFFFFF),
    fontSize: 10,
  );

  static const TextStyle _otherTimeStyle = TextStyle(
    color: AppTheme.textHint,
    fontSize: 10,
  );

  static String _formatTime(String dt) {
    try {
      final d = DateTime.parse(dt).toLocal();
      final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final minute = d.minute.toString().padLeft(2, '0');
      final period = d.hour >= 12 ? 'م' : 'ص';
      return '$hour12:$minute $period';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMe = message.senderRole.toString() == 'DOCTOR';
    final String text = message.message?.toString() ?? '';
    final String time = _formatTime(message.createdAt?.toString() ?? '');

    return Align(
      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isMe ? AppTheme.primary : AppTheme.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isMe ? 4 : 14),
                bottomRight: Radius.circular(isMe ? 14 : 4),
              ),
              border: isMe
                  ? null
                  : Border.all(color: const Color(0xFFECEFF3), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text('المريض', style: _patientLabelStyle),
                    ),
                  SelectableText(
                    text,
                    style: isMe ? _myMessageStyle : _otherMessageStyle,
                  ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: isMe ? _myTimeStyle : _otherTimeStyle,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatefulWidget {
  final DoctorChatController ctrl;
  final VoidCallback onFocusTap;

  const _ChatInputBar({
    required this.ctrl,
    required this.onFocusTap,
  });

  @override
  State<_ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<_ChatInputBar> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() {
        if (_focusNode.hasFocus) {
          widget.onFocusTap();
        }
      });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(16, 10, 8, bottomInset > 0 ? 10 : 12),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF0F2F5), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: RepaintBoundary(
                child: TextField(
                  controller: widget.ctrl.messageCtrl,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onTap: widget.onFocusTap,
                  onSubmitted: (_) => widget.ctrl.sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالة...',
                    isDense: true,
                    filled: true,
                    fillColor: AppTheme.inputBg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _SendButton(ctrl: widget.ctrl),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final DoctorChatController ctrl;

  const _SendButton({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool sending = ctrl.isSending.value;

      return SizedBox(
        width: 42,
        height: 42,
        child: Material(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: sending ? null : ctrl.sendMessage,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: sending
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      );
    });
  }
}


// ═══════════════════════════════════════════
// Add Prescription Screen - Multi Prescription
// ═══════════════════════════════════════════

class AddPrescriptionScreen extends StatefulWidget {
  const AddPrescriptionScreen({super.key});

  @override
  State<AddPrescriptionScreen> createState() => _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends State<AddPrescriptionScreen> {
  late final AddPrescriptionController ctrl;
  late final String apptId;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ValueNotifier<List<_PrescriptionDraft>> _itemsNotifier =
  ValueNotifier<List<_PrescriptionDraft>>([]);

  static const List<BoxShadow> _cardShadow = [
    BoxShadow(
      color: Color(0x05000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  List<_PrescriptionDraft> get _items => _itemsNotifier.value;

  @override
  @override
  void initState() {
    super.initState();
    ctrl = Get.put(AddPrescriptionController());
    apptId = Get.arguments as String;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final existing = await ctrl.loadForAppointment(apptId);

    if (!mounted) return;

    if (existing.isEmpty) {
      _itemsNotifier.value = [_PrescriptionDraft()];
      return;
    }

    _itemsNotifier.value = existing.map((rx) {
      return _PrescriptionDraft(
        medication: rx.medication ?? '',
        dosage: rx.dosage ?? '',
        frequency: rx.frequency ?? '',
        duration: rx.duration ?? '',
        notes: rx.notes ?? '',
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final item in _itemsNotifier.value) {
      item.dispose();
    }
    _itemsNotifier.dispose();
    super.dispose();
  }

  void _addItem() {
    final updated = List<_PrescriptionDraft>.from(_itemsNotifier.value)
      ..add(_PrescriptionDraft());
    _itemsNotifier.value = updated;
  }

  void _removeItem(String id) {
    if (_itemsNotifier.value.length == 1) return;

    final updated = List<_PrescriptionDraft>.from(_itemsNotifier.value);
    final index = updated.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final item = updated.removeAt(index);
    item.dispose();
    _itemsNotifier.value = updated;
  }

  Future<void> _saveAll() async {
    FocusScope.of(context).unfocus();

    final currentItems = _itemsNotifier.value;

    final items = currentItems
        .map((e) => {
      'medicationName': e.medicationCtrl.text.trim(),
      'dosage': e.dosageCtrl.text.trim(),
      'frequency': e.frequencyCtrl.text.trim(),
      'duration': e.durationCtrl.text.trim(),
      'notes': e.notesCtrl.text.trim(),
    })
        .toList();

    final hasAtLeastOneMed = items.any(
          (e) => (e['medicationName'] ?? '').trim().isNotEmpty,
    );

    if (!hasAtLeastOneMed) {
      Get.snackbar(
        'بيانات ناقصة',
        'أدخل اسم دواء واحد على الأقل',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFFF3E0),
        colorText: const Color(0xFF8A4B00),
      );
      return;
    }

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final ok = await ctrl.replaceAll(apptId, items);

    if (!mounted) return;

    if (ok) {
      Get.back(result: true);
      Get.snackbar(
        'تم الحفظ',
        'تم تحديث الوصفات بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successSoft,
        colorText: AppTheme.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('إضافة وصفة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: Get.back,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ValueListenableBuilder<List<_PrescriptionDraft>>(
          valueListenable: _itemsNotifier,
          builder: (context, items, _) {
            return CustomScrollView(
              keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
              cacheExtent: 600,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: _HeaderCard(
                      count: items.length,
                      onAdd: _addItem,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  sliver: SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Padding(
                        key: ValueKey(item.id),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RepaintBoundary(
                          child: _PrescriptionCard(
                            index: index,
                            item: item,
                            canRemove: items.length > 1,
                            onRemove: () => _removeItem(item.id),
                            cardShadow: _cardShadow,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 92),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: AppTheme.bg,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _SaveButton(
            ctrl: ctrl,
            onPressed: _saveAll,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

    );
  }
}

// ─────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────
class _HeaderCard extends StatelessWidget {
  final int count;
  final VoidCallback onAdd;

  const _HeaderCard({
    required this.count,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EEF3)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.medication_rounded,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تفاصيل الوصفة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count ${count == 1 ? 'دواء' : 'أدوية'}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onAdd,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: AppTheme.primary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'إضافة',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



// ─────────────────────────────────────────────
// Prescription card
// ─────────────────────────────────────────────
class _PrescriptionCard extends StatelessWidget {
  final int index;
  final _PrescriptionDraft item;
  final bool canRemove;
  final VoidCallback onRemove;
  final List<BoxShadow> cardShadow;

  const _PrescriptionCard({
    required this.index,
    required this.item,
    required this.canRemove,
    required this.onRemove,
    required this.cardShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEFF4)),
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'الدواء ${index + 1}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const Spacer(),
              if (canRemove)
                Material(
                  color: const Color(0xFFFFF3F2),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: onRemove,
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _PrescriptionField(
            label: 'اسم الدواء *',
            controller: item.medicationCtrl,
            hint: 'مثال: أموكسيسيلين',
            validator: (v) {
              final value = (v ?? '').trim();

              final hasAnyOtherField = item.dosageCtrl.text.trim().isNotEmpty ||
                  item.frequencyCtrl.text.trim().isNotEmpty ||
                  item.durationCtrl.text.trim().isNotEmpty ||
                  item.notesCtrl.text.trim().isNotEmpty;

              if (hasAnyOtherField && value.isEmpty) {
                return 'اسم الدواء مطلوب';
              }
              return null;
            },
          ),
          Row(
            children: [
              Expanded(
                child: _PrescriptionField(
                  label: 'الجرعة',
                  controller: item.dosageCtrl,
                  hint: '500mg',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PrescriptionField(
                  label: 'التكرار',
                  controller: item.frequencyCtrl,
                  hint: 'مرتين يومياً',
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _PrescriptionField(
                  label: 'المدة',
                  controller: item.durationCtrl,
                  hint: '7 أيام',
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(child: SizedBox()),
            ],
          ),
          _PrescriptionField(
            label: 'ملاحظات',
            controller: item.notesCtrl,
            hint: 'تعليمات إضافية...',
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Field
// ─────────────────────────────────────────────
class _PrescriptionField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _PrescriptionField({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  static final OutlineInputBorder _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFE4EAF0)),
  );

  static final OutlineInputBorder _focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppTheme.primary, width: 1.2),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            validator: validator,
            textInputAction:
            maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: _border,
              enabledBorder: _border,
              focusedBorder: _focusedBorder,
              errorBorder: _border.copyWith(
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
              focusedErrorBorder: _focusedBorder.copyWith(
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Save button
// ─────────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  final AddPrescriptionController ctrl;
  final Future<void> Function() onPressed;

  const _SaveButton({
    required this.ctrl,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final saving = ctrl.isSaving.value;

      return SizedBox(
        height: 54,
        child: ElevatedButton.icon(
          onPressed: saving ? null : onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppTheme.primary.withOpacity(0.55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: saving
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Icon(Icons.save_rounded, size: 18),
          label: Text(
            saving ? 'جارٍ الحفظ...' : 'حفظ الوصفات',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────
// Draft model
// ─────────────────────────────────────────────
class _PrescriptionDraft {
  _PrescriptionDraft({
    String medication = '',
    String dosage = '',
    String frequency = '',
    String duration = '',
    String notes = '',
  }) : id = UniqueKey().toString() {
    medicationCtrl.text = medication;
    dosageCtrl.text = dosage;
    frequencyCtrl.text = frequency;
    durationCtrl.text = duration;
    notesCtrl.text = notes;
  }

  final String id;
  final TextEditingController medicationCtrl = TextEditingController();
  final TextEditingController dosageCtrl = TextEditingController();
  final TextEditingController frequencyCtrl = TextEditingController();
  final TextEditingController durationCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();

  void dispose() {
    medicationCtrl.dispose();
    dosageCtrl.dispose();
    frequencyCtrl.dispose();
    durationCtrl.dispose();
    notesCtrl.dispose();
  }
}