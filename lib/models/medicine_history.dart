class MedicineHistory {
  final String id;
  final String medicineId;
  final String medicineName;
  final String medicineDosage;
  final String? medicineImagePath;
  final String status;
  final DateTime createdAt;

  const MedicineHistory({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.medicineDosage,
    this.medicineImagePath,
    required this.status,
    required this.createdAt,
  });

  bool get isTaken => status == MedicineHistoryStatus.taken;

  bool get isMissed => status == MedicineHistoryStatus.missed;

  bool get isPending => status == MedicineHistoryStatus.pending;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'medicineDosage': medicineDosage,
      'medicineImagePath': medicineImagePath,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MedicineHistory.fromJson(Map<String, dynamic> json) {
    return MedicineHistory(
      id: json['id'] as String,
      medicineId: json['medicineId'] as String,
      medicineName: json['medicineName'] as String,
      medicineDosage: json['medicineDosage'] as String? ?? '',
      medicineImagePath: json['medicineImagePath'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class MedicineHistoryStatus {
  static const String pending = 'pending';
  static const String taken = 'taken';
  static const String missed = 'missed';

  const MedicineHistoryStatus._();
}