import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../repositories/history_repository.dart';
import '../repositories/medicine_repository.dart';
import '../services/medicine_tracking_service.dart';
import '../utils/time_formatter.dart';

class NowScreen extends StatefulWidget {
  const NowScreen({super.key});

  @override
  State<NowScreen> createState() => _NowScreenState();
}

class _NowScreenState extends State<NowScreen> with WidgetsBindingObserver {
  final medicineRepository = MedicineRepository();
  final historyRepository = HistoryRepository();

  late final MedicineTrackingService medicineTrackingService;

  Timer? activeMedicineRefreshTimer;

  List<Medicine> activeMedicines = [];
  bool hasMedicineNow = false;
  bool isLoadingActiveMedicines = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    medicineTrackingService = MedicineTrackingService(
      medicineRepository: medicineRepository,
      historyRepository: historyRepository,
    );

    loadActiveMedicines();
    startAutoRefresh();
  }

  @override
  void dispose() {
    activeMedicineRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadActiveMedicines();
    }
  }

  void startAutoRefresh() {
    activeMedicineRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        loadActiveMedicines();
      },
    );
  }

  Future<void> loadActiveMedicines() async {
    if (isLoadingActiveMedicines) {
      return;
    }

    isLoadingActiveMedicines = true;

    await medicineTrackingService.markExpiredMedicinesAsMissed();

    final now = DateTime.now();
    final medicinesInCurrentRange = medicineRepository.findActiveMedicines(now);

    if (!mounted) {
      isLoadingActiveMedicines = false;
      return;
    }

    setState(() {
      hasMedicineNow = medicinesInCurrentRange.isNotEmpty;

      activeMedicines = medicinesInCurrentRange.where((medicine) {
        return !historyRepository.isMedicineHandledToday(medicine.id);
      }).toList();
    });

    isLoadingActiveMedicines = false;
  }

  Future<void> markMedicineAsTaken(Medicine medicine) async {
    await historyRepository.markMedicineAsTaken(medicine);
    await loadActiveMedicines();
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveMedicine = activeMedicines.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: hasActiveMedicine
            ? null
            : AppBar(
                title: const Text('أدوية الآن'),
                centerTitle: true,
              ),
        body: SafeArea(
          child: hasActiveMedicine
              ? _CurrentMedicineAlert(
                  key: ValueKey(activeMedicines.first.id),
                  medicine: activeMedicines.first,
                  remainingCount: activeMedicines.length,
                  onTaken: markMedicineAsTaken,
                )
              : _NoMedicineMessage(
                  message: hasMedicineNow
                      ? 'تم أخذ كل أدوية هذه الفترة ✅'
                      : 'لا يوجد دواء في الوقت الحالي',
                  icon: hasMedicineNow
                      ? Icons.check_circle
                      : Icons.notifications_off,
                ),
        ),
      ),
    );
  }
}

class _CurrentMedicineAlert extends StatefulWidget {
  final Medicine medicine;
  final int remainingCount;
  final void Function(Medicine medicine) onTaken;

  const _CurrentMedicineAlert({
    super.key,
    required this.medicine,
    required this.remainingCount,
    required this.onTaken,
  });

  @override
  State<_CurrentMedicineAlert> createState() => _CurrentMedicineAlertState();
}

class _CurrentMedicineAlertState extends State<_CurrentMedicineAlert> {
  final audioPlayer = AudioPlayer();

  StreamSubscription<void>? playerCompleteSubscription;

  bool isPlayingVoice = false;

  bool get hasVoiceMessage {
    final voicePath = widget.medicine.voiceMessagePath;

    return voicePath != null && voicePath.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();

    playerCompleteSubscription = audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        isPlayingVoice = false;
      });
    });

    playVoiceMessageAfterOpening();
  }

  @override
  void dispose() {
    playerCompleteSubscription?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  void playVoiceMessageAfterOpening() {
    if (!hasVoiceMessage) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      playOrStopVoiceMessage();
    });
  }

  Future<void> playOrStopVoiceMessage() async {
    final voicePath = widget.medicine.voiceMessagePath;

    if (voicePath == null || voicePath.isEmpty) {
      return;
    }

    final voiceFile = File(voicePath);

    if (!voiceFile.existsSync()) {
      return;
    }

    if (isPlayingVoice) {
      await audioPlayer.stop();

      if (!mounted) {
        return;
      }

      setState(() {
        isPlayingVoice = false;
      });

      return;
    }

    await audioPlayer.play(DeviceFileSource(voicePath));

    if (!mounted) {
      return;
    }

    setState(() {
      isPlayingVoice = true;
    });
  }

  Future<void> markCurrentMedicineAsTaken() async {
    await audioPlayer.stop();

    if (!mounted) {
      return;
    }

    setState(() {
      isPlayingVoice = false;
    });

    widget.onTaken(widget.medicine);
  }

  @override
  Widget build(BuildContext context) {
    final startTime = TimeFormatter.formatTime12(
      widget.medicine.startHour,
      widget.medicine.startMinute,
    );

    final endTime = TimeFormatter.formatTime12(
      widget.medicine.endHour,
      widget.medicine.endMinute,
    );

    return Container(
      width: double.infinity,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _RemainingMedicineBadge(remainingCount: widget.remainingCount),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _MedicineMainImage(imagePath: widget.medicine.imagePath),
                    const SizedBox(height: 24),
                    const Text(
                      'حان وقت الدواء',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.medicine.name,
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      widget.medicine.dosage,
                      style: const TextStyle(
                        fontSize: 28,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'من $startTime إلى $endTime',
                      style: const TextStyle(
                        fontSize: 24,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (hasVoiceMessage) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 70,
                        child: OutlinedButton.icon(
                          onPressed: playOrStopVoiceMessage,
                          icon: Icon(
                            isPlayingVoice ? Icons.stop : Icons.volume_up,
                            size: 30,
                          ),
                          label: Text(
                            isPlayingVoice
                                ? 'إيقاف الرسالة الصوتية'
                                : 'تشغيل رسالة الأسرة',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 86,
              child: FilledButton.icon(
                onPressed: markCurrentMedicineAsTaken,
                icon: const Icon(
                  Icons.check_circle,
                  size: 34,
                ),
                label: const Text(
                  'أخذت الدواء',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MedicineMainImage extends StatelessWidget {
  final String? imagePath;

  const _MedicineMainImage({
    required this.imagePath,
  });

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!hasImage) {
      return Container(
        height: 230,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.green.shade200,
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.medication_liquid,
          size: 130,
          color: Colors.green,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Image.file(
        File(imagePath!),
        height: 260,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 230,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.green.shade200,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.medication_liquid,
              size: 130,
              color: Colors.green,
            ),
          );
        },
      ),
    );
  }
}

class _RemainingMedicineBadge extends StatelessWidget {
  final int remainingCount;

  const _RemainingMedicineBadge({
    required this.remainingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.green.shade200,
        ),
      ),
      child: Text(
        'عدد الأدوية المتبقية: $remainingCount',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _NoMedicineMessage extends StatelessWidget {
  final String message;
  final IconData icon;

  const _NoMedicineMessage({
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 110,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                const Text(
                  'يمكنك الرجوع للشاشة الرئيسية أو فتح سجل الدواء',
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