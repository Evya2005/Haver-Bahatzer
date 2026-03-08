import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/dog_model.dart';

class DogTagChip extends StatelessWidget {
  final DogTag tag;
  final bool small;

  const DogTagChip({super.key, required this.tag, this.small = false});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _tagColors(tag);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tag.hebrewLabel,
        style: TextStyle(
          color: fg,
          fontSize: small ? 11 : 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, Color) _tagColors(DogTag tag) {
    switch (tag) {
      case DogTag.aggressive:
        return (AppColors.tagAggressive, AppColors.tagAggressiveText);
      case DogTag.medication:
        return (AppColors.tagMedication, AppColors.tagMedicationText);
      case DogTag.escapist:
        return (AppColors.tagEscapist, AppColors.tagEscapistText);
    }
  }
}
