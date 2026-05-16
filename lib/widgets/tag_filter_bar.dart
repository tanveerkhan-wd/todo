import 'package:flutter/material.dart';

/// A horizontal scrollable row of multi-select tag filter chips.
///
/// Pass all available tags via [allTags] and the currently selected ones via
/// [selectedTags]. Returns the updated selection through [onSelectionChanged].
class TagFilterBar extends StatelessWidget {
  const TagFilterBar({
    super.key,
    required this.allTags,
    required this.selectedTags,
    required this.onSelectionChanged,
  });

  final List<String> allTags;
  final Set<String> selectedTags;
  final ValueChanged<Set<String>> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (allTags.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allTags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (ctx, i) {
          final tag = allTags[i];
          final isSelected = selectedTags.contains(tag);
          return FilterChip(
            label: Text(tag),
            selected: isSelected,
            onSelected: (selected) {
              final updated = Set<String>.from(selectedTags);
              if (selected) {
                updated.add(tag);
              } else {
                updated.remove(tag);
              }
              onSelectionChanged(updated);
            },
            visualDensity: VisualDensity.compact,
            selectedColor: colorScheme.primary.withValues(alpha: 0.2),
            checkmarkColor: colorScheme.primary,
            labelStyle: TextStyle(
              fontSize: 12,
              color: isSelected ? colorScheme.primary : null,
            ),
          );
        },
      ),
    );
  }
}
