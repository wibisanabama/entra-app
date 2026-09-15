import 'package:flutter/material.dart';
import '../config/api_config.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double size;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.name,
    this.size = 36,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = ApiConfig.resolveMediaUrl(avatarUrl);
    final initial = name.trim().isNotEmpty ? name.trim().substring(0, 1).toUpperCase() : 'O';

    Widget avatarContent;
    if (resolvedUrl.isNotEmpty) {
      avatarContent = Image.network(
        resolvedUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallback(initial),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildFallback(initial);
        },
      );
    } else {
      avatarContent = _buildFallback(initial);
    }

    Widget avatarWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? const Color(0xFFF4F4F5),
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarContent,
    );

    if (onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  Widget _buildFallback(String initial) {
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF09090B),
        ),
      ),
    );
  }
}
