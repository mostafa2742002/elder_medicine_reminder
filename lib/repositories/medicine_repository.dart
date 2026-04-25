import 'dart:convert';
import 'dart:developer' as developer;

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/medicine.dart';
import '../storage/hive_storage.dart';

class MedicineRepository {
  Box<String> get _box => Hive.box<String>(HiveStorage.medicinesBoxName);

  Future<void> save(Medicine medicine) async {
    final jsonString = jsonEncode(medicine.toJson());

    await _box.put(medicine.id, jsonString);

    developer.log(
      'Medicine saved: id=${medicine.id}, name=${medicine.name}, total=${_box.length}',
      name: 'MedicineRepository',
    );
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
      } catch (exception, stackTrace) {
        developer.log(
          'Failed to read medicine record. key=$key',
          name: 'MedicineRepository',
          error: exception,
          stackTrace: stackTrace,
        );
      }
    }

    medicines.sort((first, second) {
      return first.name.compareTo(second.name);
    });

    developer.log(
      'Loaded medicines count=${medicines.length}, rawBoxCount=${_box.length}',
      name: 'MedicineRepository',
    );

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

    developer.log(
      'Medicine deleted: id=$id, total=${_box.length}',
      name: 'MedicineRepository',
    );
  }

  int _toMinutes(int hour, int minute) {
    return (hour * 60) + minute;
  }
}