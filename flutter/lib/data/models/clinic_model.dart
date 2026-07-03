class MyClinicItem {
  final String clinicUuid;
  final String clinicId;
  final String clinicName;
  final String? branchName;
  final String? area;
  final String? branchSlug;
  final String? groupId;
  final String? groupName;
  final String? groupSlug;
  final String role;
  final bool isActive;
  final bool isCurrent;

  MyClinicItem({
    required this.clinicUuid,
    required this.clinicId,
    required this.clinicName,
    this.branchName,
    this.area,
    this.branchSlug,
    this.groupId,
    this.groupName,
    this.groupSlug,
    required this.role,
    required this.isActive,
    required this.isCurrent,
  });

  factory MyClinicItem.fromJson(Map<String, dynamic> json) {
    return MyClinicItem(
      clinicUuid: json['clinic_uuid'].toString(),
      clinicId: json['clinic_id'].toString(),
      clinicName: json['clinic_name'].toString(),
      branchName: json['branch_name']?.toString(),
      area: json['area']?.toString(),               // ← added
      branchSlug: json['branch_slug']?.toString(),
      groupId: json['group_id']?.toString(),
      groupName: json['group_name']?.toString(),
      groupSlug: json['group_slug']?.toString(),
      role: json['role'].toString(),
      isActive: json['is_active'] == true,
      isCurrent: json['is_current'] == true,        // ← fixed
    );
  }

  MyClinicItem copyWith({
    String? clinicUuid,
    String? clinicId,
    String? clinicName,
    String? branchName,
    String? area,
    String? branchSlug,
    String? groupId,
    String? groupName,
    String? groupSlug,
    String? role,
    bool? isActive,
    bool? isCurrent,
  }) {
    return MyClinicItem(
      clinicUuid: clinicUuid ?? this.clinicUuid,
      clinicId: clinicId ?? this.clinicId,
      clinicName: clinicName ?? this.clinicName,
      branchName: branchName ?? this.branchName,
      area: area ?? this.area,
      branchSlug: branchSlug ?? this.branchSlug,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupSlug: groupSlug ?? this.groupSlug,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }
}