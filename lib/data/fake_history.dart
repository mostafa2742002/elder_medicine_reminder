import '../models/medicine_history.dart';
import '../models/medicine_status.dart';

final List<MedicineHistory> fakeHistory = [
  MedicineHistory(
    id: '1',
    medicineId: '1',
    medicineName: 'دواء الضغط',
    scheduledDate: DateTime.now(),
    status: MedicineStatus.taken,
    takenAt: DateTime.now(),
  ),
  MedicineHistory(
    id: '2',
    medicineId: '2',
    medicineName: 'دواء السكر',
    scheduledDate: DateTime.now(),
    status: MedicineStatus.missed,
  ),
  MedicineHistory(
    id: '3',
    medicineId: '3',
    medicineName: 'فيتامين د',
    scheduledDate: DateTime.now(),
    status: MedicineStatus.pending,
  ),
];