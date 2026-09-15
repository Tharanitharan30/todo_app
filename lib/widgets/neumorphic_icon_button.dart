import 'package:flutter/material.dart';
import 'neumorphic_container.dart';

class NeumorphicIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? iconColor;
  final String? tooltip;
  final bool isSelected;
  final double borderRadius;

  const NeumorphicIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 42.0,
    this.iconSize = 20.0,
    this.color,
    this.iconColor,
    this.tooltip,
    this.isSelected = false,
    this.borderRadius = 14.0,
  });

  @override
  State<NeumorphicIconButton> createState() => _NeumorphicIconButtonState();
}

class _NeumorphicIconButtonState extends State<NeumorphicIconButton> {
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
    final effectiveIconColor =
        widget.iconColor ??
        (widget.isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface);

    final style = (_isPressed || widget.isSelected)
        ? NeumorphicStyle.inset
        : NeumorphicStyle.raised;

    Widget button = GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: widget.onPressed == null ? 0.5 : 1.0,
        child: NeumorphicContainer(
          style: style,
          borderRadius: widget.borderRadius,
          width: widget.size,
          height: widget.size,
          color: widget.color,
          child: Center(
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: effectiveIconColor,
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}
