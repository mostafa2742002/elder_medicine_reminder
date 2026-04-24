import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/medicine.dart';
import '../models/medicine_history.dart';
import '../models/medicine_status.dart';
import '../storage/hive_storage.dart';

class HistoryRepository {
  Box<String> get _box => Hive.box<String>(HiveStorage.medicineHistoryBoxName);

  List<MedicineHistory> findAll() {
    final records = _box.values.map((jsonString) {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return MedicineHistory.fromJson(jsonMap);
    }).toList();

    records.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

    return records;
  }

  List<MedicineHistory> findTodayRecords() {
    final today = DateTime.now();

    return findAll().where((history) {
      return _isSameDay(history.scheduledDate, today);
    }).toList();
  }

  int countTakenToday() {
    return findTodayRecords().where((history) {
      return history.status == MedicineStatus.taken;
    }).length;
  }

  int countMissedToday() {
    return findTodayRecords().where((history) {
      return history.status == MedicineStatus.missed;
    }).length;
  }

  bool isMedicineTakenToday(String medicineId) {
    final today = DateTime.now();

    return findAll().any((history) {
      return history.medicineId == medicineId &&
          history.status == MedicineStatus.taken &&
          _isSameDay(history.scheduledDate, today);
    });
  }

  bool isMedicineHandledToday(String medicineId) {
    final today = DateTime.now();

    return findAll().any((history) {
      return history.medicineId == medicineId &&
          _isSameDay(history.scheduledDate, today) &&
          (history.status == MedicineStatus.taken ||
              history.status == MedicineStatus.missed);
    });
  }

  Future<void> markMedicineAsTaken(Medicine medicine) async {
    if (isMedicineHandledToday(medicine.id)) {
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

  Future<void> markMedicineAsMissed(Medicine medicine) async {
    if (isMedicineHandledToday(medicine.id)) {
      return;
    }

    final now = DateTime.now();

    final history = MedicineHistory(
      id: now.microsecondsSinceEpoch.toString(),
      medicineId: medicine.id,
      medicineName: medicine.name,
      scheduledDate: now,
      status: MedicineStatus.missed,
      takenAt: null,
    );

    await _box.put(history.id, jsonEncode(history.toJson()));
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}