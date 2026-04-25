import 'package:flutter/material.dart';

import 'screens/history_screen.dart';
import 'screens/medicine_management_screen.dart';
import 'screens/now_screen.dart';
import 'screens/pin_lock_screen.dart';
import 'services/notification_service.dart';
import 'storage/hive_storage.dart';

final GlobalKey<MainNavigationScreenState> mainNavigationKey =
    GlobalKey<MainNavigationScreenState>();

final GlobalKey<HistoryScreenState> historyScreenKey =
    GlobalKey<HistoryScreenState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveStorage.initialize();

  await NotificationService.initialize(
    onNotificationTap: (_) {
      mainNavigationKey.currentState?.openNowScreen();
    },
  );

  runApp(const ElderMedicineApp());
}

class ElderMedicineApp extends StatelessWidget {
  const ElderMedicineApp({super.key});

  @override
  Widget build(BuildContext context) {
    final initialTabIndex =
        NotificationService.wasAppLaunchedByNotification ? 0 : 0;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تذكير الدواء',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
        useMaterial3: true,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: MainNavigationScreen(
        key: mainNavigationKey,
        initialTabIndex: initialTabIndex,
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final int initialTabIndex;

  const MainNavigationScreen({
    super.key,
    required this.initialTabIndex,
  });

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  static const int nowTabIndex = 0;
  static const int historyTabIndex = 1;
  static const int medicineManagementTabIndex = 2;

  static const String caregiverPin = '1234';

  late int selectedIndex;
  late final List<Widget> screens;

  bool caregiverAreaUnlocked = false;

  @override
  void initState() {
    super.initState();

    selectedIndex = widget.initialTabIndex;

    screens = [
      const NowScreen(),
      HistoryScreen(key: historyScreenKey),
      const MedicineManagementScreen(),
    ];

    if (NotificationService.wasAppLaunchedByNotification) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        openNowScreen();
      });
    }
  }

  void openNowScreen() {
    if (!mounted) {
      return;
    }

    setState(() {
      selectedIndex = nowTabIndex;
    });
  }

  Future<void> changeSelectedScreen(int index) async {
    if (index == historyTabIndex) {
      historyScreenKey.currentState?.refreshHistory();

      setState(() {
        selectedIndex = historyTabIndex;
      });

      return;
    }

    if (index == medicineManagementTabIndex && !caregiverAreaUnlocked) {
      final isPinCorrect = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const PinLockScreen(
            correctPin: caregiverPin,
          ),
        ),
      );

      if (!mounted) {
        return;
      }

      if (isPinCorrect != true) {
        return;
      }

      setState(() {
        caregiverAreaUnlocked = true;
        selectedIndex = medicineManagementTabIndex;
      });

      return;
    }

    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: selectedIndex,
          children: screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: changeSelectedScreen,
          height: 78,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.notifications_active_outlined),
              selectedIcon: Icon(Icons.notifications_active),
              label: 'الآن',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'سجل الدواء',
            ),
            NavigationDestination(
              icon: Icon(Icons.lock_outline),
              selectedIcon: Icon(Icons.lock_open),
              label: 'إدارة الأدوية',
            ),
          ],
        ),
      ),
    );
  }
}