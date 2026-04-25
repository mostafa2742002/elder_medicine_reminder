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
    final medicines = <Medicine>[];

    for (final key in _box.keys) {
      final jsonString = _box.get(key);

      if (jsonString == null || jsonString.trim().isEmpty) {
        continue;
      }

      try {
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        final medicine = Medicine.fromJson(jsonMap);

        medicines.add(medicine);
      } catch (_) {
        continue;
      }
    }

    medicines.sort((first, second) {
      return first.name.compareTo(second.name);
    });

    return medicines;
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