class SpecialtyModel {
  final String id;
  final String name;

  SpecialtyModel({required this.id, required this.name});

  factory SpecialtyModel.fromJson(Map<String, dynamic> json) {
    return SpecialtyModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}
