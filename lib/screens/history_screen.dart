import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../models/medicine_history.dart';
import '../repositories/history_repository.dart';
import '../repositories/medicine_repository.dart';
import '../services/medicine_tracking_service.dart';
import '../utils/time_formatter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen>
    with WidgetsBindingObserver {
  final medicineRepository = MedicineRepository();
  final historyRepository = HistoryRepository();

  late final MedicineTrackingService medicineTrackingService;

  Timer? historyRefreshTimer;

  List<MedicineHistory> historyItems = [];
  List<Medicine> medicines = [];

  bool isLoadingHistory = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    medicineTrackingService = MedicineTrackingService(
      medicineRepository: medicineRepository,
      historyRepository: historyRepository,
    );

    loadHistory();
    startAutoRefresh();
  }

  @override
  void dispose() {
    historyRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshHistory();
    }
  }

  void startAutoRefresh() {
    historyRefreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        refreshHistory();
      },
    );
  }

  Future<void> refreshHistory() async {
    await loadHistory();
  }

  Future<void> loadHistory() async {
    if (isLoadingHistory) {
      return;
    }

    isLoadingHistory = true;

    await medicineTrackingService.markExpiredMedicinesAsMissed();

    if (!mounted) {
      isLoadingHistory = false;
      return;
    }

    setState(() {
      historyItems = historyRepository.findAll();
      medicines = medicineRepository.findAll();
    });

    isLoadingHistory = false;
  }

  List<_HistoryDisplayItem> _buildDisplayItems() {
    final items = <_HistoryDisplayItem>[];

    for (final history in historyItems) {
      final medicine = findMedicineById(history.medicineId);

      items.add(
        _HistoryDisplayItem(
          medicineId: history.medicineId,
          medicineName: history.medicineName,
          medicineDosage: history.medicineDosage,
          medicineImagePath: history.medicineImagePath ?? medicine?.imagePath,
          status: history.status,
          createdAt: history.createdAt,
        ),
      );
    }

    final now = DateTime.now();

    for (final medicine in medicines) {
      final alreadyHasHistoryToday = historyItems.any((history) {
        return history.medicineId == medicine.id &&
            isSameDay(history.createdAt, now);
      });

      if (!alreadyHasHistoryToday) {
        items.add(
          _HistoryDisplayItem(
            medicineId: medicine.id,
            medicineName: medicine.name,
            medicineDosage: medicine.dosage,
            medicineImagePath: medicine.imagePath,
            status: MedicineHistoryStatus.pending,
            createdAt: now,
          ),
        );
      }
    }

    items.sort((first, second) {
      return second.createdAt.compareTo(first.createdAt);
    });

    return items;
  }

  Medicine? findMedicineById(String medicineId) {
    for (final medicine in medicines) {
      if (medicine.id == medicineId) {
        return medicine;
      }
    }

    return null;
  }

  Map<String, List<_HistoryDisplayItem>> _groupItemsByDay(
    List<_HistoryDisplayItem> items,
  ) {
    final groupedItems = <String, List<_HistoryDisplayItem>>{};

    for (final item in items) {
      final dayKey = createDayKey(item.createdAt);

      groupedItems.putIfAbsent(dayKey, () {
        return [];
      });

      groupedItems[dayKey]!.add(item);
    }

    return groupedItems;
  }

  String createDayKey(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  bool isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  @override
  Widget build(BuildContext context) {
    final displayItems = _buildDisplayItems();
    final groupedItems = _groupItemsByDay(displayItems);
    final dayKeys = groupedItems.keys.toList()
      ..sort((first, second) {
        return second.compareTo(first);
      });

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
        ),
        body: RefreshIndicator(
          onRefresh: refreshHistory,
          child: displayItems.isEmpty
              ? const _EmptyHistoryMessage()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: dayKeys.length,
                  itemBuilder: (context, index) {
                    final dayKey = dayKeys[index];
                    final items = groupedItems[dayKey]!;

                    return _HistoryDaySection(
                      dayKey: dayKey,
                      items: items,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _HistoryDisplayItem {
  final String medicineId;
  final String medicineName;
  final String medicineDosage;
  final String? medicineImagePath;
  final String status;
  final DateTime createdAt;

  const _HistoryDisplayItem({
    required this.medicineId,
    required this.medicineName,
    required this.medicineDosage,
    required this.medicineImagePath,
    required this.status,
    required this.createdAt,
  });
}

class _HistoryDaySection extends StatelessWidget {
  final String dayKey;
  final List<_HistoryDisplayItem> items;

  const _HistoryDaySection({
    required this.dayKey,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(dayKey);

    final takenCount = items.where((item) {
      return item.status == MedicineHistoryStatus.taken;
    }).length;

    final missedCount = items.where((item) {
      return item.status == MedicineHistoryStatus.missed;
    }).length;

    final pendingCount = items.where((item) {
      return item.status == MedicineHistoryStatus.pending;
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DayHeader(
          date: date,
          takenCount: takenCount,
          missedCount: missedCount,
          pendingCount: pendingCount,
        ),
        const SizedBox(height: 10),
        ...items.map((item) {
          return _HistoryMedicineCard(item: item);
        }),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime date;
  final int takenCount;
  final int missedCount;
  final int pendingCount;

  const _DayHeader({
    required this.date,
    required this.takenCount,
    required this.missedCount,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = TimeFormatter.formatArabicDateLabel(date);

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              dateLabel,
              style: const TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusSummaryChip(
                  label: 'تم أخذه',
                  count: takenCount,
                  color: Colors.green,
                  icon: Icons.check_circle,
                ),
                _StatusSummaryChip(
                  label: 'لم يتم أخذه',
                  count: missedCount,
                  color: Colors.red,
                  icon: Icons.cancel,
                ),
                _StatusSummaryChip(
                  label: 'في الانتظار',
                  count: pendingCount,
                  color: Colors.orange,
                  icon: Icons.hourglass_bottom,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusSummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatusSummaryChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        icon,
        color: color,
        size: 22,
      ),
      label: Text(
        '$label: $count',
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
      side: BorderSide(
        color: color.withValues(alpha: 0.35),
      ),
      backgroundColor: color.withValues(alpha: 0.10),
    );
  }
}

class _HistoryMedicineCard extends StatelessWidget {
  final _HistoryDisplayItem item;

  const _HistoryMedicineCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final statusStyle = _HistoryStatusStyle.fromStatus(item.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            right: BorderSide(
              color: statusStyle.color,
              width: 7,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _MedicineHistoryImage(imagePath: item.medicineImagePath),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      item.medicineName,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    if (item.medicineDosage.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.medicineDosage,
                        style: const TextStyle(
                          fontSize: 19,
                          height: 1.35,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                    const SizedBox(height: 10),
                    _HistoryStatusBadge(
                      statusText: statusStyle.text,
                      icon: statusStyle.icon,
                      color: statusStyle.color,
                    ),
                    if (item.status != MedicineHistoryStatus.pending) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${statusStyle.timeLabel} ${TimeFormatter.formatDateTime12(item.createdAt)}',
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.3,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicineHistoryImage extends StatelessWidget {
  final String? imagePath;

  const _MedicineHistoryImage({
    required this.imagePath,
  });

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!hasImage) {
      return Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: Colors.greenAccent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.medication,
          size: 44,
          color: Colors.green,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        File(imagePath!),
        width: 78,
        height: 78,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.medication,
              size: 44,
              color: Colors.green,
            ),
          );
        },
      ),
    );
  }
}

class _HistoryStatusBadge extends StatelessWidget {
  final String statusText;
  final IconData icon;
  final Color color;

  const _HistoryStatusBadge({
    required this.statusText,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryStatusStyle {
  final String text;
  final String timeLabel;
  final IconData icon;
  final Color color;

  const _HistoryStatusStyle({
    required this.text,
    required this.timeLabel,
    required this.icon,
    required this.color,
  });

  factory _HistoryStatusStyle.fromStatus(String status) {
    if (status == MedicineHistoryStatus.taken) {
      return const _HistoryStatusStyle(
        text: 'تم أخذه',
        timeLabel: 'تم أخذه الساعة',
        icon: Icons.check_circle,
        color: Colors.green,
      );
    }

    if (status == MedicineHistoryStatus.missed) {
      return const _HistoryStatusStyle(
        text: 'لم يتم أخذه',
        timeLabel: 'تم تسجيله كفائت الساعة',
        icon: Icons.cancel,
        color: Colors.red,
      );
    }

    return const _HistoryStatusStyle(
      text: 'في الانتظار',
      timeLabel: '',
      icon: Icons.hourglass_bottom,
      color: Colors.orange,
    );
  }
}

class _EmptyHistoryMessage extends StatelessWidget {
  const _EmptyHistoryMessage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: const [
        SizedBox(height: 100),
        Card(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
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
                  'عند أخذ دواء أو انتهاء وقته، سيظهر هنا في السجل.',
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
      ],
    );
  }
}