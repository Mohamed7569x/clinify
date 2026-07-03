import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/config/app_theme.dart';
import '../../../widgets/shared_widgets.dart';
import '../controllers/patient_controllers.dart';


String smartDateTime(String date, String time) {
  final dt = DateTime.parse('$date $time');
  final now = DateTime.now();

  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final target = DateTime(dt.year, dt.month, dt.day);

  String dayLabel;
  if (target == today) {
    dayLabel = 'اليوم';
  } else if (target == tomorrow) {
    dayLabel = 'غداً';
  } else {
    dayLabel = '${dt.day}/${dt.month}/${dt.year}';
  }

  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour >= 12 ? 'م' : 'ص';

  return '$dayLabel | $hour12:$minute $period';
}

class _DateTimeBadge extends StatelessWidget {
  final String date;
  final String time;
  final bool isMuted;

  const _DateTimeBadge({
    required this.date,
    required this.time,
    this.isMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isMuted ? const Color(0xFFF8F8F8) : AppTheme.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 14,
            color: isMuted ? AppTheme.textHint : AppTheme.textSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$date • $time',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isMuted ? AppTheme.textHint : AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ═══════════════════════════════════════════
// Patient Appointments Screen (Simplified)
// ═══════════════════════════════════════════
class PatientAppointmentsScreen extends StatelessWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PatientAppointmentsController>();
    debugPrint('AppointmentsScreen build ctrl = ${identityHashCode(ctrl)}');
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppTheme.white,
            padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 16),
            child: Text('مواعيدي', style: AppTheme.heading1),
          ),
          Expanded(
            child: Obx(() {
              final appointments = ctrl.appointments.toList();
              debugPrint(
                'AppointmentsScreen Obx rebuild -> ctrl=${identityHashCode(ctrl)} '
                    'count=${appointments.length}',
              );

              if (ctrl.isLoading.value && appointments.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                );
              }

              final upcoming = <dynamic>[];
              final history = <dynamic>[];

              for (final appt in appointments) {
                if (appt.isUpcoming == true) {
                  upcoming.add(appt);
                } else {
                  history.add(appt);
                }
              }

              final items = <_AppointmentListItem>[];

              if (upcoming.isNotEmpty) {
                items.add(const _AppointmentListItem.section('المواعيد القادمة'));
                for (final appt in upcoming) {
                  items.add(_AppointmentListItem.card(appt));
                }
              }

              if (history.isNotEmpty) {
                items.add(const _AppointmentListItem.spacer(20));
                items.add(const _AppointmentListItem.section('السجل'));
                for (final appt in history) {
                  items.add(_AppointmentListItem.card(appt));
                }
              }

              if (items.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => ctrl.loadAppointments(forceRefresh: true),
                  color: AppTheme.primary,
                  edgeOffset: 8,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: const [
                      Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: EmptyState(
                          icon: Icons.calendar_today_outlined,
                          title: 'لا توجد مواعيد',
                          subtitle: 'احجز موعدك الأول',
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => ctrl.loadAppointments(forceRefresh: true),
                color: AppTheme.primary,
                edgeOffset: 8,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    switch (item.type) {
                      case _AppointmentListItemType.section:
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SectionTitle(item.title!),
                        );

                      case _AppointmentListItemType.spacer:
                        return SizedBox(height: item.height);

                      case _AppointmentListItemType.card:
                        return _SimpleApptCard(
                          appt: item.appt,
                          ctrl: ctrl,
                        );
                    }
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

enum _AppointmentListItemType {
  section,
  card,
  spacer,
}

class _AppointmentListItem {
  final _AppointmentListItemType type;
  final String? title;
  final dynamic appt;
  final double height;

  const _AppointmentListItem.section(this.title)
      : type = _AppointmentListItemType.section,
        appt = null,
        height = 0;

  const _AppointmentListItem.card(this.appt)
      : type = _AppointmentListItemType.card,
        title = null,
        height = 0;

  const _AppointmentListItem.spacer(this.height)
      : type = _AppointmentListItemType.spacer,
        title = null,
        appt = null;
}

// ═══════════════════════════════════════════
// Section Title
// ═══════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Simplified Appointment Card
// ═══════════════════════════════════════════
class _SimpleApptCard extends StatelessWidget {
  final dynamic appt;
  final PatientAppointmentsController ctrl;

  const _SimpleApptCard({
    required this.appt,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    final doctor = appt.doctorName?.toString() ?? 'الطبيب';
    final status = (appt.status?.toString() ?? '').toUpperCase();
    final style = _AppointmentStatusStyle.fromStatus(status);
    final hideActions = status == 'CANCELLED' || status == 'NO_SHOW';
    final isCancelled = status == 'CANCELLED'|| status == 'NO_SHOW';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCancelled ? const Color(0xFFFFFAFA) : AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCancelled ? const Color(0xFFF2D4D4) : AppTheme.border,
        ),
        boxShadow: AppTheme.cardShadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 92,
            decoration: BoxDecoration(
              color: style.accent,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  UserAvatar(name: doctor, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'د. $doctor',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isCancelled
                                      ? AppTheme.textSecondary
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(child: _StatusBadge(style: style)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _DateTimeBadge(
                          date: appt.date.toString(),
                          time: appt.startTime.toString(),
                          isMuted: isCancelled,
                        ),
                      ],
                    ),
                  ),
                  if (!hideActions)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: const Icon(Icons.more_vert_rounded, size: 20),
                      color: AppTheme.textSecondary,
                      onPressed: () => _openActions(context),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.white,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _ActionsSheet(appt: appt, ctrl: ctrl),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _AppointmentStatusStyle style;

  const _StatusBadge({required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.badgeBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: style.badgeBorder),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          color: style.badgeText,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AppointmentStatusStyle {
  final String label;
  final Color accent;
  final Color badgeBg;
  final Color badgeBorder;
  final Color badgeText;

  const _AppointmentStatusStyle({
    required this.label,
    required this.accent,
    required this.badgeBg,
    required this.badgeBorder,
    required this.badgeText,
  });

  static _AppointmentStatusStyle fromStatus(String status) {
    switch (status) {
      case 'PENDING':
        return const _AppointmentStatusStyle(
          label: 'بانتظار التأكيد',
          accent: Color(0xFFE6A23C),
          badgeBg: Color(0xFFFFF7E8),
          badgeBorder: Color(0xFFF5D8A6),
          badgeText: Color(0xFFB7791F),
        );

      case 'CONFIRMED':
        return const _AppointmentStatusStyle(
          label: 'مؤكد',
          accent: Color(0xFF22A06B),
          badgeBg: Color(0xFFEAF8F1),
          badgeBorder: Color(0xFFBFE7D1),
          badgeText: Color(0xFF1F8A5B),
        );

      case 'COMPLETED':
        return const _AppointmentStatusStyle(
          label: 'مكتمل',
          accent: Color(0xFF4C8BF5),
          badgeBg: Color(0xFFEFF5FF),
          badgeBorder: Color(0xFFCFE0FF),
          badgeText: Color(0xFF356AC3),
        );

      case 'CANCELLED':
        return const _AppointmentStatusStyle(
          label: 'ملغي',
          accent: Color(0xFFE05A5A),
          badgeBg: Color(0xFFFFEEEE),
          badgeBorder: Color(0xFFF3CACA),
          badgeText: Color(0xFFD64545),
        );

      case 'NO_SHOW':
        return const _AppointmentStatusStyle(
          label: 'لم يحضر',
          accent: Color(0xFF9AA1AC),
          badgeBg: Color(0xFFF3F4F6),
          badgeBorder: Color(0xFFE5E7EB),
          badgeText: Color(0xFF6B7280),
        );

      case 'RESCHEDULED':
        return const _AppointmentStatusStyle(
          label: 'أعيدت الجدولة',
          accent: Color(0xFF8B5CF6),
          badgeBg: Color(0xFFF4EEFF),
          badgeBorder: Color(0xFFE1D4FF),
          badgeText: Color(0xFF7C4DCC),
        );

      default:
        return const _AppointmentStatusStyle(
          label: 'غير معروف',
          accent: Color(0xFFB8C0CC),
          badgeBg: Color(0xFFF6F7F9),
          badgeBorder: Color(0xFFE6EAF0),
          badgeText: AppTheme.textSecondary,
        );
    }
  }
}



// ═══════════════════════════════════════════
// Smart Single Action
// ═══════════════════════════════════════════

Widget _modernItem({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  bool isDestructive = false,
}) {
  final color = isDestructive ? AppTheme.error : AppTheme.textPrimary;
  final bg = isDestructive ? AppTheme.errorSoft : AppTheme.inputBg;

  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SheetItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppTheme.error : AppTheme.textPrimary;
    final bg = isDestructive ? AppTheme.errorSoft : AppTheme.inputBg;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _ActionsSheet extends StatelessWidget {
  final dynamic appt;
  final PatientAppointmentsController ctrl;

  const _ActionsSheet({
    required this.appt,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    final isUpcoming = appt.isUpcoming == true;
    final isConfirmed = appt.isConfirmed == true;
    final isCompleted = appt.isCompleted == true;
    final id = appt.id.toString();

    final actions = <Widget>[];

    if (isConfirmed || isCompleted) {
      actions.add(
        _SheetItem(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'محادثة',
          onTap: () {
            Get.back();
            Get.toNamed('/patient/chat', arguments: id);
          },
        ),
      );
    }

    if (isCompleted) {
      actions.addAll([
        _SheetItem(
          icon: Icons.medication_outlined,
          label: 'الوصفة',
          onTap: () {
            Get.back();
            Get.toNamed('/patient/prescriptions', arguments: id);
          },
        ),
        _SheetItem(
          icon: Icons.star_outline_rounded,
          label: 'تقييم الطبيب',
          onTap: () {
            Get.back();
            Get.toNamed('/patient/review', arguments: id);
          },
        ),
      ]);
    }

    if (isUpcoming) {
      actions.add(
        _SheetItem(
          icon: Icons.close_rounded,
          label: 'إلغاء الموعد',
          isDestructive: true,
          onTap: () {
            Get.back();
            _showCancelDialog(context, id);
          },
        ),
      );
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'الإجراءات',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...actions,
          ],
        ),
      ),
    );
  }
}

void _showCancelDialog(BuildContext context, String id) {
  final reasonCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppTheme.errorSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                color: AppTheme.error,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'إلغاء الموعد',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'هل أنت متأكد من إلغاء هذا الموعد؟ يمكنك كتابة سبب الإلغاء بشكل اختياري.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'سبب الإلغاء (اختياري)',
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: Get.back,
                    child: const Text('تراجع'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                    ),
                    onPressed: () {
                      Get.back();
                      final reason = reasonCtrl.text.trim();

                      Get.find<PatientAppointmentsController>()
                          .cancelAppointment(
                        id,
                        reason: reason.isNotEmpty ? reason : null,
                      );
                    },
                    child: const Text('إلغاء الموعد'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
