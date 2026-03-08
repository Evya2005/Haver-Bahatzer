import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../models/dog_model.dart';

class DogTagsSelector extends StatelessWidget {
  final List<DogTag> selectedTags;
  final ValueChanged<List<DogTag>> onChanged;

  const DogTagsSelector({
    super.key,
    required this.selectedTags,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.tags, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: DogTag.values.map((tag) {
            final selected = selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag.hebrewLabel),
              selected: selected,
              onSelected: (value) {
                final updated = List<DogTag>.from(selectedTags);
                if (value) {
                  updated.add(tag);
                } else {
                  updated.remove(tag);
                }
                onChanged(updated);
              },
              avatar: selected ? null : null,
            );
          }).toList(),
        ),
      ],
    );
  }
}
