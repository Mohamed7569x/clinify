class UserModel {
  final String id;
  final String clinicId;
  final String role;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? gender;
  final String? dateOfBirth;
  final String? avatarUrl;
  final bool isActive;
  final String createdAt;

  UserModel({
    required this.id,
    required this.clinicId,
    required this.role,
    required this.name,
    this.email,
    this.phoneNumber,
    this.gender,
    this.dateOfBirth,
    this.avatarUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      clinicId: json['clinic_id'] ?? '',
      role: json['role'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phoneNumber: json['phone_number'],
      gender: json['gender'],
      dateOfBirth: json['date_of_birth'],
      avatarUrl: json['avatar_url'],
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinic_id': clinicId,
      'role': role,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'avatar_url': avatarUrl,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }
}
