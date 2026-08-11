import 'package:flutter/material.dart';

import '../models/attendee.dart';

class AttendeeTile extends StatelessWidget {
  final Attendee attendee;

  const AttendeeTile({
    super.key,
    required this.attendee,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCheckedIn = attendee.isCheckedIn;

    final initial = attendee.userName.isNotEmpty
        ? attendee.userName[0].toUpperCase()
        : 'P';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.2),
            child: Text(
              initial,
              style: const TextStyle(
                color: Color(0xFF7C3AED),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendee.userName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (attendee.userEmail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    attendee.userEmail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Kode: ${attendee.ticketCode.length > 18 ? '${attendee.ticketCode.substring(0, 18)}...' : attendee.ticketCode}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.horizontal(10, vertical: 6),
            decoration: BoxDecoration(
              color: isCheckedIn
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCheckedIn ? Icons.check_circle : Icons.schedule,
                  size: 14,
                  color: isCheckedIn ? Colors.greenAccent : Colors.amberAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  isCheckedIn ? 'Hadir' : 'Belum',
                  style: TextStyle(
                    color: isCheckedIn ? Colors.greenAccent : Colors.amberAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
