import 'package:flutter/material.dart';
import 'neumorphic_container.dart';

class NeumorphicProgress extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color? color;
  final Color? trackColor;
  final double borderRadius;

  const NeumorphicProgress({
    super.key,
    required this.progress,
    this.height = 12.0,
    this.color,
    this.trackColor,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clampedProgress = progress.clamp(0.0, 1.0);
    final activeColor = color ?? theme.colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final progressWidth = totalWidth * clampedProgress;

        return NeumorphicContainer(
          style: NeumorphicStyle.inset,
          borderRadius: borderRadius,
          height: height,
          width: totalWidth,
          color: trackColor,
          padding: EdgeInsets.zero,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: progressWidth,
              height: height,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
