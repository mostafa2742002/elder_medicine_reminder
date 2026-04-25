import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class MedicineImageService {
  final ImagePicker _imagePicker = ImagePicker();

  Future<String?> pickAndSaveImage(ImageSource source) async {
    final pickedImage = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (pickedImage == null) {
      return null;
    }

    final sourceFile = File(pickedImage.path);

    final appDirectory = await getApplicationDocumentsDirectory();
    final imagesDirectory = Directory(
      '${appDirectory.path}/medicine_images',
    );

    if (!await imagesDirectory.exists()) {
      await imagesDirectory.create(recursive: true);
    }

    final extension = _extractExtension(pickedImage.path);

    final fileName =
        'medicine_${DateTime.now().microsecondsSinceEpoch}$extension';

    final savedImage = await sourceFile.copy(
      '${imagesDirectory.path}/$fileName',
    );

    return savedImage.path;
  }

  Future<void> deleteImageIfExists(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return;
    }

    final imageFile = File(imagePath);

    if (await imageFile.exists()) {
      await imageFile.delete();
    }
  }

  String _extractExtension(String path) {
    final lastDotIndex = path.lastIndexOf('.');

    if (lastDotIndex == -1 || lastDotIndex == path.length - 1) {
      return '.jpg';
    }

    final extension = path.substring(lastDotIndex).toLowerCase();

    if (extension.length > 6) {
      return '.jpg';
    }

    return extension;
  }
}