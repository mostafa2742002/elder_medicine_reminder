import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/medicine.dart';
import '../storage/hive_storage.dart';

class MedicineRepository {
  Box<String> get _box => Hive.box<String>(HiveStorage.medicinesBoxName);

  Future<void> save(Medicine medicine) async {
    final jsonString = jsonEncode(medicine.toJson());
    await _box.put(medicine.id, jsonString);
  }

  List<Medicine> findAll() {
    return _box.values.map((jsonString) {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return Medicine.fromJson(jsonMap);
    }).toList();
  }

  List<Medicine> findActiveMedicines(DateTime dateTime) {
    final currentMinutes = _toMinutes(dateTime.hour, dateTime.minute);

    return findAll().where((medicine) {
      final startMinutes = _toMinutes(
        medicine.startHour,
        medicine.startMinute,
      );

      final endMinutes = _toMinutes(
        medicine.endHour,
        medicine.endMinute,
      );

      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }).toList();
  }

  Future<void> deleteById(String id) async {
    await _box.delete(id);
  }

  int _toMinutes(int hour, int minute) {
    return (hour * 60) + minute;
  }
}