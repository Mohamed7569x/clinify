import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/config/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends GetView<AuthController> {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Get.back(),
        ),
        title: const Text('إنشاء حساب'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: controller.registerFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ── Clinic badge ──
                Obx(() => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.business_rounded,
                              size: 16, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'التسجيل في ${controller.clinicId.value}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 20),

                // ── Header ──
                const Text(
                  'تسجيل مريض جديد',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),

                // ── Notice ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.warningSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppTheme.warning, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'سيتم تفعيل حسابك بعد موافقة إدارة العيادة.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ═══════════ Personal Info Section ═══════════
                _SectionHeader(icon: Icons.person_outline_rounded, title: 'البيانات الشخصية'),
                const SizedBox(height: 16),

                // Name
                const _FieldLabel('الاسم الكامل'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'مثال: أحمد محمد',
                    prefixIcon: Icon(Icons.badge_outlined, size: 22),
                  ),
                  validator: (v) => Validators.required(v, 'الاسم'),
                ),
                const SizedBox(height: 16),

                // Email
                const _FieldLabel('البريد الإلكتروني'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    hintText: 'example@email.com',
                    prefixIcon: Icon(Icons.email_outlined, size: 22),
                  ),
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),

                // Phone
                const _FieldLabel('رقم الهاتف'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.phoneCtrl,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    hintText: '+20 1x xxxx xxxx',
                    prefixIcon: Icon(Icons.phone_outlined, size: 22),
                  ),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 4),
                const Text(
                  'مطلوب إدخال البريد الإلكتروني أو رقم الهاتف على الأقل.',
                  style: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 28),

                // ═══════════ Password Section ═══════════
                _SectionHeader(icon: Icons.lock_outline_rounded, title: 'كلمة المرور'),
                const SizedBox(height: 16),

                const _FieldLabel('كلمة المرور'),
                const SizedBox(height: 8),
                Obx(() => TextFormField(
                      controller: controller.regPasswordCtrl,
                      obscureText: controller.obscurePassword.value,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon:
                            const Icon(Icons.lock_outline_rounded, size: 22),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.obscurePassword.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppTheme.textHint,
                            size: 20,
                          ),
                          onPressed: () =>
                              controller.obscurePassword.toggle(),
                        ),
                      ),
                      validator: Validators.password,
                    )),
                const SizedBox(height: 16),

                // Confirm
                const _FieldLabel('تأكيد كلمة المرور'),
                const SizedBox(height: 8),
                Obx(() => TextFormField(
                      controller: controller.confirmPasswordCtrl,
                      obscureText: controller.obscureConfirm.value,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon:
                            const Icon(Icons.lock_outline_rounded, size: 22),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.obscureConfirm.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppTheme.textHint,
                            size: 20,
                          ),
                          onPressed: () =>
                              controller.obscureConfirm.toggle(),
                        ),
                      ),
                      validator: (v) => Validators.confirmPassword(
                          v, controller.regPasswordCtrl.text),
                    )),
                const SizedBox(height: 16),

                // ── Password requirements ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.inputBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'يجب أن تحتوي كلمة المرور على:',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      _ReqItem('8 أحرف على الأقل'),
                      _ReqItem('حرف كبير (A-Z)'),
                      _ReqItem('حرف صغير (a-z)'),
                      _ReqItem('رقم (0-9)'),
                      _ReqItem('رمز خاص (!@#\$...)'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Register Button ──
                Obx(() => ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.registerPatient,
                      style: ElevatedButton.styleFrom(
                        elevation: controller.isLoading.value ? 0 : 2,
                        shadowColor: AppTheme.primary.withOpacity(0.3),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text('إنشاء الحساب'),
                    )),
                const SizedBox(height: 20),

                // ── Already have account ──
                Center(
                  child: TextButton(
                    onPressed: () => Get.back(),
                    child: const Text.rich(
                      TextSpan(
                        text: 'لديك حساب بالفعل؟  ',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text: 'تسجيل الدخول',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable Components ──

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ReqItem extends StatelessWidget {
  final String text;
  const _ReqItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppTheme.textHint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.textHint,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
