class Medicine {
  final String id;
  final String name;
  final String dosage;
  final String? imagePath;
  final String? voiceMessagePath;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    this.imagePath,
    this.voiceMessagePath,
    required this.startHour,
    this.startMinute = 0,
    required this.endHour,
    this.endMinute = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'imagePath': imagePath,
      'voiceMessagePath': voiceMessagePath,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      imagePath: json['imagePath'] as String?,
      voiceMessagePath: json['voiceMessagePath'] as String?,
      startHour: json['startHour'] as int,
      startMinute: json['startMinute'] as int? ?? 0,
      endHour: json['endHour'] as int,
      endMinute: json['endMinute'] as int? ?? 0,
    );
  }
}