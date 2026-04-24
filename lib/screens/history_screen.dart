import 'package:flutter/material.dart';

import '../repositories/medicine_repository.dart';
import '../services/medicine_tracking_service.dart';
import '../models/medicine_history.dart';
import '../models/medicine_status.dart';
import '../repositories/history_repository.dart';

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

    setState(() {
      historyRecords = historyRepository.findAll();
    });
  }

  String getStatusText(MedicineStatus status) {
    switch (status) {
      case MedicineStatus.pending:
        return 'في الانتظار ⏳';
      case MedicineStatus.taken:
        return 'تم أخذه ✅';
      case MedicineStatus.missed:
        return 'لم يتم أخذه ❌';
    }
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

  String getTakenTimeText(MedicineHistory history) {
    if (history.takenAt == null) {
      return '';
    }

    final hour = history.takenAt!.hour.toString().padLeft(2, '0');
    final minute = history.takenAt!.minute.toString().padLeft(2, '0');

    return 'الساعة $hour:$minute';
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
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'لا يوجد سجل حتى الآن',
                    style: TextStyle(fontSize: 28),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: historyRecords.length,
                itemBuilder: (context, index) {
                  final history = historyRecords[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: Icon(
                        getStatusIcon(history.status),
                        size: 42,
                      ),
                      title: Text(
                        history.medicineName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${getStatusText(history.status)}\n${getTakenTimeText(history)}',
                        style: const TextStyle(fontSize: 19),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}