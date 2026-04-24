import 'medicine_status.dart';

class MedicineHistory {
  final String id;
  final String medicineId;
  final String medicineName;
  final DateTime scheduledDate;
  final MedicineStatus status;
  final DateTime? takenAt;

  const MedicineHistory({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.scheduledDate,
    required this.status,
    this.takenAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'scheduledDate': scheduledDate.toIso8601String(),
      'status': status.toJson(),
      'takenAt': takenAt?.toIso8601String(),
    };
  }

  factory MedicineHistory.fromJson(Map<String, dynamic> json) {
    final takenAtValue = json['takenAt'];

    return MedicineHistory(
      id: json['id'] as String,
      medicineId: json['medicineId'] as String,
      medicineName: json['medicineName'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      status: MedicineStatus.fromJson(json['status'] as String),
      takenAt: takenAtValue == null
          ? null
          : DateTime.parse(takenAtValue as String),
    );
  }
}