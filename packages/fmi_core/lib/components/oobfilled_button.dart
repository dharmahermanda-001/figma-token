// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import '../design_tokens/mds_tokens.dart';

class OOBFilledButton extends StatelessWidget {
  final ButtonStyle? style;
  final Widget child;
  final Icon? icon;
  final bool iconVisible;
  final VoidCallback onPressed;

  const OOBFilledButton({
    this.style,
    required this.child,
    this.icon,
    this.iconVisible = false,
    required this.onPressed,
    super.key,
  });

  factory OOBFilledButton.variant({
    required String variant,
    required VoidCallback onPressed,
    Widget? child,
    Icon? icon,
    ButtonStyle? style,
    bool? iconVisible,
  }) {
    late ButtonStyle defaultStyle;
    late Widget defaultChild;
    late Icon? defaultIcon;
    late bool defaultIconVisible;

    switch(variant) {
      case 'default':
        defaultStyle = ElevatedButton.styleFrom(
          backgroundColor: MdsTokens.color2.primary,
          padding: EdgeInsets.all(MdsTokens.pad2.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MdsTokens.radius2.sm),
          ),
        );
        defaultChild = Text('Label');
        defaultIcon = null;
        defaultIconVisible = false;
        break;
      case 'secondary':
        defaultStyle = ElevatedButton.styleFrom(
          backgroundColor: MdsTokens.color2.primary,
          padding: EdgeInsets.all(MdsTokens.pad2.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MdsTokens.radius2.sm),
          ),
        );
        defaultChild = Text('Label');
        defaultIcon = null;
        defaultIconVisible = false;
        break;
      default:
        throw Exception('Unknown variant $variant');
    }
    return OOBFilledButton(
      style: style ?? defaultStyle,
      child: child ?? defaultChild,
      icon: icon ?? defaultIcon,
      iconVisible: iconVisible ?? defaultIconVisible,
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon ?? SizedBox.shrink(),
      label: child,
      style: style ?? ElevatedButton.styleFrom(),
    );
  }
}

