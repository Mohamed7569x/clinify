class ScheduleModel {
  final String id;
  final String doctorId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final int slotDuration;
  final bool isActive;
  final String createdAt;

  ScheduleModel({
    required this.id,
    required this.doctorId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.slotDuration,
    required this.isActive,
    required this.createdAt,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] ?? '',
      doctorId: json['doctor_id'] ?? '',
      dayOfWeek: json['day_of_week'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      slotDuration: json['slot_duration'] ?? 30,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class BlockedSlotModel {
  final String id;
  final String doctorId;
  final String date;
  final String? startTime;
  final String? endTime;
  final String? reason;
  final String createdAt;

  BlockedSlotModel({
    required this.id,
    required this.doctorId,
    required this.date,
    this.startTime,
    this.endTime,
    this.reason,
    required this.createdAt,
  });

  factory BlockedSlotModel.fromJson(Map<String, dynamic> json) {
    return BlockedSlotModel(
      id: json['id'] ?? '',
      doctorId: json['doctor_id'] ?? '',
      date: json['date'] ?? '',
      startTime: json['start_time'],
      endTime: json['end_time'],
      reason: json['reason'],
      createdAt: json['created_at'] ?? '',
    );
  }
}
