import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/config/app_theme.dart';
import '../../../widgets/shared_widgets.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/patient_controllers.dart';
import '../../shared/controllers/notification_controller.dart';
import 'patient_shell.dart';

// ═══════════════════════════════════════════
// Patient Home Screen
// ═══════════════════════════════════════════
class PatientHomeScreen extends StatelessWidget {
  final VoidCallback? onBookAppointment;

  const PatientHomeScreen({
    super.key,
    this.onBookAppointment,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PatientHomeController>();
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Obx(() {
        if (ctrl.isLoading.value && ctrl.userName.value.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: ()=> ctrl.loadData(forceRefresh: true),
          edgeOffset: topPadding,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _TopBar(topPadding: topPadding)),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: _BookAppointmentCard(
                  onTap: onBookAppointment,
                ),
              ),
              const SliverToBoxAdapter(child: _SectionLabel(label: 'المواعيد القادمة')),
              const _UpcomingSliver(),
              const SliverToBoxAdapter(child: _SectionLabel(label: 'إعلانات العيادة')),
              const _AnnouncementsSliver(),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final double topPadding;
  const _TopBar({required this.topPadding});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PatientHomeController>();
    final notif = Get.find<NotificationController>();

    return Container(
      color: AppTheme.white,
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 16, 16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Obx(() {
                final name = ctrl.userName.value;
                return UserAvatar(
                  name: name.isNotEmpty ? name : 'م',
                  size: 42,
                );
              }),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() {
                  final name = ctrl.userName.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'أهلاً بك',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        name.isNotEmpty ? name : 'مريض',
                        style: AppTheme.heading2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                }),
              ),
              Obx(() => _BellButton(unread: notif.unreadCount.value)),
            ],
          ),
          const SizedBox(height: 16),
          const _CurrentClinicSwitcher(),
        ],
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  final int unread;
  const _BellButton({required this.unread});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.toNamed('/patient/notifications'),
      borderRadius: AppTheme.radius12,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_outlined,
              color: AppTheme.textSecondary,
              size: 24,
            ),
            if (unread > 0)
              const Positioned(
                top: 9,
                right: 9,
                child: SizedBox(
                  width: 8,
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Home body
// ─────────────────────────────────────────────
class _HomeBodySliver extends StatelessWidget {
  const _HomeBodySliver();

  @override
  Widget build(BuildContext context) {
    return const SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: _StatsRow()),
        SliverToBoxAdapter(child: _BookAppointmentCard()),
        SliverToBoxAdapter(child: _SectionLabel(label: 'المواعيد القادمة')),
        _UpcomingSliver(),
        SliverToBoxAdapter(child: _SectionLabel(label: 'إعلانات العيادة')),
        _AnnouncementsSliver(),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Stats row
// ─────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PatientHomeController>();
    return Obx(() => Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _StatPill(
            value: ctrl.upcomingAppointments.length,
            label: 'مواعيد\nقادمة',
            color: AppTheme.primary,
            bg: AppTheme.primaryLight,
          ),
          const SizedBox(width: 10),
          _StatPill(
            value: ctrl.completedAppointments.length,
            label: 'زيارات\nمكتملة',
            color: AppTheme.success,
            bg: AppTheme.successSoft,
          ),
        ],
      ),
    ));
  }
}

class _StatPill extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final Color bg;

  const _StatPill({
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppTheme.radius14,
        ),
        child: Row(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CTA booking card
// ─────────────────────────────────────────────
class _BookAppointmentCard extends StatelessWidget {
  final VoidCallback? onTap;

  const _BookAppointmentCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppTheme.radius16,
          onTap: () {
            debugPrint('Book appointment tapped');
            onTap?.call();
          },
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF16A39A),
                  Color(0xFF4F8CFF),
                ],
              ),
              borderRadius: AppTheme.radius16,
              boxShadow: AppTheme.cardShadowSm,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'احجز موعد جديد',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'تصفح الأطباء واختر الموعد المناسب لك',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Text(label, style: AppTheme.heading3),
    );
  }
}

// ─────────────────────────────────────────────
// Upcoming appointments
// ─────────────────────────────────────────────
class _UpcomingSliver extends StatelessWidget {
  const _UpcomingSliver();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PatientHomeController>();
    return Obx(() {
      final appts = ctrl.upcomingAppointments;

      if (appts.isEmpty) {
        return const SliverToBoxAdapter(child: _EmptyAppts());
      }

      final count = appts.length > 3 ? 3 : appts.length;
      return SliverList(
        delegate: SliverChildBuilderDelegate(
              (_, i) => _ApptCard(appt: appts[i]),
          childCount: count,
          addRepaintBoundaries: true,
          addAutomaticKeepAlives: false,
        ),
      );
    });
  }
}

class _EmptyAppts extends StatelessWidget {
  const _EmptyAppts();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.find<PatientShellController>().changeTab(1),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardDecoration,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: AppTheme.radius12,
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                color: AppTheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'لا توجد مواعيد قادمة',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'اضغط لعرض الأطباء وحجز موعد جديد',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
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
class _ApptCard extends StatelessWidget {
  final dynamic appt;
  const _ApptCard({required this.appt});

  static const _months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  static DateTime? _parseDate(String value) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  static String _formatDateLabel(String date) {
    final parsed = _parseDate(date);
    if (parsed == null) return date;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(parsed.year, parsed.month, parsed.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'غدًا';
    if (diff == -1) return 'أمس';

    return '${parsed.day} ${_months[parsed.month - 1]}';
  }

  static String _formatFullDate(String date) {
    final parsed = _parseDate(date);
    if (parsed == null) return date;
    return '${parsed.day} ${_months[parsed.month - 1]} ${parsed.year}';
  }

  static String _formatTime12h(String time) {
    try {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'م' : 'ص';

      hour = hour % 12;
      if (hour == 0) hour = 12;

      return '$hour:$minute $period';
    } catch (_) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = appt.date.toString();
    final doctor = appt.doctorName.toString();
    final specialty = appt.specialtyName?.toString() ?? '';
    final start = _formatTime12h(appt.startTime.toString().substring(0, 5));
    final end = _formatTime12h(appt.endTime.toString().substring(0, 5));
    final shortDate = _formatDateLabel(dateStr);
    final fullDate = _formatFullDate(dateStr);

    return InkWell(
      onTap: () => Get.find<PatientShellController>().changeTab(2),
      borderRadius: AppTheme.radius14,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: AppTheme.radius12,
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: AppTheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          doctor.isNotEmpty ? 'د. $doctor' : 'الطبيب',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      StatusBadge(appt.status.toString()),
                    ],
                  ),
                  if (specialty.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      specialty,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.event_outlined,
                        text: '$shortDate • $fullDate',
                      ),
                      _InfoChip(
                        icon: Icons.access_time_rounded,
                        text: '$start - $end',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Announcements
// ─────────────────────────────────────────────
class _AnnouncementsSliver extends StatelessWidget {
  const _AnnouncementsSliver();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PatientHomeController>();
    return Obx(() {
      final items = ctrl.announcements;
      if (items.isEmpty) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }

      final count = items.length > 3 ? 3 : items.length;
      return SliverList(
        delegate: SliverChildBuilderDelegate(
              (_, i) => _AnnouncementCard(item: items[i]),
          childCount: count,
          addRepaintBoundaries: true,
          addAutomaticKeepAlives: false,
        ),
      );
    });
  }
}

class _AnnouncementCard extends StatelessWidget {
  final dynamic item;
  const _AnnouncementCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF7E6),
              borderRadius: AppTheme.radius10,
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: AppTheme.warning,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.body.toString(),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentClinicSwitcher extends StatelessWidget {
  const _CurrentClinicSwitcher();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Obx(() {
      final clinic = auth.selectedClinic.value;
      if (clinic == null) return const SizedBox.shrink();


      final title = clinic.clinicName.trim();
      final area = (clinic.area ?? '').trim();
      final address = (clinic.address ?? '').trim();
      final branch = (clinic.branchName ?? '').trim();

      // Pick the best available location descriptor
      final subtitle = area.isNotEmpty
          ? area
          : branch.isNotEmpty
          ? branch
          : address.isNotEmpty
          ? address
          : '—';

      return InkWell(
        onTap: () async {
          FocusManager.instance.primaryFocus?.unfocus();
          await auth.loadMyClinics();
          _showClinicSwitcherSheet(auth);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              // Clinic icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: AppTheme.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Title + area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Switch icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: AppTheme.primary,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showClinicSwitcherSheet(AuthController auth) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Obx(() {
            if (auth.isLoadingMyClinics.value) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (auth.myClinics.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'لا توجد عيادات متاحة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'اختر العيادة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ...auth.myClinics.map((clinic) {
                  final isCurrent =
                      auth.selectedClinic.value?.clinicId == clinic.clinicId;

                  final subtitle = (clinic.branchName ?? '').trim().isNotEmpty
                      ? clinic.branchName!.trim()
                      : '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: isCurrent
                          ? null
                          : () async {
                        Get.back(); // close the sheet first
                        await auth.switchClinic(clinic);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFFF2FBF6)
                              : AppTheme.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCurrent
                                ? AppTheme.success.withValues(alpha: 0.35)
                                : AppTheme.primary.withValues(alpha: 0.12),
                            width: isCurrent ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCurrent
                                  ? Icons.check_circle_rounded
                                  : Icons.chevron_right_rounded,
                              color: isCurrent
                                  ? AppTheme.success
                                  : AppTheme.textSecondary,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    clinic.clinicName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  if (subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          size: 14,
                                          color: AppTheme.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showLoadingOverlay() {
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black38,
    );
  }
}