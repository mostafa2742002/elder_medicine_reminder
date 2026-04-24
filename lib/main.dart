import 'package:flutter/material.dart';
import 'storage/hive_storage.dart';

import 'screens/history_screen.dart';
import 'screens/medicine_management_screen.dart';
import 'screens/now_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveStorage.initialize();

  runApp(const ElderMedicineApp());
}

class ElderMedicineApp extends StatelessWidget {
  const ElderMedicineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تذكير الدواء',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void openScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تذكير الدواء'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.medication,
                size: 100,
              ),
              const SizedBox(height: 24),
              const Text(
                'أهلاً بك',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'هذا التطبيق يساعدك على تذكّر مواعيد الدواء بسهولة',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 70,
                child: ElevatedButton(
                  onPressed: () {
                    openScreen(context, const NowScreen());
                  },
                  child: const Text(
                    'أدوية الآن',
                    style: TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 70,
                child: OutlinedButton(
                  onPressed: () {
                    openScreen(context, const HistoryScreen());
                  },
                  child: const Text(
                    'سجل الدواء',
                    style: TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 70,
                child: OutlinedButton(
                  onPressed: () {
                    openScreen(context, const MedicineManagementScreen());
                  },
                  child: const Text(
                    'إدارة الأدوية',
                    style: TextStyle(fontSize: 26),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}