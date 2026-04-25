import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/medicine.dart';
import '../models/medicine_history.dart';
import '../storage/hive_storage.dart';

class HistoryRepository {
  Box<String> get _box => Hive.box<String>(HiveStorage.historyBoxName);

  List<MedicineHistory> findAll() {
    final historyItems = <MedicineHistory>[];

    for (final key in _box.keys) {
      final jsonString = _box.get(key);

      if (jsonString == null || jsonString.trim().isEmpty) {
        continue;
      }

      try {
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        final history = MedicineHistory.fromJson(jsonMap);

        historyItems.add(history);
      } catch (_) {
        continue;
      }
    }

    historyItems.sort((first, second) {
      return second.createdAt.compareTo(first.createdAt);
    });

    return historyItems;
  }

  List<MedicineHistory> findTodayHistory() {
    final now = DateTime.now();

    return findAll().where((history) {
      return _isSameDay(history.createdAt, now);
    }).toList();
  }

  bool isMedicineHandledToday(String medicineId) {
    final now = DateTime.now();

    return findAll().any((history) {
      final isSameMedicine = history.medicineId == medicineId;
      final isToday = _isSameDay(history.createdAt, now);
      final isHandled = history.status == MedicineHistoryStatus.taken ||
          history.status == MedicineHistoryStatus.missed;

      return isSameMedicine && isToday && isHandled;
    });
  }

  Future<void> markMedicineAsTaken(Medicine medicine) async {
    final now = DateTime.now();

    final history = MedicineHistory(
      id: _createHistoryId(medicine.id, now),
      medicineId: medicine.id,
      medicineName: medicine.name,
      medicineDosage: medicine.dosage,
      medicineImagePath: medicine.imagePath,
      status: MedicineHistoryStatus.taken,
      createdAt: now,
    );

    await _save(history);
  }

  Future<void> markMedicineAsMissed(Medicine medicine) async {
    final now = DateTime.now();

    final history = MedicineHistory(
      id: _createHistoryId(medicine.id, now),
      medicineId: medicine.id,
      medicineName: medicine.name,
      medicineDosage: medicine.dosage,
      medicineImagePath: medicine.imagePath,
      status: MedicineHistoryStatus.missed,
      createdAt: now,
    );

    await _save(history);
  }

  Future<void> _save(MedicineHistory history) async {
    final jsonString = jsonEncode(history.toJson());

    await _box.put(history.id, jsonString);
  }

  String _createHistoryId(String medicineId, DateTime dateTime) {
    final dayKey = _createDayKey(dateTime);

    return '$medicineId-$dayKey';
  }

  String createDayKey(DateTime dateTime) {
    return _createDayKey(dateTime);
  }

  String _createDayKey(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}