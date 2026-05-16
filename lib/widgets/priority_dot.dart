import 'package:flutter/material.dart';

import '../models/todo.dart';

/// A small colored dot that visually conveys a task's [Priority].
class PriorityDot extends StatelessWidget {
  const PriorityDot({super.key, required this.priority});

  final Priority priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (priority) {
          Priority.high => Colors.redAccent,
          Priority.medium => Colors.orangeAccent,
          Priority.low => Colors.grey,
        },
      ),
    );
  }
}
