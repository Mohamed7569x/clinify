import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/config/app_theme.dart';
import '../../../data/models/other_models.dart';
import '../../../data/repositories/all_repositories.dart';
import '../../../widgets/shared_widgets.dart';
import '../controllers/notification_controller.dart';

// ═══════════════════════════════════════════
// Notifications Screen
// ═══════════════════════════════════════════

class NotificationsScreen extends GetView<NotificationController> {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        title: const Text('الإشعارات'),
        leading: IconButton(icon: const Icon(Icons.arrow_forward_rounded), onPressed: () => Get.back()),
        actions: [
          Obx(() => controller.notifications.any((n) => !n.isRead)
              ? TextButton(onPressed: controller.markAllRead, child: const Text('قراءة الكل', style: TextStyle(fontSize: 12)))
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }
        if (controller.notifications.isEmpty) {
          return const EmptyState(icon: Icons.notifications_none_rounded, title: 'لا توجد إشعارات', subtitle: 'ستظهر الإشعارات هنا');
        }
        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: controller.loadNotifications,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: controller.notifications.length,
            itemBuilder: (_, i) {
              final n = controller.notifications[i];
              return GestureDetector(
                onTap: () { if (!n.isRead) controller.markRead(n.id); },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: n.isRead ? AppTheme.white : AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                    border: n.isRead ? null : Border.all(color: AppTheme.primary.withOpacity(0.15)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: _bg(n.type), borderRadius: BorderRadius.circular(10)),
                      child: Icon(_ic(n.type), size: 18, color: _clr(n.type)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700, fontSize: 13.5)),
                      const SizedBox(height: 3),
                      Text(n.body, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(_ago(n.createdAt), style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
                    ])),
                    if (!n.isRead)
                      Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4),
                          decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
                  ]),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Color _bg(String t) {
    switch (t) {
      case 'APPOINTMENT_CONFIRMED': case 'ACCOUNT_APPROVED': return AppTheme.successSoft;
      case 'APPOINTMENT_CANCELLED': return AppTheme.errorSoft;
      case 'APPOINTMENT_REMINDER': return AppTheme.warningSoft;
      case 'PRESCRIPTION_ADDED': return AppTheme.purpleSoft;
      default: return AppTheme.infoSoft;
    }
  }
  Color _clr(String t) {
    switch (t) {
      case 'APPOINTMENT_CONFIRMED': case 'ACCOUNT_APPROVED': return AppTheme.success;
      case 'APPOINTMENT_CANCELLED': return AppTheme.error;
      case 'APPOINTMENT_REMINDER': return AppTheme.warning;
      case 'PRESCRIPTION_ADDED': return AppTheme.purple;
      default: return AppTheme.primary;
    }
  }
  IconData _ic(String t) {
    switch (t) {
      case 'APPOINTMENT_BOOKED': return Icons.calendar_today_rounded;
      case 'APPOINTMENT_CONFIRMED': return Icons.check_circle_outline;
      case 'APPOINTMENT_CANCELLED': return Icons.cancel_outlined;
      case 'APPOINTMENT_REMINDER': return Icons.alarm_rounded;
      case 'PRESCRIPTION_ADDED': return Icons.medication_rounded;
      case 'ACCOUNT_APPROVED': return Icons.person_add_alt_1_rounded;
      default: return Icons.notifications_outlined;
    }
  }
  String _ago(String dt) {
    try { final d = DateTime.parse(dt); final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
      if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return ''; }
  }
}

// ═══════════════════════════════════════════
// Announcements Screen
// ═══════════════════════════════════════════

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});
  @override
  State<AnnouncementsScreen> createState() => _AnnoState();
}

class _AnnoState extends State<AnnouncementsScreen> {
  final AnnouncementRepository _repo = AnnouncementRepository();
  List<AnnouncementModel> _list = []; bool _ld = true;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { setState(() => _ld = true); try { _list = await _repo.list(); } catch (_) {} setState(() => _ld = false); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(backgroundColor: AppTheme.white, title: const Text('الإعلانات'),
          leading: IconButton(icon: const Icon(Icons.arrow_forward_rounded), onPressed: () => Get.back())),
      body: _ld ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _list.isEmpty ? const EmptyState(icon: Icons.campaign_outlined, title: 'لا توجد إعلانات', subtitle: 'ستظهر إعلانات العيادة هنا')
          : RefreshIndicator(color: AppTheme.primary, onRefresh: _load, child: ListView.builder(
              padding: const EdgeInsets.all(20), itemCount: _list.length,
              itemBuilder: (_, i) {
                final a = _list[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 2))]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFFFF7E6), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.campaign_rounded, color: AppTheme.warning, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                    ]),
                    const SizedBox(height: 10),
                    Text(a.body, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.6)),
                    const SizedBox(height: 8),
                    Text(_fmtDate(a.createdAt), style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
                  ]),
                );
              })),
    );
  }
  String _fmtDate(String dt) { try { final d = DateTime.parse(dt); const m = ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر']; return '${d.day} ${m[d.month-1]} ${d.year}'; } catch (_) { return dt; } }
}
