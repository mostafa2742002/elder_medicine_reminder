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
    final medicines = medicineRepository.findAll();

    for (final medicine in medicines) {
      final medicineWindowEnded = now.hour >= medicine.endHour;
      final alreadyHandledToday =
          historyRepository.isMedicineHandledToday(medicine.id);

      if (medicineWindowEnded && !alreadyHandledToday) {
        await historyRepository.markMedicineAsMissed(medicine);
      }
    }
  }
}