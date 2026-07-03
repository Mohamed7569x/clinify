class AppointmentModel {
  final String id;
  final String clinicId;
  final String doctorId;
  final String patientId;
  final String doctorName;
  final String patientName;
  final String? specialtyName;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final String? consultationNotes;
  final String? cancellationReason;
  final String createdAt;

  AppointmentModel({
    required this.id,
    required this.clinicId,
    required this.doctorId,
    required this.patientId,
    this.doctorName = '',
    this.patientName = '',
    this.specialtyName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.consultationNotes,
    this.cancellationReason,
    required this.createdAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] ?? '',
      clinicId: json['clinic_id'] ?? '',
      doctorId: json['doctor_id'] ?? '',
      patientId: json['patient_id'] ?? '',
      doctorName: json['doctor_name'] ?? '',
      patientName: json['patient_name'] ?? '',
      specialtyName: json['specialty_name'],
      date: json['date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      status: json['status'] ?? 'PENDING',
      consultationNotes: json['consultation_notes'],
      cancellationReason: json['cancellation_reason'],
      createdAt: json['created_at'] ?? '',
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isConfirmed => status == 'CONFIRMED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';



  bool get isUpcoming {
    final now = DateTime.now();

    final dateParsed = DateTime.parse(date);
    final parts = startTime.split(':');

    final apptDateTime = DateTime(
      dateParsed.year,
      dateParsed.month,
      dateParsed.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    final isFuture = apptDateTime.isAfter(now);

    final isActiveStatus =
        status != 'COMPLETED' &&
            status != 'CANCELLED' &&
            status != 'NO_SHOW';

    return isFuture && isActiveStatus;
  }
}