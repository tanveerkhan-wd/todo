import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A [SliverPersistentHeaderDelegate] that renders a pinned date-group label
/// with an optional item count.
class DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  DateHeaderDelegate(this.label, {this.count});

  final String label;
  final int? count;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 48,
      width: double.infinity,
      color: isDark ? AppTheme.surfaceDark : AppTheme.neutral,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: 'Section: $label',
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          if (count != null)
            Semantics(
              label: '$count items',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(DateHeaderDelegate oldDelegate) =>
      label != oldDelegate.label || count != oldDelegate.count;
}
