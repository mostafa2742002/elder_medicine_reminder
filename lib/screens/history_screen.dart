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

  String getStatusText(MedicineHistory history) {
    switch (history.status) {
      case MedicineStatus.pending:
        return 'في الانتظار ⏳';
      case MedicineStatus.taken:
        return getTakenText(history);
      case MedicineStatus.missed:
        return 'لم يتم أخذه ❌';
    }
  }

  String getTakenText(MedicineHistory history) {
    if (history.takenAt == null) {
      return 'تم أخذه ✅';
    }

    final takenTime = TimeFormatter.formatDateTime12(history.takenAt!);

    return 'تم أخذه الساعة $takenTime ✅';
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل الدواء'),
          centerTitle: true,
        ),
        body: historyRecords.isEmpty
            ? const _EmptyHistoryMessage()
            : RefreshIndicator(
                onRefresh: loadHistory,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: historyRecords.length,
                  itemBuilder: (context, index) {
                    final history = historyRecords[index];

                    return _HistoryCard(
                      history: history,
                      statusText: getStatusText(history),
                      statusIcon: getStatusIcon(history.status),
                    );
                  },
                ),
              ),
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
        padding: EdgeInsets.all(24),
        child: Text(
          'لا يوجد سجل حتى الآن',
          style: TextStyle(fontSize: 28),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final MedicineHistory history;
  final String statusText;
  final IconData statusIcon;

  const _HistoryCard({
    required this.history,
    required this.statusText,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = TimeFormatter.formatArabicDateLabel(
      history.scheduledDate,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(
          statusIcon,
          size: 42,
        ),
        title: Text(
          history.medicineName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '$dateLabel\n$statusText',
            style: const TextStyle(
              fontSize: 19,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}