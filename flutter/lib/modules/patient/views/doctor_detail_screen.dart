import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/config/app_theme.dart';
import '../../../data/models/doctor_model.dart';
import '../../../widgets/shared_widgets.dart';
import '../controllers/patient_controllers.dart';
import 'package:table_calendar/table_calendar.dart';
// ─────────────────────────────────────────────
// Shared constants
// ─────────────────────────────────────────────
const _kCardShadow = [
  BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 2)),
];
const _kCardDecoration = BoxDecoration(
  color: AppTheme.white,
  borderRadius: BorderRadius.all(Radius.circular(16)),
  boxShadow: _kCardShadow,
);

// ═══════════════════════════════════════════
// Doctor Detail Screen
// ═══════════════════════════════════════════
class DoctorDetailScreen extends StatelessWidget {
  const DoctorDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final doctor = Get.arguments as DoctorModel;
    final specialty = doctor.specialty?.name ?? 'طب عام';
    final rating = doctor.profile.rating.toStringAsFixed(1);
    final license = doctor.profile.licenseNumber ?? '—';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        title: const Text('الملف الشخصي'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: Get.back,
        ),
      ),
      body: ListView(
        children: [
          // ── Header card ──
          Container(
            color: AppTheme.white,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                UserAvatar(name: doctor.user.name, size: 76),
                const SizedBox(height: 14),
                Text(
                  doctor.user.name,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  specialty,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),

                // Rating badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7E6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppTheme.warning,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: const TextStyle(
                              color: AppTheme.warning,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '(${doctor.profile.totalReviews} تقييم)',
                      style: const TextStyle(
                        color: AppTheme.textHint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Stats row
                Row(
                  children: [
                    _StatItem(
                      icon: Icons.medical_services_outlined,
                      label: 'التخصص',
                      value: specialty,
                    ),
                    const _VerticalDivider(),
                    _StatItem(
                      icon: Icons.badge_outlined,
                      label: 'الترخيص',
                      value: license,
                    ),
                    const _VerticalDivider(),
                    _StatItem(
                      icon: Icons.star_outline_rounded,
                      label: 'التقييم',
                      value: '$rating/5',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Bio ──
          if (doctor.profile.bio != null && doctor.profile.bio!.isNotEmpty)
            _SectionCard(
              title: 'نبذة عن الطبيب',
              icon: Icons.info_outline_rounded,
              child: Text(
                doctor.profile.bio!,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13.5,
                  height: 1.7,
                ),
              ),
            ),

          // ── Contact ──
          _SectionCard(
            title: 'معلومات التواصل',
            icon: Icons.contact_phone_outlined,
            child: Column(
              children: [
                if (doctor.user.email != null)
                  _InfoRow(label: 'البريد', value: doctor.user.email!),
                if (doctor.user.phoneNumber != null)
                  _InfoRow(label: 'الهاتف', value: doctor.user.phoneNumber!),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Booking button ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton.icon(
              onPressed: () => Get.toNamed('/patient/booking', arguments: doctor),
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: const Text('حجز موعد'),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Detail screen sub-widgets
// ─────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textHint, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 1,
      height: 40,
      child: ColoredBox(color: AppTheme.border),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: _kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
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
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              textAlign: TextAlign.left,
              textDirection: TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }
}
// ═══════════════════════════════════════════
// Booking Screen
// ═══════════════════════════════════════════
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late final BookingController ctrl;

  late final DateTime _initialDate;
  late final DateTime _firstDate;
  late final DateTime _lastDate;

  @override
  void initState() {
    super.initState();
    ctrl = Get.put(BookingController());
    ctrl.setDoctor(Get.arguments as DoctorModel);

    final now = DateTime.now();
    _firstDate = now;
    _initialDate = now.add(const Duration(days: 1));
    _lastDate = now.add(const Duration(days: 60));
  }

  @override
  Widget build(BuildContext context) {
    final doctorName = ctrl.doctor.user.name;
    final specialty = ctrl.doctor.specialty?.name ?? 'طب عام';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        title: const Text('حجز موعد'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: Get.back,
        ),
      ),
      body: Column(
        children: [
          // Doctor Card
          Container(
            color: AppTheme.white,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                UserAvatar(name: doctorName, size: 44),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      specialty,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: 12),

                // ✅ NEW CALENDAR
                _CalendarCard(
                  initialDate: _initialDate,
                  firstDate: _firstDate,
                  lastDate: _lastDate,
                  onDateChanged: ctrl.selectDate,
                ),

                const SizedBox(height: 16),

                _SlotsSection(ctrl: ctrl),

                const SizedBox(height: 28),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ConfirmButton(ctrl: ctrl),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// NEW CALENDAR (FIXED)
// ═══════════════════════════════════════════
class _CalendarCard extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateChanged;

  const _CalendarCard({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
  });

  @override
  State<_CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<_CalendarCard> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate;
    _selectedDay = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: _kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_month_rounded,
                  color: AppTheme.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'اختر التاريخ',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TableCalendar(
            firstDay: widget.firstDate,
            lastDay: widget.lastDate,
            focusedDay: _focusedDay,

            availableGestures: AvailableGestures.horizontalSwipe,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.saturday,

            selectedDayPredicate: (day) =>
                isSameDay(_selectedDay, day),

            onDaySelected: (selectedDay, focusedDay) {
              if (isSameDay(_selectedDay, selectedDay)) return;

              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              widget.onDateChanged(selectedDay);
            },

            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),

            pageAnimationEnabled: true,
          ),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────
// Slots section — rebuilds only on slot data changes
// ─────────────────────────────────────────────
class _SlotsSection extends StatelessWidget {
  final BookingController ctrl;

  const _SlotsSection({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.selectedDate.value == null) {
        return const _InfoBox(
          text: 'اختر تاريخاً لعرض المواعيد المتاحة',
          icon: Icons.touch_app_rounded,
        );
      }
      if (ctrl.isLoadingSlots.value) {
        return const Padding(
          padding: EdgeInsets.all(30),
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
        );
      }
      if (ctrl.availableSlots.isEmpty) {
        return const _InfoBox(
          text: 'لا توجد مواعيد متاحة في هذا اليوم',
          icon: Icons.event_busy_rounded,
        );
      }
      return _SlotsGrid(ctrl: ctrl);
    });
  }
}

// ─────────────────────────────────────────────
// Slots grid — extracted so Wrap children are stable widgets
// ─────────────────────────────────────────────
class _SlotsGrid extends StatelessWidget {
  final BookingController ctrl;

  const _SlotsGrid({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final slots = ctrl.availableSlots;
      final selectedSlot = ctrl.selectedSlot.value;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: _kCardDecoration,
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final slot in slots)
              _SlotChip(
                slot: slot,
                selected: selectedSlot?.startTime == slot.startTime &&
                    ctrl.selectedDate.value == ctrl.selectedDate.value,
                onTap: () => ctrl.selectSlot(slot),
              ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────
// Individual slot chip
// ─────────────────────────────────────────────
class _SlotChip extends StatelessWidget {
  final dynamic slot;
  final bool selected;
  final VoidCallback onTap;

  const _SlotChip({
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeLabel = slot.startTime.toString().substring(0, 5);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.primary
                  : AppTheme.inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? AppTheme.primary
                    : AppTheme.border,
                width: selected ? 1.5 : 1,
              ),
              boxShadow: selected
                  ? [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeLabel,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // 👇 علامة الصح (فرق بصري قوي)
                if (selected) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────
// Confirm button — rebuilds only on isBooking / selectedSlot
// ─────────────────────────────────────────────
class _ConfirmButton extends StatelessWidget {
  final BookingController ctrl;

  const _ConfirmButton({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final booking = ctrl.isBooking.value;
      final hasSlot = ctrl.selectedSlot.value != null;

      return ElevatedButton(
        onPressed: (!hasSlot || booking)
            ? null
            : () async {
          final ok = await ctrl.confirmBooking();
          if (ok) {
            Get.back();
            Get.back();
            Get.snackbar(
              'تم الحجز!',
              'تم حجز موعدك بنجاح',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppTheme.successSoft,
              colorText: AppTheme.success,
            );
          }
        },
        child: booking
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        )
            : const Text('تأكيد الحجز'),
      );
    });
  }
}

// ─────────────────────────────────────────────
// Info box (empty state for slots area)
// ─────────────────────────────────────────────
class _InfoBox extends StatelessWidget {
  final String text;
  final IconData icon;

  const _InfoBox({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}