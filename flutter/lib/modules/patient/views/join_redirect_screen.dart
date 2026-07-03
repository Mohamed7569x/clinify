import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/config/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';

class JoinRedirectScreen extends StatefulWidget {
  const JoinRedirectScreen({super.key});

  @override
  State<JoinRedirectScreen> createState() => _JoinRedirectScreenState();
}

class _JoinRedirectScreenState extends State<JoinRedirectScreen> {
  bool _handled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handled) return;
    _handled = true;
    _process();
  }

  Future<void> _process() async {
    final auth = Get.find<AuthController>();
    final uri = Uri.parse(Get.currentRoute);
    await auth.handleIncomingUri(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                color: AppTheme.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'جاري فتح العيادة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'يرجى الانتظار قليلاً...',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}