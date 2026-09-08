import 'package:flutter/material.dart';

@immutable
class EntraTokens extends ThemeExtension<EntraTokens> {
  const EntraTokens({
    required this.ink,
    required this.muted,
    required this.canvas,
    required this.line,
    required this.success,
    required this.warning,
    required this.danger,
  });

  static const light = EntraTokens(
    ink: Color(0xFF09090B),
    muted: Color(0xFF71717A),
    canvas: Color(0xFFFAFAFA),
    line: Color(0xFFE4E4E7),
    success: Color(0xFF15803D),
    warning: Color(0xFFB45309),
    danger: Color(0xFFBE123C),
  );

  final Color ink;
  final Color muted;
  final Color canvas;
  final Color line;
  final Color success;
  final Color warning;
  final Color danger;

  @override
  EntraTokens copyWith({
    Color? ink,
    Color? muted,
    Color? canvas,
    Color? line,
    Color? success,
    Color? warning,
    Color? danger,
  }) {
    return EntraTokens(
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      canvas: canvas ?? this.canvas,
      line: line ?? this.line,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  EntraTokens lerp(covariant EntraTokens? other, double t) {
    if (other == null) return this;
    return EntraTokens(
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      line: Color.lerp(line, other.line, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}
