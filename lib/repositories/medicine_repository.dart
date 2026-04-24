import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';
import '../storage/hive_storage.dart';

import '../models/medicine.dart';

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
    final currentHour = dateTime.hour;

    return findAll().where((medicine) {
      return currentHour >= medicine.startHour &&
          currentHour < medicine.endHour;
    }).toList();
  }

  Future<void> deleteById(String id) async {
    await _box.delete(id);
  }
}