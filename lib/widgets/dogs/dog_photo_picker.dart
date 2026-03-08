import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class DogPhotoPicker extends StatelessWidget {
  final File? imageFile;
  final String? existingPhotoUrl;
  final ValueChanged<File> onImageSelected;

  const DogPhotoPicker({
    super.key,
    this.imageFile,
    this.existingPhotoUrl,
    required this.onImageSelected,
  });

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 90);
    if (picked != null) {
      onImageSelected(File(picked.path));
    }
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text(AppStrings.photoFromCamera),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text(AppStrings.photoFromGallery),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(context, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageFile != null || existingPhotoUrl != null;

    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.chipBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: imageFile != null
                    ? Image.file(imageFile!, fit: BoxFit.cover)
                    : Image.network(existingPhotoUrl!, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 40, color: AppColors.primary),
                  const SizedBox(height: 8),
                  Text(AppStrings.addPhoto,
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}
