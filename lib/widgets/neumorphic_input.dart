import 'package:flutter/material.dart';
import 'neumorphic_container.dart';

class NeumorphicInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final int? maxLines;
  final FocusNode? focusNode;
  final bool readOnly;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const NeumorphicInput({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.maxLines = 1,
    this.focusNode,
    this.readOnly = false,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
    this.borderRadius = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
            child: Text(
              labelText!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
        NeumorphicContainer(
          style: NeumorphicStyle.inset,
          borderRadius: borderRadius,
          padding: padding,
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            validator: validator,
            maxLines: maxLines,
            readOnly: readOnly,
            onTap: onTap,
            style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              filled: false,
              hintText: hintText,
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 14,
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      size: 20,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    )
                  : null,
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}
