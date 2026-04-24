import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveStorage {
  static const String medicinesBoxName = 'medicines';
  static const String medicineHistoryBoxName = 'medicine_history';

  static Future<void> initialize() async {
    if (kIsWeb) {
      await Hive.initFlutter();
    } else {
      final appDirectory = await getApplicationDocumentsDirectory();
      Hive.init(appDirectory.path);
    }

    await Hive.openBox<String>(medicinesBoxName);
    await Hive.openBox<String>(medicineHistoryBoxName);
  }
}