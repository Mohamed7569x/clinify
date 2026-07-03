import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/config/app_theme.dart';
import '../../../widgets/shared_widgets.dart';
import '../controllers/patient_controllers.dart';

class DoctorListScreen extends GetView<DoctorListController> {
  const DoctorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: RefreshIndicator(
          onRefresh: () => controller.loadDoctors(forceRefresh: true),
        color: AppTheme.primary,
        child: CustomScrollView(
        slivers: [
          // ═══════════ HEADER ═══════════
          SliverToBoxAdapter(
            child: Container(
              color: AppTheme.white,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 20,
                right: 20,
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'الأطباء',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Search bar ──
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.inputBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      onChanged: controller.setSearch,
                      decoration: const InputDecoration(
                        hintText: 'ابحث عن طبيب...',
                        prefixIcon: Icon(Icons.search_rounded,
                            color: AppTheme.textHint, size: 20),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ═══════════ SPECIALTY FILTERS ═══════════
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: Obx(() => ListView(
                    scrollDirection: Axis.horizontal,

                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    children: [
                      _filterChip('الكل', null),
                      ...controller.specialties.map(
                          (s) => _filterChip(s.name, s.id)),
                    ],
                  )),
            ),
          ),

          // ═══════════ RESULTS COUNT ═══════════
          SliverToBoxAdapter(
            child: Obx(() => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    '${controller.filteredDoctors.length} طبيب',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )),
          ),

          // ═══════════ DOCTOR LIST ═══════════
          Obx(() {
            if (controller.isLoading.value) {
              return const SliverFillRemaining(
                child: Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primary)),
              );
            }
            if (controller.filteredDoctors.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.search_off_rounded,
                            color: AppTheme.primary, size: 32),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'لا يوجد أطباء',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'جرب تغيير البحث أو التخصص',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final doc = controller.filteredDoctors[i];
                    return _DoctorCard(doc: doc);
                  },
                  childCount: controller.filteredDoctors.length,
                ),
              ),
            );
          }),

          // Bottom space
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      )),
    );
  }

  Widget _filterChip(String label, String? specId) {
    return Obx(() {
      final selected = controller.selectedSpecialty.value == specId;
      return GestureDetector(
        onTap: () => controller.setSpecialtyFilter(specId),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : AppTheme.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.border,
              width: 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
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
    });
  }
}

// ═══════════════════════════════════════════
// Doctor Card
// ═══════════════════════════════════════════

class _DoctorCard extends StatelessWidget {
  final dynamic doc;
  const _DoctorCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF2A9D8F),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF22C55E),
    ];
    final bgColors = [
      const Color(0xFFE8F5F2),
      const Color(0xFFEBF2FF),
      const Color(0xFFF0EBFF),
      const Color(0xFFFFF7E6),
      const Color(0xFFFEE8E8),
      const Color(0xFFE8F8EE),
    ];
    final idx = doc.user.name.toString().codeUnitAt(0) % colors.length;

    return GestureDetector(
      onTap: () => Get.toNamed('/patient/doctor-detail', arguments: doc),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Avatar ──
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: bgColors[idx],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  _initials(doc.user.name.toString()),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors[idx],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // ── Info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.user.name.toString(),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    doc.specialty?.name?.toString() ?? 'طب عام',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Rating + reviews
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7E6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppTheme.warning, size: 14),
                            const SizedBox(width: 3),
                            Text(
                              (doc.profile.rating as double)
                                  .toStringAsFixed(1),
                              style: const TextStyle(
                                color: AppTheme.warning,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${doc.profile.totalReviews} تقييم)',
                        style: const TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Arrow ──
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_rounded, // RTL: points left
                color: AppTheme.primary,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    return name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();
  }
}
