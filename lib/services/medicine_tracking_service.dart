import '../repositories/history_repository.dart';
import '../repositories/medicine_repository.dart';

class MedicineTrackingService {
  final MedicineRepository medicineRepository;
  final HistoryRepository historyRepository;

  MedicineTrackingService({
    required this.medicineRepository,
    required this.historyRepository,
  });

  Future<void> markExpiredMedicinesAsMissed() async {
    final now = DateTime.now();
    final currentMinutes = _toMinutes(now.hour, now.minute);
    final medicines = medicineRepository.findAll();

    for (final medicine in medicines) {
      final endMinutes = _toMinutes(
        medicine.endHour,
        medicine.endMinute,
      );

      final medicineWindowEnded = currentMinutes >= endMinutes;

      final alreadyHandledToday =
          historyRepository.isMedicineHandledToday(medicine.id);

      if (medicineWindowEnded && !alreadyHandledToday) {
        await historyRepository.markMedicineAsMissed(medicine);
      }
    }
  }

  int _toMinutes(int hour, int minute) {
    return (hour * 60) + minute;
  }
}