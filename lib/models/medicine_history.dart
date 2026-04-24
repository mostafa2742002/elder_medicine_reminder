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
}