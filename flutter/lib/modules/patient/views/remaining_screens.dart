import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/config/app_theme.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/models/other_models.dart';
import '../../../data/repositories/all_repositories.dart';
import '../../../widgets/shared_widgets.dart';
import '../controllers/patient_controllers.dart';

// ─────────────────────────────────────────────
// Shared constants
// ─────────────────────────────────────────────
const _kCardShadow = [
  BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 2)),
];
const _kChatOtherShadow = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
];
const _kInputBarShadow = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, -2)),
];

// ═══════════════════════════════════════════
// Edit Profile Screen
// ═══════════════════════════════════════════
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final PatientModel _p;
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _blood;
  late final TextEditingController _allergy;
  late final TextEditingController _chronic;
  late final TextEditingController _ecName;
  late final TextEditingController _ecPhone;

  @override
  void initState() {
    super.initState();
    _p = Get.arguments as PatientModel;
    _name = TextEditingController(text: _p.user.name);
    _email = TextEditingController(text: _p.user.email ?? '');
    _phone = TextEditingController(text: _p.user.phoneNumber ?? '');
    _blood = TextEditingController(text: _p.profile.bloodType ?? '');
    _allergy = TextEditingController(text: _p.profile.allergies ?? '');
    _chronic = TextEditingController(text: _p.profile.chronicConditions ?? '');
    _ecName = TextEditingController(text: _p.profile.emergencyContactName ?? '');
    _ecPhone = TextEditingController(text: _p.profile.emergencyContactPhone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _blood.dispose();
    _allergy.dispose();
    _chronic.dispose();
    _ecName.dispose();
    _ecPhone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{};

    void check(String key, TextEditingController ctrl, String? old) {
      final val = ctrl.text.trim();
      if (val != (old ?? '')) data[key] = val.isNotEmpty ? val : null;
    }

    check('name', _name, _p.user.name);
    check('email', _email, _p.user.email);
    check('phone_number', _phone, _p.user.phoneNumber);
    check('blood_type', _blood, _p.profile.bloodType);
    check('allergies', _allergy, _p.profile.allergies);
    check('chronic_conditions', _chronic, _p.profile.chronicConditions);
    check('emergency_contact_name', _ecName, _p.profile.emergencyContactName);
    check('emergency_contact_phone', _ecPhone, _p.profile.emergencyContactPhone);

    if (data.isEmpty) {
      Get.back();
      return;
    }

    await Get.find<PatientProfileController>().updateProfile(data);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        title: const Text('تعديل الملف'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: Get.back,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Personal info ──
            const _SectionHeader(
              title: 'البيانات الشخصية',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),
            _FormField(label: 'الاسم الكامل', controller: _name, required: true),
            _FormField(
              label: 'البريد الإلكتروني',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              ltr: true,
            ),
            _FormField(
              label: 'رقم الهاتف',
              controller: _phone,
              keyboardType: TextInputType.phone,
              ltr: true,
            ),

            const SizedBox(height: 20),

            // ── Medical info ──
            const _SectionHeader(
              title: 'المعلومات الطبية',
              icon: Icons.favorite_outline_rounded,
            ),
            const SizedBox(height: 14),
            _FormField(
              label: 'فصيلة الدم',
              controller: _blood,
              hint: 'مثال: A+',
            ),
            _FormField(
              label: 'الحساسية',
              controller: _allergy,
              hint: 'مثال: بنسلين',
              maxLines: 2,
            ),
            _FormField(
              label: 'أمراض مزمنة',
              controller: _chronic,
              hint: 'مثال: سكري',
              maxLines: 2,
            ),

            const SizedBox(height: 20),

            // ── Emergency contact ──
            const _SectionHeader(
              title: 'جهة اتصال طوارئ',
              icon: Icons.emergency_outlined,
            ),
            const SizedBox(height: 14),
            _FormField(label: 'اسم جهة الاتصال', controller: _ecName),
            _FormField(
              label: 'هاتف الطوارئ',
              controller: _ecPhone,
              keyboardType: TextInputType.phone,
              ltr: true,
            ),

            const SizedBox(height: 28),
            _SaveProfileButton(onSave: _save),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

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
          child: Icon(icon, size: 16, color: AppTheme.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppTheme.primary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Form field
// ─────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool required;
  final TextInputType? keyboardType;
  final String? hint;
  final int maxLines;
  final bool ltr;

  const _FormField({
    required this.label,
    required this.controller,
    this.required = false,
    this.keyboardType,
    this.hint,
    this.maxLines = 1,
    this.ltr = false,
  });

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
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            textDirection: ltr ? TextDirection.ltr : null,
            decoration: InputDecoration(hintText: hint),
            validator: required
                ? (v) => v == null || v.trim().isEmpty ? '$label مطلوب' : null
                : null,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Save button — own Obx scope
// ─────────────────────────────────────────────
class _SaveProfileButton extends StatelessWidget {
  final VoidCallback onSave;

  const _SaveProfileButton({required this.onSave});

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.find<PatientProfileController>();
    return Obx(() {
      final saving = profileCtrl.isSaving.value;
      return ElevatedButton(
        onPressed: saving ? null : onSave,
        child: saving
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        )
            : const Text('حفظ التغييرات'),
      );
    });
  }
}
// ═══════════════════════════════════════════
// Patient Chat Screen - Optimized
// ═══════════════════════════════════════════
class PatientChatScreen extends StatefulWidget {
  const PatientChatScreen({super.key});

  @override
  State<PatientChatScreen> createState() => _PatientChatScreenState();
}

class _PatientChatScreenState extends State<PatientChatScreen>
    with WidgetsBindingObserver {
  late final PatientChatController ctrl;
  final ScrollController _scrollController = ScrollController();

  Worker? _messagesWorker;
  Worker? _loadingWorker;

  int _lastMessageCount = 0;
  bool _didInitialJump = false;

  static const double _bubbleMaxWidthFactor = 0.75;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    ctrl = Get.put(PatientChatController());
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
        title: const Text('المحادثة'),
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
            child: _MessagesList(
              ctrl: ctrl,
              scrollCtrl: _scrollController,
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

// ─────────────────────────────────────────────
// Messages list
// ─────────────────────────────────────────────
class _MessagesList extends StatelessWidget {
  final PatientChatController ctrl;
  final ScrollController scrollCtrl;
  final double maxWidth;

  const _MessagesList({
    required this.ctrl,
    required this.scrollCtrl,
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
            subtitle: 'ابدأ محادثة مع طبيبك',
          ),
        );
      }

      final messages = ctrl.messages;

      return ListView.builder(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: messages.length,
        addRepaintBoundaries: true,
        addAutomaticKeepAlives: false,
        cacheExtent: 500,
        itemBuilder: (_, i) {
          final msg = messages[i];
          return RepaintBoundary(
            child: _ChatBubble(
              key: ValueKey(
                msg.id?.toString() ?? '${msg.createdAt}_${msg.senderRole}_$i',
              ),
              msg: msg,
              maxWidth: maxWidth,
            ),
          );
        },
      );
    });
  }
}

// ─────────────────────────────────────────────
// Chat bubble
// ─────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final ChatMessageModel msg;
  final double maxWidth;

  const _ChatBubble({
    super.key,
    required this.msg,
    required this.maxWidth,
  });

  static const TextStyle _doctorLabelStyle = TextStyle(
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
    final isMe = msg.senderRole == 'PATIENT';
    final time = _formatTime(msg.createdAt);

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
                      child: Text('الطبيب', style: _doctorLabelStyle),
                    ),
                  SelectableText(
                    msg.message,
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

// ─────────────────────────────────────────────
// Chat input bar
// ─────────────────────────────────────────────
class _ChatInputBar extends StatefulWidget {
  final PatientChatController ctrl;
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

  static final OutlineInputBorder _inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(24),
    borderSide: BorderSide.none,
  );

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
                    border: _inputBorder,
                    enabledBorder: _inputBorder,
                    focusedBorder: _inputBorder,
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

// ─────────────────────────────────────────────
// Send button
// ─────────────────────────────────────────────
class _SendButton extends StatelessWidget {
  final PatientChatController ctrl;

  const _SendButton({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sending = ctrl.isSending.value;

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
// Prescriptions Screen
// ═══════════════════════════════════════════
class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _RxState();
}

class _RxState extends State<PrescriptionsScreen> {
  final _repo = PrescriptionRepository();
  List<PrescriptionModel> _prescriptions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _prescriptions =
      await _repo.listForAppointment(Get.arguments as String);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        title: const Text('الوصفات الطبية'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: Get.back,
        ),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      )
          : _prescriptions.isEmpty
          ? const EmptyState(
        icon: Icons.medication_outlined,
        title: 'لا توجد وصفات',
        subtitle: 'لم يضف الطبيب وصفات بعد',
      )
          : RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _prescriptions.length,
          addRepaintBoundaries: true,
          addAutomaticKeepAlives: false,
          itemBuilder: (_, i) => _RxCard(rx: _prescriptions[i]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Prescription card
// ─────────────────────────────────────────────
class _RxCard extends StatelessWidget {
  final PrescriptionModel rx;

  const _RxCard({required this.rx});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.successSoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  color: AppTheme.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  rx.medication,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (rx.dosage != null) _RxRow(label: 'الجرعة', value: rx.dosage!),
          if (rx.frequency != null)
            _RxRow(label: 'التكرار', value: rx.frequency!),
          if (rx.duration != null) _RxRow(label: 'المدة', value: rx.duration!),
          if (rx.notes != null && rx.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.inputBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                rx.notes!,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RxRow extends StatelessWidget {
  final String label;
  final String value;

  const _RxRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Review Screen
// ═══════════════════════════════════════════
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewState();
}

class _ReviewState extends State<ReviewScreen> {
  final _repo = ReviewRepository();
  final _commentCtrl = TextEditingController();

  int _rating = 0;
  bool _submitting = false;
  bool _alreadyDone = false;
  bool _checking = true;
  late final String _appointmentId;

  // Precomputed — avoids switch in build
  static const _ratingLabels = <int, String>{
    0: 'اضغط للتقييم',
    1: 'سيء',
    2: 'أقل من المتوسط',
    3: 'متوسط',
    4: 'جيد',
    5: 'ممتاز',
  };

  @override
  void initState() {
    super.initState();
    _appointmentId = Get.arguments as String;
    _checkExisting();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkExisting() async {
    final existing = await _repo.getForAppointment(_appointmentId);
    if (existing != null) {
      setState(() {
        _alreadyDone = true;
        _rating = existing.rating;
      });
    }
    setState(() => _checking = false);
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      Get.snackbar(
        'خطأ',
        'يرجى اختيار تقييم',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.errorSoft,
        colorText: AppTheme.error,
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await _repo.create(
        appointmentId: _appointmentId,
        rating: _rating,
        comment: _commentCtrl.text.trim().isNotEmpty
            ? _commentCtrl.text.trim()
            : null,
      );
      Get.back();
      Get.snackbar(
        'شكراً!',
        'تم إرسال تقييمك',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successSoft,
        colorText: AppTheme.success,
      );
    } catch (_) {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: AppTheme.white,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_alreadyDone) {
      return Scaffold(
        backgroundColor: AppTheme.white,
        appBar: AppBar(
          backgroundColor: AppTheme.white,
          title: const Text('التقييم'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded),
            onPressed: Get.back,
          ),
        ),
        body: const _AlreadyReviewedBody(),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        title: const Text('التقييم'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: Get.back,
        ),
      ),
      body: _ReviewForm(
        rating: _rating,
        commentCtrl: _commentCtrl,
        submitting: _submitting,
        ratingLabel: _ratingLabels[_rating] ?? 'اضغط للتقييم',
        onRatingChanged: (v) => setState(() => _rating = v),
        onSubmit: _submit,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Already reviewed body — pure static widget
// ─────────────────────────────────────────────
class _AlreadyReviewedBody extends StatelessWidget {
  const _AlreadyReviewedBody();

  @override
  Widget build(BuildContext context) {
    // Rating passed via parent — accessed via route args already read
    // We just show the done state; actual rating stars use InteractiveStarRating
    // passed as non-reactive, so this widget never rebuilds.
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.successSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.success,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'تم التقييم مسبقاً',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(onPressed: Get.back, child: const Text('رجوع')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Review form — receives all values, no setState inside
// ─────────────────────────────────────────────
class _ReviewForm extends StatelessWidget {
  final int rating;
  final TextEditingController commentCtrl;
  final bool submitting;
  final String ratingLabel;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  const _ReviewForm({
    required this.rating,
    required this.commentCtrl,
    required this.submitting,
    required this.ratingLabel,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Text(
            'كيف كانت تجربتك؟',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'تقييمك يساعد في تحسين جودة الخدمة',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 32),
          InteractiveStarRating(
            rating: rating,
            onChanged: onRatingChanged,
            size: 44,
          ),
          const SizedBox(height: 8),
          Text(
            ratingLabel,
            style: const TextStyle(
              color: AppTheme.warning,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: commentCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'اكتب تعليقاً (اختياري)...',
            ),
          ),
          const SizedBox(height: 28),
          _SubmitButton(submitting: submitting, onSubmit: onSubmit),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Submit button
// ─────────────────────────────────────────────
class _SubmitButton extends StatelessWidget {
  final bool submitting;
  final VoidCallback onSubmit;

  const _SubmitButton({required this.submitting, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: submitting ? null : onSubmit,
      child: submitting
          ? const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Colors.white,
        ),
      )
          : const Text('إرسال التقييم'),
    );
  }
}