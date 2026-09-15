import 'package:flutter/material.dart';
import 'neumorphic_container.dart';

class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final NeumorphicStyle style;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double? width;
  final double? height;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.borderRadius = 16.0,
    this.style = NeumorphicStyle.raised,
    this.onTap,
    this.color,
    this.borderColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicContainer(
      style: style,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      onTap: onTap,
      color: color,
      borderColor: borderColor,
      width: width,
      height: height,
      child: child,
    );
  }
}
