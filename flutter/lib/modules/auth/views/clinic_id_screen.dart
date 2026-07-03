import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../app/config/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../controllers/auth_controller.dart';

class ClinicIdScreen extends GetView<AuthController> {
  ClinicIdScreen({super.key});

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: SafeArea(
          child: Obx(
                () => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 28),

                    if (controller.selectedClinic.value == null) ...[


                      controller.showClinicCodeInput.value
                          ? _buildClinicCodeBlock()
                          : _buildSearchBlock(),

                      const SizedBox(height: 18),

                      _buildModeSwitch(),
                    ] else ...[
                      _buildSelectedClinicCard(),
                      const SizedBox(height: 18),
                    ],

                    const SizedBox(height: 20),
                    _buildContinueButton(),
                    const SizedBox(height: 18),
                    _buildHelpCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD7EADF),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            // Base gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color(0xFFF4FBF8),
                      Color(0xFFEAF5F1),
                    ],
                  ),
                ),
              ),
            ),

            // Decorative blob in the top-right (RTL focal corner)
            Positioned(
              top: -50,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.12),
                      AppTheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // A second, smaller blob for layered depth
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.06),
                      AppTheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Eyebrow pill — sets the promise
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFD7EADF),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            size: 14,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'خطوة واحدة فقط',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary.withValues(alpha: 0.9),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Big hook — the "why"
                    const Text(
                      'عيادتك بين يديك',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Supporting line — the "what"
                    Text(
                      'احجز مواعيدك، تابع علاجك، وتواصل مع طبيبك بكل سهولة.',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary.withValues(alpha: 0.9),
                        height: 1.7,
                      ),
                    ),


                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'ابحث عن العيادة',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _searchCtrl,
          onChanged: controller.searchClinics,
          textInputAction: TextInputAction.search,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'اسم العيادة أو الفرع',
            hintStyle: TextStyle(
              color: AppTheme.textHint.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: controller.clinicQuery.value.isNotEmpty
                ? IconButton(
              onPressed: () {
                _searchCtrl.clear();
                FocusManager.instance.primaryFocus?.unfocus();
                controller.searchClinics('');
              },
              icon: const Icon(Icons.close_rounded),
              color: AppTheme.textSecondary,
            )
                : null,
            suffixIcon: const Padding(
              padding: EdgeInsetsDirectional.only(end: 12),
              child: Icon(
                Icons.search_rounded,
                color: AppTheme.primary,
                size: 24,
              ),
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            filled: true,
            fillColor: AppTheme.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: AppTheme.primary.withValues(alpha: 0.18),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: AppTheme.primary,
                width: 1.8,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (controller.isSearchingClinics.value)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          ),
        if (!controller.isSearchingClinics.value &&
            controller.clinicSearchResults.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              children: controller.clinicSearchResults
                  .asMap()
                  .entries
                  .map((entry) => _buildSearchResultItem(
                clinic: entry.value,
                isLast: entry.key == controller.clinicSearchResults.length - 1,
              ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildClinicCodeBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Label + helper hint on the same row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'اختياري',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary.withValues(alpha: 0.8),
              ),
            ),
            const Text(
              'أدخل رمز العيادة',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'إن حصلت على رمز من العيادة، أدخله هنا للانتقال مباشرة.',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),

        // The input — clean, no tiny hidden button
        TextFormField(
          controller: controller.clinicIdCtrl,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          inputFormatters: [
            _UpperCaseFormatter(),
            LengthLimitingTextInputFormatter(24),
          ],
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
            letterSpacing: 1.8,
          ),
          decoration: InputDecoration(
            hintText: 'مثال: ABC123',
            hintStyle: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppTheme.textHint.withValues(alpha: 0.55),
            ),
            prefixIcon: const Padding(
              padding: EdgeInsetsDirectional.only(start: 14, end: 8),
              child: Icon(
                Icons.qr_code_2_rounded,
                color: AppTheme.primary,
                size: 24,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            filled: true,
            fillColor: AppTheme.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: AppTheme.primary.withValues(alpha: 0.18),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: AppTheme.primary,
                width: 1.8,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: AppTheme.error,
                width: 1.4,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: AppTheme.error,
                width: 1.6,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
          ),
          validator: Validators.clinicId,
          onFieldSubmitted: (_) async {
            FocusManager.instance.primaryFocus?.unfocus();
            if (!_formKey.currentState!.validate()) return;
            await controller.submitClinicId();
          },
        ),
        const SizedBox(height: 12),

        // THE obvious action — full-width, clearly labeled, can't be missed
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: controller.isResolvingClinic.value
                ? null
                : () async {
              FocusManager.instance.primaryFocus?.unfocus();
              if (!_formKey.currentState!.validate()) return;
              await controller.submitClinicId();
            },
            icon: controller.isResolvingClinic.value
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            )
                : const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 22,
            ),
            label: Text(
              controller.isResolvingClinic.value
                  ? 'جاري التحقق...'
                  : 'التحقق من الرمز',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              disabledBackgroundColor:
              AppTheme.primary.withValues(alpha: 0.5),
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSwitch() {
    return Align(
      alignment: Alignment.center,
      child: TextButton(
        onPressed: () {
          FocusManager.instance.primaryFocus?.unfocus();
          if (controller.showClinicCodeInput.value) {
            controller.openSearchMode();
          } else {
            controller.openClinicCodeInput();
          }
        },
        child: Text(
          controller.showClinicCodeInput.value
              ? 'البحث باسم العيادة بدلاً من الرمز'
              : 'لديّ رمز العيادة',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultItem({
    required JoinBranchItem clinic,
    required bool isLast,
  }) {
    final subtitleParts = <String>[
      if ((clinic.groupName ?? '').trim().isNotEmpty) clinic.groupName!.trim(),
      if ((clinic.address ?? '').trim().isNotEmpty) clinic.address!.trim(),
    ];

    final subtitle = subtitleParts.join(' | ');

    return InkWell(
      onTap: () {
        _searchCtrl.clear();
        FocusManager.instance.primaryFocus?.unfocus();
        controller.chooseClinic(clinic);
      },
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(18))
          : BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
            bottom: BorderSide(color: Color(0xFFF0F2F5)),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.chevron_left_rounded,
              size: 28,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _clinicDisplayName(clinic),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF4FAF7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                color: AppTheme.primary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedClinicCard() {
    final clinic = controller.selectedClinic.value!;
    final address = (clinic.address ?? '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FBF6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.success.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  controller.clearSelectedClinic();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'تغيير العيادة',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  padding: EdgeInsets.zero,
                ),
              ),
              const Spacer(),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.success,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'تم اختيار العيادة',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _clinicDisplayName(clinic),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          if ((clinic.groupName ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              clinic.groupName!.trim(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (address.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              address,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              clinic.clinicId,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    final canContinue = controller.selectedClinic.value != null;

    return SizedBox(
      height: 58,
      child: ElevatedButton(
        onPressed: canContinue
            ? () {
          FocusManager.instance.primaryFocus?.unfocus();
          Get.toNamed('/login');
        }
            : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.white,
          disabledBackgroundColor: const Color(0xFFE5E7EB),
          disabledForegroundColor: const Color(0xFF9CA3AF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          canContinue ? 'متابعة' : 'اختر العيادة أولاً',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildHelpCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E6FF)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppTheme.info,
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'إذا لم تجد عيادتك في البحث، يمكنك إدخال رمز العيادة الذي حصلت عليه من الإدارة.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.7,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _clinicDisplayName(JoinBranchItem clinic) {
    final area = (clinic.area ?? '').trim();
    if (area.isEmpty) return clinic.clinicName;
    return '${clinic.clinicName} - $area';
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String number;
  final String label;

  const _StatBlock({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          number,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}