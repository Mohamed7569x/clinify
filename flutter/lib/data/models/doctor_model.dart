import 'user_model.dart';
import 'specialty_model.dart';

class DoctorProfileModel {
  final String id;
  final String userId;
  final String? specialtyId;
  final String? bio;
  final String? licenseNumber;
  final double rating;
  final int totalReviews;
  final String createdAt;

  DoctorProfileModel({
    required this.id,
    required this.userId,
    this.specialtyId,
    this.bio,
    this.licenseNumber,
    required this.rating,
    required this.totalReviews,
    required this.createdAt,
  });

  factory DoctorProfileModel.fromJson(Map<String, dynamic> json) {
    return DoctorProfileModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      specialtyId: json['specialty_id'],
      bio: json['bio'],
      licenseNumber: json['license_number'],
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class DoctorModel {
  final UserModel user;
  final DoctorProfileModel profile;
  final SpecialtyModel? specialty;

  DoctorModel({
    required this.user,
    required this.profile,
    this.specialty,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      user: UserModel.fromJson(json['user']),
      profile: DoctorProfileModel.fromJson(json['profile']),
      specialty: json['specialty'] != null
          ? SpecialtyModel.fromJson(json['specialty'])
          : null,
    );
  }
}
