import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/medicine.dart';
import '../models/medicine_history.dart';
import '../models/medicine_status.dart';

class HistoryRepository {
  static const String boxName = 'medicine_history';

  Box<String> get _box => Hive.box<String>(boxName);

  List<MedicineHistory> findAll() {
    final records = _box.values.map((jsonString) {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return MedicineHistory.fromJson(jsonMap);
    }).toList();

    records.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

    return records;
  }

  bool isMedicineTakenToday(String medicineId) {
    final today = DateTime.now();

    return findAll().any((history) {
      return history.medicineId == medicineId &&
          history.status == MedicineStatus.taken &&
          _isSameDay(history.scheduledDate, today);
    });
  }

  Future<void> markMedicineAsTaken(Medicine medicine) async {
    if (isMedicineTakenToday(medicine.id)) {
      return;
    }

    final now = DateTime.now();

    final history = MedicineHistory(
      id: now.microsecondsSinceEpoch.toString(),
      medicineId: medicine.id,
      medicineName: medicine.name,
      scheduledDate: now,
      status: MedicineStatus.taken,
      takenAt: now,
    );

    await _box.put(history.id, jsonEncode(history.toJson()));
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}