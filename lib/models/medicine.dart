class Medicine {
  final String id;
  final String name;
  final String dosage;
  final int startHour;
  final int endHour;

  const Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.startHour,
    required this.endHour,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'startHour': startHour,
      'endHour': endHour,
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      startHour: json['startHour'] as int,
      endHour: json['endHour'] as int,
    );
  }
}