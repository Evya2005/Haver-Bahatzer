import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/tag_provider.dart';

class DogTagsSelector extends StatelessWidget {
  final List<String> selectedTags; // tag IDs
  final ValueChanged<List<String>> onChanged;

  const DogTagsSelector({
    super.key,
    required this.selectedTags,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final allTags = context.watch<TagProvider>().tags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.tags, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: allTags.map((tag) {
            final selected = selectedTags.contains(tag.id);
            return FilterChip(
              label: Text(tag.label),
              selected: selected,
              onSelected: (value) {
                final updated = List<String>.from(selectedTags);
                if (value) {
                  updated.add(tag.id);
                } else {
                  updated.remove(tag.id);
                }
                onChanged(updated);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
