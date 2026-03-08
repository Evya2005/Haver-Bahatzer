import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/kennel_constants.dart';

class KennelSelector extends StatelessWidget {
  final String? selectedKennelId;
  final ValueChanged<String?> onChanged;

  const KennelSelector({
    super.key,
    required this.selectedKennelId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedKennelId,
      decoration: const InputDecoration(labelText: AppStrings.kennel),
      isExpanded: true,
      items: KennelConstants.all.map((k) {
        return DropdownMenuItem<String>(
          value: k.id,
          child: Text(k.hebrewName),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (v) =>
          v == null || v.isEmpty ? AppStrings.fieldRequired : null,
    );
  }
}
