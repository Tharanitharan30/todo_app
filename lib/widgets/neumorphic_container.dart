import 'package:flutter/material.dart';
import '../theme.dart';

enum NeumorphicStyle { raised, inset, flat }

class NeumorphicContainer extends StatelessWidget {
  final Widget? child;
  final NeumorphicStyle style;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double distance;
  final double blur;

  const NeumorphicContainer({
    super.key,
    this.child,
    this.style = NeumorphicStyle.raised,
    this.borderRadius = 16.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.color,
    this.borderColor,
    this.onTap,
    this.distance = 4.0,
    this.blur = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        color ??
        (isDark ? NeumorphicColors.darkSurface : NeumorphicColors.lightSurface);

    final darkShadowColor = isDark
        ? NeumorphicColors.darkDarkShadow.withValues(alpha: 0.8)
        : NeumorphicColors.lightDarkShadow.withValues(alpha: 0.55);

    final lightHighlightColor = isDark
        ? NeumorphicColors.darkLightHighlight.withValues(alpha: 0.5)
        : NeumorphicColors.lightLightHighlight.withValues(alpha: 0.95);

    List<BoxShadow> boxShadows = [];
    Gradient? gradient;
    Border? border;

    if (style == NeumorphicStyle.raised) {
      boxShadows = [
        BoxShadow(
          color: darkShadowColor,
          offset: Offset(distance, distance),
          blurRadius: blur,
        ),
        BoxShadow(
          color: lightHighlightColor,
          offset: Offset(-distance, -distance),
          blurRadius: blur,
        ),
      ];
      border = Border.all(
        color:
            borderColor ??
            (isDark ? const Color(0xFF262B34) : const Color(0xFFD6DEE7)),
        width: 0.5,
      );
    } else if (style == NeumorphicStyle.inset) {
      // Inset style: Darker top/left inner shadow gradient effect
      final darkInset = isDark
          ? NeumorphicColors.darkDarkShadow.withValues(alpha: 0.7)
          : NeumorphicColors.lightDarkShadow.withValues(alpha: 0.4);
      final lightInset = isDark
          ? NeumorphicColors.darkLightHighlight.withValues(alpha: 0.3)
          : NeumorphicColors.lightLightHighlight.withValues(alpha: 0.7);

      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [darkInset, baseColor, lightInset],
        stops: const [0.0, 0.4, 1.0],
      );

      border = Border.all(
        color:
            borderColor ??
            (isDark ? const Color(0xFF181B20) : const Color(0xFFCCD5E1)),
        width: 0.8,
      );
    } else {
      // Flat style
      border = Border.all(
        color:
            borderColor ??
            (isDark ? const Color(0xFF262B34) : const Color(0xFFD6DEE7)),
        width: 0.8,
      );
    }

    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? baseColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadows,
        border: border,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
