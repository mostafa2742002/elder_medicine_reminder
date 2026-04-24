import 'package:flutter/material.dart';

import '../models/medicine_history.dart';
import '../models/medicine_status.dart';
import '../repositories/history_repository.dart';
import '../repositories/medicine_repository.dart';
import '../services/medicine_tracking_service.dart';
import '../utils/time_formatter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final historyRepository = HistoryRepository();
  final medicineRepository = MedicineRepository();

  late final MedicineTrackingService medicineTrackingService;

  List<MedicineHistory> historyRecords = [];

  @override
  void initState() {
    super.initState();

    medicineTrackingService = MedicineTrackingService(
      medicineRepository: medicineRepository,
      historyRepository: historyRepository,
    );

    loadHistory();
  }

  Future<void> loadHistory() async {
    await medicineTrackingService.markExpiredMedicinesAsMissed();

    if (!mounted) {
      return;
    }

    setState(() {
      historyRecords = historyRepository.findAll();
    });
  }

  Future<void> confirmClearHistory() async {
    if (historyRecords.isEmpty) {
      showMessage('لا يوجد سجل لحذفه');
      return;
    }

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'حذف السجل',
              textAlign: TextAlign.right,
            ),
            content: const Text(
              'هل تريد حذف سجل الدواء بالكامل؟\nلن يتم حذف الأدوية نفسها.',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 20,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text(
                  'إلغاء',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                icon: const Icon(Icons.delete),
                label: const Text(
                  'حذف السجل',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (shouldClear == true) {
      await clearHistory();
    }
  }

  Future<void> clearHistory() async {
    await historyRepository.clearAll();

    if (!mounted) {
      return;
    }

    setState(() {
      historyRecords = [];
    });

    showMessage('تم حذف سجل الدواء');
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  String getStatusText(MedicineHistory history) {
    switch (history.status) {
      case MedicineStatus.pending:
        return 'في الانتظار';
      case MedicineStatus.taken:
        return getTakenText(history);
      case MedicineStatus.missed:
        return 'لم يتم أخذه';
    }
  }

  String getTakenText(MedicineHistory history) {
    if (history.takenAt == null) {
      return 'تم أخذه';
    }

    final takenTime = TimeFormatter.formatDateTime12(history.takenAt!);

    return 'تم أخذه الساعة $takenTime';
  }

  IconData getStatusIcon(MedicineStatus status) {
    switch (status) {
      case MedicineStatus.pending:
        return Icons.hourglass_bottom;
      case MedicineStatus.taken:
        return Icons.check_circle;
      case MedicineStatus.missed:
        return Icons.cancel;
    }
  }

  Color getStatusColor(MedicineStatus status) {
    switch (status) {
      case MedicineStatus.pending:
        return Colors.orange;
      case MedicineStatus.taken:
        return Colors.green;
      case MedicineStatus.missed:
        return Colors.red;
    }
  }

  String getStatusBadgeText(MedicineStatus status) {
    switch (status) {
      case MedicineStatus.pending:
        return 'في الانتظار';
      case MedicineStatus.taken:
        return 'تم أخذه';
      case MedicineStatus.missed:
        return 'فائت';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasHistory = historyRecords.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'سجل الدواء',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'حذف السجل',
              onPressed: confirmClearHistory,
              icon: const Icon(Icons.delete_sweep),
            ),
          ],
        ),
        body: hasHistory
            ? RefreshIndicator(
                onRefresh: loadHistory,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: historyRecords.length,
                  itemBuilder: (context, index) {
                    final history = historyRecords[index];
                    final statusColor = getStatusColor(history.status);

                    return _HistoryCard(
                      history: history,
                      statusText: getStatusText(history),
                      statusBadgeText: getStatusBadgeText(history.status),
                      statusIcon: getStatusIcon(history.status),
                      statusColor: statusColor,
                    );
                  },
                ),
              )
            : const _EmptyHistoryMessage(),
      ),
    );
  }
}

class _EmptyHistoryMessage extends StatelessWidget {
  const _EmptyHistoryMessage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history,
                  size: 100,
                  color: Colors.green,
                ),
                SizedBox(height: 22),
                Text(
                  'لا يوجد سجل حتى الآن',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'سيظهر هنا الدواء الذي تم أخذه أو نسيانه.',
                  style: TextStyle(
                    fontSize: 22,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final MedicineHistory history;
  final String statusText;
  final String statusBadgeText;
  final IconData statusIcon;
  final Color statusColor;

  const _HistoryCard({
    required this.history,
    required this.statusText,
    required this.statusBadgeText,
    required this.statusIcon,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = TimeFormatter.formatArabicDateLabel(
      history.scheduledDate,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              statusIcon,
              size: 76,
              color: statusColor,
            ),
            const SizedBox(height: 12),
            Text(
              history.medicineName,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                statusBadgeText,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              dateLabel,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              statusText,
              style: const TextStyle(
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