import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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
  final imagePicker = ImagePicker();

  final nameController = TextEditingController();
  final dosageController = TextEditingController();

  final startHourController = TextEditingController();
  final startMinuteController = TextEditingController();

  final endHourController = TextEditingController();
  final endMinuteController = TextEditingController();

  String? imagePath;

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
      imagePath = medicine.imagePath;

      startHourController.text = convertFrom24HourTo12Hour(
        medicine.startHour,
      ).toString();

      startMinuteController.text = medicine.startMinute.toString().padLeft(
            2,
            '0',
          );

      endHourController.text = convertFrom24HourTo12Hour(
        medicine.endHour,
      ).toString();

      endMinuteController.text = medicine.endMinute.toString().padLeft(
            2,
            '0',
          );

      startPeriod = medicine.startHour < 12 ? 'AM' : 'PM';
      endPeriod = medicine.endHour < 12 ? 'AM' : 'PM';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    startHourController.dispose();
    startMinuteController.dispose();
    endHourController.dispose();
    endMinuteController.dispose();
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

  Future<void> pickMedicineImage(ImageSource imageSource) async {
    try {
      final pickedImage = await imagePicker.pickImage(
        source: imageSource,
        imageQuality: 85,
      );

      if (pickedImage == null) {
        return;
      }

      final savedImagePath = await saveImageInsideAppFolder(pickedImage);

      if (!mounted) {
        return;
      }

      setState(() {
        imagePath = savedImagePath;
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }

      showErrorMessage('حدث خطأ أثناء اختيار الصورة');
    }
  }

  Future<String> saveImageInsideAppFolder(XFile pickedImage) async {
    final appDirectory = await getApplicationDocumentsDirectory();

    final medicineImagesDirectory = Directory(
      path.join(appDirectory.path, 'medicine_images'),
    );

    if (!await medicineImagesDirectory.exists()) {
      await medicineImagesDirectory.create(recursive: true);
    }

    final extension = path.extension(pickedImage.path).isEmpty
        ? '.jpg'
        : path.extension(pickedImage.path);

    final fileName = '${DateTime.now().microsecondsSinceEpoch}$extension';

    final savedImagePath = path.join(
      medicineImagesDirectory.path,
      fileName,
    );

    final pickedImageFile = File(pickedImage.path);
    final savedImageFile = await pickedImageFile.copy(savedImagePath);

    return savedImageFile.path;
  }

  void removeMedicineImage() {
    setState(() {
      imagePath = null;
    });
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
    final startMinute = int.parse(startMinuteController.text.trim());

    final endHour12 = int.parse(endHourController.text.trim());
    final endMinute = int.parse(endMinuteController.text.trim());

    final startHour24 = convertTo24Hour(startHour12, startPeriod);
    final endHour24 = convertTo24Hour(endHour12, endPeriod);

    final medicine = Medicine(
      id: widget.medicineToEdit?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      dosage: dosageController.text.trim(),
      imagePath: imagePath,
      startHour: startHour24,
      startMinute: startMinute,
      endHour: endHour24,
      endMinute: endMinute,
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

  String? validateMinute(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }

    final minute = int.tryParse(value.trim());

    if (minute == null) {
      return 'اكتب رقم صحيح';
    }

    if (minute < 0 || minute > 59) {
      return 'الدقائق يجب أن تكون من 0 إلى 59';
    }

    return null;
  }

  String? validateTimeRange() {
    final startHour12 = int.tryParse(startHourController.text.trim());
    final startMinute = int.tryParse(startMinuteController.text.trim());

    final endHour12 = int.tryParse(endHourController.text.trim());
    final endMinute = int.tryParse(endMinuteController.text.trim());

    if (startHour12 == null ||
        startMinute == null ||
        endHour12 == null ||
        endMinute == null) {
      return null;
    }

    final startHour24 = convertTo24Hour(startHour12, startPeriod);
    final endHour24 = convertTo24Hour(endHour12, endPeriod);

    final startTotalMinutes = toMinutes(startHour24, startMinute);
    final endTotalMinutes = toMinutes(endHour24, endMinute);

    if (endTotalMinutes <= startTotalMinutes) {
      return 'وقت النهاية يجب أن يكون بعد وقت البداية';
    }

    return null;
  }

  int toMinutes(int hour, int minute) {
    return (hour * 60) + minute;
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
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'الفترة',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 18,
        ),
      ),
      style: const TextStyle(
        fontSize: 18,
        color: Colors.black,
      ),
      items: const [
        DropdownMenuItem(
          value: 'AM',
          child: Text(
            'صباحًا',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DropdownMenuItem(
          value: 'PM',
          child: Text(
            'مساءً',
            overflow: TextOverflow.ellipsis,
          ),
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
        ? 'عدّل اسم الدواء أو الجرعة أو الصورة أو فترة الدواء.'
        : 'اكتب اسم الدواء والجرعة وأضف صورة واضحة للدواء.';
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
                    title: 'صورة الدواء',
                    child: _MedicineImagePickerCard(
                      imagePath: imagePath,
                      onPickFromGallery: () {
                        pickMedicineImage(ImageSource.gallery);
                      },
                      onTakePhoto: () {
                        pickMedicineImage(ImageSource.camera);
                      },
                      onRemoveImage: removeMedicineImage,
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
                        _TimeInputRow(
                          hourController: startHourController,
                          minuteController: startMinuteController,
                          period: startPeriod,
                          onPeriodChanged: (value) {
                            setState(() {
                              startPeriod = value!;
                            });
                          },
                          validateHour: validateHour12,
                          validateMinute: validateMinute,
                          buildPeriodDropdown: buildPeriodDropdown,
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
                        _TimeInputRow(
                          hourController: endHourController,
                          minuteController: endMinuteController,
                          period: endPeriod,
                          onPeriodChanged: (value) {
                            setState(() {
                              endPeriod = value!;
                            });
                          },
                          validateHour: validateHour12,
                          validateMinute: validateMinute,
                          buildPeriodDropdown: buildPeriodDropdown,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'مثال: من 5:36 مساءً إلى 6:30 مساءً',
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

class _MedicineImagePickerCard extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onPickFromGallery;
  final VoidCallback onTakePhoto;
  final VoidCallback onRemoveImage;

  const _MedicineImagePickerCard({
    required this.imagePath,
    required this.onPickFromGallery,
    required this.onTakePhoto,
    required this.onRemoveImage,
  });

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.green.shade200,
            ),
          ),
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(
                    File(imagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const _ImagePlaceholder();
                    },
                  ),
                )
              : const _ImagePlaceholder(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: FilledButton.icon(
            onPressed: onPickFromGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text(
              'اختيار صورة من المعرض',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: OutlinedButton.icon(
            onPressed: onTakePhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text(
              'التقاط صورة بالكاميرا',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
        if (hasImage) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: TextButton.icon(
              onPressed: onRemoveImage,
              icon: const Icon(Icons.delete_outline),
              label: const Text(
                'حذف الصورة',
                style: TextStyle(fontSize: 19),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image,
          size: 80,
          color: Colors.green,
        ),
        SizedBox(height: 12),
        Text(
          'أضف صورة واضحة للدواء',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TimeInputRow extends StatelessWidget {
  final TextEditingController hourController;
  final TextEditingController minuteController;
  final String period;
  final ValueChanged<String?> onPeriodChanged;
  final FormFieldValidator<String> validateHour;
  final FormFieldValidator<String> validateMinute;
  final Widget Function({
    required String value,
    required ValueChanged<String?> onChanged,
  }) buildPeriodDropdown;

  const _TimeInputRow({
    required this.hourController,
    required this.minuteController,
    required this.period,
    required this.onPeriodChanged,
    required this.validateHour,
    required this.validateMinute,
    required this.buildPeriodDropdown,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: hourController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الساعة',
                  hintText: '5',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 22),
                validator: validateHour,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: minuteController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الدقائق',
                  hintText: '36',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 22),
                validator: validateMinute,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        buildPeriodDropdown(
          value: period,
          onChanged: onPeriodChanged,
        ),
      ],
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