import 'package:hive_ce_flutter/hive_flutter.dart';

class HiveStorage {
  static const String medicinesBoxName = 'medicines';
  static const String historyBoxName = 'medicine_history';

  const HiveStorage._();

  static Future<void> initialize() async {
    await Hive.initFlutter();

    if (!Hive.isBoxOpen(medicinesBoxName)) {
      await Hive.openBox<String>(medicinesBoxName);
    }

    if (!Hive.isBoxOpen(historyBoxName)) {
      await Hive.openBox<String>(historyBoxName);
    }
  }
}