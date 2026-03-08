import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/dog_provider.dart';

class DogMultiSelector extends StatelessWidget {
  final List<String> selectedDogIds;
  final ValueChanged<List<String>> onChanged;

  const DogMultiSelector({
    super.key,
    required this.selectedDogIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dogs = context.watch<DogProvider>().dogs;

    // Determine locked owner: once any dog is selected, only dogs from
    // the same owner are selectable.
    String? lockedOwnerPhone;
    for (final dog in dogs) {
      if (selectedDogIds.contains(dog.id)) {
        lockedOwnerPhone = dog.ownerPhone;
        break;
      }
    }

    return FormField<List<String>>(
      initialValue: selectedDogIds,
      validator: (v) =>
          (v == null || v.isEmpty) ? AppStrings.fieldRequired : null,
      builder: (state) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: AppStrings.selectDogs,
            errorText: state.errorText,
            border: const OutlineInputBorder(),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ...dogs.map((dog) {
                final isSelected = selectedDogIds.contains(dog.id);
                final isDisabled = lockedOwnerPhone != null &&
                    dog.ownerPhone != lockedOwnerPhone;
                return FilterChip(
                  label: Text(
                    dog.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                  onSelected: isDisabled
                      ? null
                      : (selected) {
                          final updated = List<String>.from(selectedDogIds);
                          if (selected) {
                            updated.add(dog.id);
                          } else {
                            updated.remove(dog.id);
                          }
                          onChanged(updated);
                          state.didChange(updated);
                        },
                );
              }),
              if (dogs.isEmpty)
                Text(
                  AppStrings.noDogs,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
            ],
          ),
        );
      },
    );
  }
}
