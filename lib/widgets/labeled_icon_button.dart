import 'package:flutter/material.dart';

/// An [IconButton] wrapped in [Semantics] with a human-readable label.
///
/// Always provide [tooltip] for accessibility; [semanticLabel] defaults to
/// [tooltip] when not specified.
class LabeledIconButton extends StatelessWidget {
  const LabeledIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.semanticLabel,
    this.size = 20,
    this.style,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final double size;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? tooltip,
      button: true,
      enabled: onPressed != null,
      child: IconButton(
        icon: icon,
        tooltip: tooltip,
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        style: style,
        constraints: BoxConstraints(
          minWidth: size + 16,
          minHeight: size + 16,
        ),
      ),
    );
  }
}
