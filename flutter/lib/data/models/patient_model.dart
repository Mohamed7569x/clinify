import 'user_model.dart';

class PatientProfileModel {
  final String id;
  final String userId;
  final String? bloodType;
  final String? allergies;
  final String? chronicConditions;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String createdAt;

  PatientProfileModel({
    required this.id,
    required this.userId,
    this.bloodType,
    this.allergies,
    this.chronicConditions,
    this.emergencyContactName,
    this.emergencyContactPhone,
    required this.createdAt,
  });

  factory PatientProfileModel.fromJson(Map<String, dynamic> json) {
    return PatientProfileModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      bloodType: json['blood_type'],
      allergies: json['allergies'],
      chronicConditions: json['chronic_conditions'],
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactPhone: json['emergency_contact_phone'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

class PatientModel {
  final UserModel user;
  final PatientProfileModel profile;

  PatientModel({required this.user, required this.profile});

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      user: UserModel.fromJson(json['user']),
      profile: PatientProfileModel.fromJson(json['profile']),
    );
  }
}
