import 'package:flutter/material.dart';

import 'screens/history_screen.dart';
import 'screens/medicine_management_screen.dart';
import 'screens/now_screen.dart';
import 'storage/hive_storage.dart';

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
        colorSchemeSeed: Colors.green,
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
          title: const Text(
            'تذكير الدواء',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _WelcomeCard(),

                const SizedBox(height: 28),

                _HomeActionCard(
                  icon: Icons.medication,
                  title: 'أدوية الآن',
                  subtitle: 'اعرض الدواء المطلوب في هذا الوقت',
                  buttonText: 'فتح أدوية الآن',
                  onPressed: () {
                    openScreen(context, const NowScreen());
                  },
                ),

                const SizedBox(height: 18),

                _HomeActionCard(
                  icon: Icons.history,
                  title: 'سجل الدواء',
                  subtitle: 'اعرف الأدوية التي تم أخذها أو نسيانها',
                  buttonText: 'فتح السجل',
                  onPressed: () {
                    openScreen(context, const HistoryScreen());
                  },
                ),

                const SizedBox(height: 18),

                _HomeActionCard(
                  icon: Icons.settings,
                  title: 'إدارة الأدوية',
                  subtitle: 'إضافة أو حذف مواعيد الدواء',
                  buttonText: 'إدارة الأدوية',
                  onPressed: () {
                    openScreen(context, const MedicineManagementScreen());
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: const [
            Icon(
              Icons.health_and_safety,
              size: 90,
              color: Colors.green,
            ),
            SizedBox(height: 20),
            Text(
              'أهلاً بك',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'تطبيق بسيط يساعد على تذكّر الدواء وتسجيل ما تم أخذه أو نسيانه',
              style: TextStyle(
                fontSize: 22,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              icon,
              size: 70,
              color: Colors.green,
            ),

            const SizedBox(height: 14),

            Text(
              title,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 20,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 72,
              child: FilledButton(
                onPressed: onPressed,
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}