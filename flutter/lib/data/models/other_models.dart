// ── Available Slot ──
class AvailableSlotModel {
  final String startTime;
  final String endTime;

  AvailableSlotModel({required this.startTime, required this.endTime});

  factory AvailableSlotModel.fromJson(Map<String, dynamic> json) {
    return AvailableSlotModel(
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
    );
  }
}

// ── Prescription ──
class PrescriptionModel {
  final String id;
  final String appointmentId;
  final String medication;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? notes;
  final String createdAt;

  PrescriptionModel({
    required this.id,
    required this.appointmentId,
    required this.medication,
    this.dosage,
    this.frequency,
    this.duration,
    this.notes,
    required this.createdAt,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id'] ?? '',
      appointmentId: json['appointment_id'] ?? '',
      medication: json['medication'] ?? '',
      dosage: json['dosage'],
      frequency: json['frequency'],
      duration: json['duration'],
      notes: json['notes'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

// ── Review ──
class ReviewModel {
  final String id;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final int rating;
  final String? comment;
  final String createdAt;

  ReviewModel({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      appointmentId: json['appointment_id'] ?? '',
      patientId: json['patient_id'] ?? '',
      doctorId: json['doctor_id'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

// ── Chat Message ──
class ChatMessageModel {
  final String id;
  final String appointmentId;
  final String senderId;
  final String senderRole;
  final String message;
  final bool isRead;
  final String createdAt;

  ChatMessageModel({
    required this.id,
    required this.appointmentId,
    required this.senderId,
    required this.senderRole,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? '',
      appointmentId: json['appointment_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderRole: json['sender_role'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}

// ── Notification ──
class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final String? relatedId;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.relatedId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      isRead: json['is_read'] ?? false,
      relatedId: json['related_id'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

// ── Announcement ──
class AnnouncementModel {
  final String id;
  final String clinicId;
  final String createdBy;
  final String title;
  final String body;
  final String? targetRole;
  final String createdAt;

  AnnouncementModel({
    required this.id,
    required this.clinicId,
    required this.createdBy,
    required this.title,
    required this.body,
    this.targetRole,
    required this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] ?? '',
      clinicId: json['clinic_id'] ?? '',
      createdBy: json['created_by'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      targetRole: json['target_role'],
      createdAt: json['created_at'] ?? '',
    );
  }
}
