import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/config/app_theme.dart';
import '../../../widgets/shared_widgets.dart';
import '../../shared/controllers/notification_controller.dart';
import '../controllers/doctor_controllers.dart';

// ─────────────────────────────────────────────
// Shared constants
// ─────────────────────────────────────────────
const _kCardShadow = [
  BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 2)),
];
const _kActionShadow = [
  BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2)),
];
const _kCardDecoration = BoxDecoration(
  color: AppTheme.white,
  borderRadius: BorderRadius.all(Radius.circular(14)),
  boxShadow: _kCardShadow,
);

// ═══════════════════════════════════════════
// Doctor Home Screen
// ═══════════════════════════════════════════
class DoctorHomeScreen extends GetView<DoctorHomeController> {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Obx(() {
        if (controller.isLoading.value && controller.doctorName.value.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: controller.loadData,
          edgeOffset: topPadding,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _Header(topPadding: topPadding)),
              SliverToBoxAdapter(child: _StatsGrid(controller: controller)),
              SliverToBoxAdapter(child: _QuickActions()),
              SliverToBoxAdapter(child: _TodayHeader(controller: controller)),
              _TodayAppointmentsSliver(controller: controller),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────
class _Header extends StatelessWidget {
  final double topPadding;

  const _Header({required this.topPadding});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.white,
      padding: EdgeInsets.only(
        top: topPadding + 12,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      child: Row(
        children: [
          _AvatarSection(),
          const SizedBox(width: 12),
          const _DoctorNameColumn(),
          const _NotificationBell(),
        ],
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DoctorHomeController>();
    return Obx(() {
      final name = ctrl.doctorName.value;
      return UserAvatar(name: name.isNotEmpty ? name : 'د', size: 44);
    });
  }
}

class _DoctorNameColumn extends StatelessWidget {
  const _DoctorNameColumn();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DoctorHomeController>();
    return Expanded(
      child: Obx(() {
        final name = ctrl.doctorName.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مرحباً دكتور 👋',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            Text(
              name.isNotEmpty ? 'د. $name' : 'لوحة التحكم',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      }),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final n = Get.find<NotificationController>();
      final hasUnread = n.unreadCount.value > 0;
      return InkWell(
        onTap: () => Get.toNamed('/doctor/notifications'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.inputBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: AppTheme.textSecondary,
                size: 22,
              ),
              if (hasUnread)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: _UnreadDot(),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 8,
      height: 8,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.error,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Stats grid — rebuilds only on count changes
// ─────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final DoctorHomeController controller;

  const _StatsGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Obx(() => Column(
        children: [
          Row(
            children: [
              _StatCard(
                label: 'مواعيد اليوم',
                value: '${controller.todayAppointments.length}',
                icon: Icons.calendar_today_rounded,
                color: AppTheme.primary,
                bg: AppTheme.primaryLight,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'بانتظار التأكيد',
                value: '${controller.pendingCount.value}',
                icon: Icons.hourglass_top_rounded,
                color: AppTheme.warning,
                bg: AppTheme.warningSoft,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatCard(
                label: 'زيارات مكتملة',
                value: '${controller.completedCount.value}',
                icon: Icons.check_circle_outline_rounded,
                color: AppTheme.success,
                bg: AppTheme.successSoft,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'إجمالي المواعيد',
                value: '${controller.totalCount.value}',
                icon: Icons.bar_chart_rounded,
                color: AppTheme.info,
                bg: const Color(0xFFEBF2FF),
              ),
            ],
          ),
        ],
      )),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _kCardDecoration,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
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

// ─────────────────────────────────────────────
// Quick actions
// ─────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _ActionCard(
            label: 'الإعلانات',
            icon: Icons.campaign_rounded,
            color: AppTheme.warning,
            bg: Color(0xFFFFF7E6),
            route: '/doctor/announcements',
          ),
          SizedBox(width: 12),
          _ActionCard(
            label: 'الإشعارات',
            icon: Icons.notifications_outlined,
            color: AppTheme.info,
            bg: Color(0xFFEBF2FF),
            route: '/doctor/notifications',
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  final String route;

  const _ActionCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => Get.toNamed(route),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _kActionShadow,
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
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
// Today's header
// ─────────────────────────────────────────────
class _TodayHeader extends StatelessWidget {
  final DoctorHomeController controller;

  const _TodayHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = controller.todayAppointments.length;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'مواعيد اليوم',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (count > 0)
              Text(
                '$count موعد',
                style: const TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────
// Today's appointments sliver
// ─────────────────────────────────────────────
class _TodayAppointmentsSliver extends StatelessWidget {
  final DoctorHomeController controller;

  const _TodayAppointmentsSliver({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final appts = controller.todayAppointments;

      if (appts.isEmpty) {
        return const SliverToBoxAdapter(child: _EmptyTodayCard());
      }

      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
                (_, i) => _TodayAppointmentCard(appt: appts[i]),
            childCount: appts.length,
            addRepaintBoundaries: true,
            addAutomaticKeepAlives: false,
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────
// Empty today card
// ─────────────────────────────────────────────
class _EmptyTodayCard extends StatelessWidget {
  const _EmptyTodayCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: _kCardDecoration,
      child: const Column(
        children: [
          _EmptyIcon(),
          SizedBox(height: 12),
          Text(
            'لا توجد مواعيد اليوم',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'استمتع بوقتك!',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EmptyIcon extends StatelessWidget {
  const _EmptyIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.event_available_rounded,
        color: AppTheme.primary,
        size: 26,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Today appointment card
// ─────────────────────────────────────────────
class _TodayAppointmentCard extends StatelessWidget {
  final dynamic appt;

  const _TodayAppointmentCard({required this.appt});

  @override
  Widget build(BuildContext context) {
    final startTime = appt.startTime.toString().substring(0, 5);
    final endTime = appt.endTime.toString().substring(0, 5);
    final patientName = appt.patientName.toString();
    final status = appt.status.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: _kCardDecoration,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                startTime,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
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
                  patientName.isNotEmpty ? patientName : 'مريض',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$startTime – $endTime',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(status),
        ],
      ),
    );
  }
}