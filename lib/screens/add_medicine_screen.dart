import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../repositories/medicine_repository.dart';

class AddMedicineScreen extends StatefulWidget {
  final Medicine? medicineToEdit;

  const AddMedicineScreen({
    super.key,
    this.medicineToEdit,
  });

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

  bool get isEditMode => widget.medicineToEdit != null;

  @override
  void initState() {
    super.initState();

    final medicine = widget.medicineToEdit;

    if (medicine != null) {
      nameController.text = medicine.name;
      dosageController.text = medicine.dosage;

      startHourController.text = convertFrom24HourTo12Hour(
        medicine.startHour,
      ).toString();

      endHourController.text = convertFrom24HourTo12Hour(
        medicine.endHour,
      ).toString();

      startPeriod = medicine.startHour < 12 ? 'AM' : 'PM';
      endPeriod = medicine.endHour < 12 ? 'AM' : 'PM';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    startHourController.dispose();
    endHourController.dispose();
    super.dispose();
  }

  int convertFrom24HourTo12Hour(int hour24) {
    final hour12 = hour24 % 12;

    if (hour12 == 0) {
      return 12;
    }

    return hour12;
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
      showErrorMessage(timeRangeError);
      return;
    }

    final startHour12 = int.parse(startHourController.text.trim());
    final endHour12 = int.parse(endHourController.text.trim());

    final startHour24 = convertTo24Hour(startHour12, startPeriod);
    final endHour24 = convertTo24Hour(endHour12, endPeriod);

    final medicine = Medicine(
      id: widget.medicineToEdit?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
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

  void showErrorMessage(String message) {
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
      style: const TextStyle(
        fontSize: 20,
        color: Colors.black,
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
    final title = isEditMode ? 'تعديل الدواء' : 'إضافة دواء';
    final headerTitle = isEditMode ? 'تعديل بيانات الدواء' : 'أضف دواء جديد';
    final headerSubtitle = isEditMode
        ? 'عدّل اسم الدواء أو الجرعة أو فترة الدواء.'
        : 'اكتب اسم الدواء والجرعة والفترة التي يمكن أخذ الدواء خلالها.';
    final saveButtonText = isEditMode ? 'حفظ التعديل' : 'حفظ الدواء';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FormHeader(
                    title: headerTitle,
                    subtitle: headerSubtitle,
                    icon: isEditMode ? Icons.edit : Icons.add_circle,
                  ),

                  const SizedBox(height: 24),

                  _FormSectionCard(
                    title: 'بيانات الدواء',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'اسم الدواء',
                            hintText: 'مثال: دواء الضغط',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.medication),
                          ),
                          style: const TextStyle(fontSize: 22),
                          validator: validateRequiredText,
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: dosageController,
                          decoration: const InputDecoration(
                            labelText: 'الجرعة',
                            hintText: 'مثال: قرص واحد بعد الأكل',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.format_list_numbered),
                          ),
                          style: const TextStyle(fontSize: 22),
                          validator: validateRequiredText,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  _FormSectionCard(
                    title: 'فترة الدواء',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'بداية الفترة',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
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

                        const SizedBox(height: 22),

                        const Text(
                          'نهاية الفترة',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
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

                        const SizedBox(height: 14),

                        const Text(
                          'مثال: من 8 صباحًا إلى 10 صباحًا',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    height: 76,
                    child: FilledButton.icon(
                      onPressed: saveMedicine,
                      icon: Icon(
                        isEditMode ? Icons.check : Icons.save,
                        size: 30,
                      ),
                      label: Text(
                        saveButtonText,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'ملاحظة: التطبيق يدعم حاليًا الفترات داخل نفس اليوم فقط.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
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

class _FormHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _FormHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(
              icon,
              size: 80,
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
          ],
        ),
      ),
    );
  }
}

class _FormSectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _FormSectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}