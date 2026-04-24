import '../models/medicine.dart';
import '../models/medicine_history.dart';
import '../models/medicine_status.dart';

class AppStore {
  static final List<Medicine> medicines = [
    const Medicine(
      id: '1',
      name: 'دواء الضغط',
      dosage: 'قرص واحد',
      startHour: 8,
      endHour: 10,
    ),
    const Medicine(
      id: '2',
      name: 'دواء السكر',
      dosage: 'قرص بعد الأكل',
      startHour: 16,
      endHour: 22,
    ),
    const Medicine(
      id: '3',
      name: 'فيتامين د',
      dosage: 'كبسولة واحدة',
      startHour: 20,
      endHour: 22,
    ),
  ];

  static final List<MedicineHistory> history = [];

  static void addMedicine(Medicine medicine) {
  medicines.add(medicine);
  }

  static void markMedicineAsTaken(Medicine medicine) {
    history.insert(
      0,
      MedicineHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        medicineId: medicine.id,
        medicineName: medicine.name,
        scheduledDate: DateTime.now(),
        status: MedicineStatus.taken,
        takenAt: DateTime.now(),
      ),
    );
  }
}