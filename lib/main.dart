import 'package:flutter/material.dart';

import 'screens/history_screen.dart';
import 'screens/medicine_management_screen.dart';
import 'screens/now_screen.dart';
import 'services/notification_service.dart';
import 'storage/hive_storage.dart';

final GlobalKey<_MainNavigationScreenState> mainNavigationKey =
    GlobalKey<_MainNavigationScreenState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveStorage.initialize();

  await NotificationService.initialize(
    onNotificationTap: (_) {
      mainNavigationKey.currentState?.openNowScreen();
    },
  );

  runApp(const ElderMedicineReminderApp());
}

class ElderMedicineReminderApp extends StatelessWidget {
  const ElderMedicineReminderApp({super.key});

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
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int selectedIndex;

  final List<Widget> screens = const [
    NowScreen(),
    HistoryScreen(),
    MedicineManagementScreen(),
  ];

  @override
  void initState() {
    super.initState();

    selectedIndex = widget.initialTabIndex;

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
      selectedIndex = 0;
    });
  }

  void changeSelectedScreen(int index) {
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
              icon: Icon(Icons.medication_outlined),
              selectedIcon: Icon(Icons.medication),
              label: 'إدارة الأدوية',
            ),
          ],
        ),
      ),
    );
  }
}