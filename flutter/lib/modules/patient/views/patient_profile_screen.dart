import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/config/app_theme.dart';
import '../../../data/models/patient_model.dart';
import '../../../widgets/shared_widgets.dart';
import '../controllers/patient_controllers.dart';
import '../../auth/controllers/auth_controller.dart';

// ─────────────────────────────────────────────
// Shared constants
// ─────────────────────────────────────────────
const _kCardShadow = [
  BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 2)),
];
const _kMenuShadow = [
  BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2)),
];

// ═══════════════════════════════════════════
// Patient Profile Screen
// ═══════════════════════════════════════════
class PatientProfileScreen extends GetView<PatientProfileController> {
  const PatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Obx(() {
        final profile = controller.profile.value;

        if (controller.isLoading.value || profile == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: controller.loadProfile,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ProfileHeader(profile: profile, topPadding: topPadding),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ProfileCard(
                      title: 'البيانات الشخصية',
                      icon: Icons.person_outline_rounded,
                      rows: [
                        _InfoRow(label: 'البريد', value: profile.user.email ?? '—'),
                        _InfoRow(label: 'الهاتف', value: profile.user.phoneNumber ?? '—'),
                        _InfoRow(label: 'الجنس', value: _genderAr(profile.user.gender)),
                        _InfoRow(label: 'تاريخ الميلاد', value: profile.user.dateOfBirth ?? '—'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ProfileCard(
                      title: 'المعلومات الطبية',
                      icon: Icons.favorite_outline_rounded,
                      rows: [
                        _InfoRow(label: 'فصيلة الدم', value: profile.profile.bloodType ?? '—'),
                        _InfoRow(label: 'الحساسية', value: profile.profile.allergies ?? '—'),
                        _InfoRow(label: 'أمراض مزمنة', value: profile.profile.chronicConditions ?? '—'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ProfileCard(
                      title: 'جهة اتصال طوارئ',
                      icon: Icons.emergency_outlined,
                      rows: [
                        _InfoRow(label: 'الاسم', value: profile.profile.emergencyContactName ?? '—'),
                        _InfoRow(label: 'الهاتف', value: profile.profile.emergencyContactPhone ?? '—'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => Get.toNamed('/patient/edit-profile', arguments: profile),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('تعديل الملف الشخصي'),
                    ),
                    const SizedBox(height: 12),
                    _MenuItem(
                      icon: Icons.campaign_outlined,
                      label: 'الإعلانات',
                      onTap: () => Get.toNamed('/patient/announcements'),
                    ),
                    _MenuItem(
                      icon: Icons.notifications_outlined,
                      label: 'الإشعارات',
                      onTap: () => Get.toNamed('/patient/notifications'),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Top-level static helper — no closure, no instance allocation
  static String _genderAr(String? g) {
    switch (g?.toUpperCase()) {
      case 'MALE':
        return 'ذكر';
      case 'FEMALE':
        return 'أنثى';
      default:
        return '—';
    }
  }

  void _confirmLogout(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _LogoutSheet(),
    );
  }
}

// ─────────────────────────────────────────────
// Profile header
// ─────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final PatientModel profile;
  final double topPadding;

  const _ProfileHeader({required this.profile, required this.topPadding});

  @override
  Widget build(BuildContext context) {
    final contact = profile.user.email ?? profile.user.phoneNumber ?? '';

    return Container(
      color: AppTheme.white,
      padding: EdgeInsets.only(top: topPadding + 12, bottom: 24),
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
                _LogoutButton(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          UserAvatar(name: profile.user.name, size: 72),
          const SizedBox(height: 12),
          Text(
            profile.user.name,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            contact,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Logout button
// ─────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => const _LogoutSheet(),
      ),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.errorSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Logout bottom sheet — fully static widget
// ─────────────────────────────────────────────
class _LogoutSheet extends StatelessWidget {
  const _LogoutSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
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
            child: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 28),
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
            'هل تريد تسجيل الخروج من حسابك؟',
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

// ─────────────────────────────────────────────
// Profile info card
// ─────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_InfoRow> rows;

  const _ProfileCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: _kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Info row
// ─────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Menu item
// ─────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
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
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.all(Radius.circular(14)),
          boxShadow: _kMenuShadow,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
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