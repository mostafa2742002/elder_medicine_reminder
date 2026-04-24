import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../repositories/medicine_repository.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final formKey = GlobalKey<FormState>();
  final medicineRepository = MedicineRepository();

  final nameController = TextEditingController();
  final dosageController = TextEditingController();
  final startHourController = TextEditingController();
  final endHourController = TextEditingController();

  String startPeriod = 'AM';
  String endPeriod = 'AM';

  @override
  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    startHourController.dispose();
    endHourController.dispose();
    super.dispose();
  }

  int convertTo24Hour(int hour12, String period) {
    if (period == 'AM') {
      if (hour12 == 12) {
        return 0;
      }

      return hour12;
    }

    if (hour12 == 12) {
      return 12;
    }

    return hour12 + 12;
  }

  Future<void> saveMedicine() async {
    final isValid = formKey.currentState!.validate();

    if (!isValid) {
      return;
    }

    final timeRangeError = validateTimeRange();

    if (timeRangeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            timeRangeError,
            textDirection: TextDirection.rtl,
          ),
        ),
      );

      return;
    }

    final startHour12 = int.parse(startHourController.text.trim());
    final endHour12 = int.parse(endHourController.text.trim());

    final startHour24 = convertTo24Hour(startHour12, startPeriod);
    final endHour24 = convertTo24Hour(endHour12, endPeriod);

    final medicine = Medicine(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      dosage: dosageController.text.trim(),
      startHour: startHour24,
      endHour: endHour24,
    );

    await medicineRepository.save(medicine);

    if (!mounted) {
      return;
    }

    Navigator.pop(context, true);
  }
  
  String? validateRequiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }

    return null;
  }

  String? validateHour12(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }

    final hour = int.tryParse(value.trim());

    if (hour == null) {
      return 'اكتب رقم صحيح';
    }

    if (hour < 1 || hour > 12) {
      return 'الساعة يجب أن تكون من 1 إلى 12';
    }

    return null;
  }

    String? validateTimeRange() {
    final startHourText = startHourController.text.trim();
    final endHourText = endHourController.text.trim();

    final startHour12 = int.tryParse(startHourText);
    final endHour12 = int.tryParse(endHourText);

    if (startHour12 == null || endHour12 == null) {
      return null;
    }

    final startHour24 = convertTo24Hour(startHour12, startPeriod);
    final endHour24 = convertTo24Hour(endHour12, endPeriod);

    if (endHour24 <= startHour24) {
      return 'وقت النهاية يجب أن يكون بعد وقت البداية';
    }

    return null;
  }


  Widget buildPeriodDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(
        labelText: 'الفترة',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(
          value: 'AM',
          child: Text('صباحًا'),
        ),
        DropdownMenuItem(
          value: 'PM',
          child: Text('مساءً'),
        ),
      ],
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة دواء'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الدواء',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 22),
                  validator: validateRequiredText,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: dosageController,
                  decoration: const InputDecoration(
                    labelText: 'الجرعة',
                    hintText: 'مثال: قرص واحد',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 22),
                  validator: validateRequiredText,
                ),

                const SizedBox(height: 24),

                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'بداية فترة الدواء',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: startHourController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الساعة',
                          hintText: 'مثال: 8',
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 22),
                        validator: validateHour12,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: buildPeriodDropdown(
                        value: startPeriod,
                        onChanged: (value) {
                          setState(() {
                            startPeriod = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'نهاية فترة الدواء',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: endHourController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الساعة',
                          hintText: 'مثال: 10',
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 22),
                        validator: validateHour12,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: buildPeriodDropdown(
                        value: endPeriod,
                        onChanged: (value) {
                          setState(() {
                            endPeriod = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 70,
                  child: ElevatedButton(
                    onPressed: saveMedicine,
                    child: const Text(
                      'حفظ الدواء',
                      style: TextStyle(fontSize: 26),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}