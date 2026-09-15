import 'package:flutter/material.dart';

import '../services/gate_service.dart';

class ScanResultDialog extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onDismiss;

  const ScanResultDialog({
    super.key,
    required this.result,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = result.status == ScanStatus.success;
    final isAlreadyUsed = result.status == ScanStatus.alreadyUsed;

    final IconData icon = isSuccess
        ? Icons.check_circle_rounded
        : (isAlreadyUsed ? Icons.warning_amber_rounded : Icons.cancel_rounded);

    final Color statusColor = isSuccess
        ? const Color(0xFF059669) // green-600
        : (isAlreadyUsed ? const Color(0xFFD97706) : const Color(0xFFDC2626)); // amber-600 / red-600

    final Color statusBg = isSuccess
        ? const Color(0xFFECFDF5) // green-50
        : (isAlreadyUsed ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2)); // amber-50 / red-50

    final String title = isSuccess
        ? 'CHECK-IN BERHASIL'
        : (isAlreadyUsed ? 'TIKET SUDAH DIGUNAKAN' : 'TIKET TIDAK VALID');

    return AlertDialog(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: statusBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: statusColor,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            result.message,
            style: const TextStyle(
              color: Color(0xFF71717A),
              fontSize: 13,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: const Color(0xFFE4E4E7)),
            ),
            child: Text(
              result.ticketCode,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFF09090B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDismiss();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF09090B),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Scan Tiket Lain',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
