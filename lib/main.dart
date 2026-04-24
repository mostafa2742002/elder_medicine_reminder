import 'package:flutter/material.dart';

import 'repositories/history_repository.dart';
import 'repositories/medicine_repository.dart';
import 'screens/history_screen.dart';
import 'screens/medicine_management_screen.dart';
import 'screens/now_screen.dart';
import 'services/medicine_tracking_service.dart';
import 'services/notification_service.dart';
import 'storage/hive_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveStorage.initialize();
  await NotificationService.initialize();
  await NotificationService.scheduleAllMedicineNotifications();

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final medicineRepository = MedicineRepository();
  final historyRepository = HistoryRepository();

  late final MedicineTrackingService medicineTrackingService;

  int medicineCount = 0;
  int takenTodayCount = 0;
  int missedTodayCount = 0;

  @override
  void initState() {
    super.initState();

    medicineTrackingService = MedicineTrackingService(
      medicineRepository: medicineRepository,
      historyRepository: historyRepository,
    );

    loadSummary();
  }

  Future<void> loadSummary() async {
    await medicineTrackingService.markExpiredMedicinesAsMissed();

    if (!mounted) {
      return;
    }

    setState(() {
      medicineCount = medicineRepository.findAll().length;
      takenTodayCount = historyRepository.countTakenToday();
      missedTodayCount = historyRepository.countMissedToday();
    });
  }

  Future<void> openScreen(BuildContext context, Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    );

    await loadSummary();
  }

  Future<void> showTestNotification() async {
    await NotificationService.showTestNotification();
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
          actions: [
            IconButton(
              tooltip: 'اختبار التنبيه',
              onPressed: showTestNotification,
              icon: const Icon(Icons.notifications_active),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: loadSummary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _WelcomeCard(),
                  const SizedBox(height: 20),
                  _TodaySummaryCard(
                    medicineCount: medicineCount,
                    takenTodayCount: takenTodayCount,
                    missedTodayCount: missedTodayCount,
                  ),
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
                    subtitle: 'إضافة أو تعديل أو حذف مواعيد الدواء',
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
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
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

class _TodaySummaryCard extends StatelessWidget {
  final int medicineCount;
  final int takenTodayCount;
  final int missedTodayCount;

  const _TodaySummaryCard({
    required this.medicineCount,
    required this.takenTodayCount,
    required this.missedTodayCount,
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
            const Text(
              'ملخص اليوم',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.medication,
                    label: 'الأدوية',
                    value: medicineCount.toString(),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.check_circle,
                    label: 'تم أخذها',
                    value: takenTodayCount.toString(),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.cancel,
                    label: 'فائتة',
                    value: missedTodayCount.toString(),
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 42,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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