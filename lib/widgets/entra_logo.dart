import 'package:flutter/material.dart';

class EntraLogo extends StatelessWidget {
  const EntraLogo({
    super.key,
    this.size = 64,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/black-logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
