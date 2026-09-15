import 'package:flutter/material.dart';
import 'neumorphic_container.dart';

class NeumorphicButton extends StatefulWidget {
  final Widget? child;
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final Color? textColor;
  final bool isPrimary;
  final double? width;
  final double? height;

  const NeumorphicButton({
    super.key,
    this.child,
    this.label,
    this.icon,
    this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
    this.margin,
    this.borderRadius = 14.0,
    this.color,
    this.textColor,
    this.isPrimary = false,
    this.width,
    this.height,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = true);
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.color ?? theme.colorScheme.primary;

    Color? effectiveColor;
    Color effectiveTextColor;

    if (widget.isPrimary) {
      effectiveColor = primaryColor;
      effectiveTextColor = theme.colorScheme.onPrimary;
    } else {
      effectiveColor = widget.color;
      effectiveTextColor = widget.textColor ?? theme.colorScheme.onSurface;
    }

    Widget content;
    if (widget.child != null) {
      content = widget.child!;
    } else {
      final List<Widget> children = [];
      if (widget.icon != null) {
        children.add(Icon(widget.icon, size: 18, color: effectiveTextColor));
        if (widget.label != null) {
          children.add(const SizedBox(width: 8));
        }
      }
      if (widget.label != null) {
        children.add(
          Text(
            widget.label!,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: effectiveTextColor,
            ),
          ),
        );
      }
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: widget.onPressed == null ? 0.5 : 1.0,
        child: NeumorphicContainer(
          style: _isPressed ? NeumorphicStyle.inset : NeumorphicStyle.raised,
          borderRadius: widget.borderRadius,
          padding: widget.padding,
          margin: widget.margin,
          width: widget.width,
          height: widget.height,
          color: effectiveColor,
          child: content,
        ),
      ),
    );
  }
}
