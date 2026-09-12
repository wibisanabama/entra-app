import 'package:flutter/material.dart';

class EntraLogo extends StatelessWidget {
  const EntraLogo({
    super.key,
    this.size = 64,
    this.backgroundColor = Colors.white,
    this.borderRadius,
    this.padding,
    this.withBorder = true,
  });

  final double size;
  final Color backgroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool withBorder;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(size * 0.22);
    final effectivePadding = padding ?? EdgeInsets.all(size * 0.16);

    return Container(
      width: size,
      height: size,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: effectiveRadius,
        border: withBorder
            ? Border.all(color: const Color(0xFFE4E4E7), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/black-logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
