import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/gate_service.dart';
import '../utils/qr_normalizer.dart';


class ScannerScreen extends StatefulWidget {
  final String eventId;

  const ScannerScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final GateService _gateService = GateService();
  bool _isProcessing = false;

  // Scan Result Banner
  ScanResult? _rapidResult;
  Timer? _rapidResetTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rapidResetTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.start();
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawCode = barcodes.first.rawValue;
    if (rawCode == null || rawCode.trim().isEmpty) return;

    final normalizedCode = QrNormalizer.normalize(rawCode);
    if (normalizedCode.isEmpty) return;

    _processTicketScan(normalizedCode);
  }

  Future<void> _processTicketScan(String ticketCode) async {
    setState(() {
      _isProcessing = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token ?? '';

    final ScanResult result = await _gateService.scanTicket(
      ticketCode,
      token,
      eventId: widget.eventId,
    );

    // Haptic Alert
    if (result.status == ScanStatus.success) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.vibrate();
    }

    if (!mounted) return;

    // Show floating result banner without blocking modal dialog
    setState(() {
      _rapidResult = result;
    });

    _rapidResetTimer?.cancel();
    _rapidResetTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _rapidResult = null;
          _isProcessing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rapid = _rapidResult;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        title: const Text(
          'Scan QR Tiket',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Viewfinder Rounded Corner Brackets
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: CustomPaint(
                painter: _ScannerCornerPainter(
                  color: _rapidResult != null
                      ? (_rapidResult!.status == ScanStatus.success
                          ? const Color(0xFF10B981)
                          : _rapidResult!.status == ScanStatus.alreadyUsed
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFEF4444))
                      : (_isProcessing ? const Color(0xFFF59E0B) : Colors.white),
                  strokeWidth: 5.0,
                  cornerLength: 64.0,
                  cornerRadius: 36.0,
                ),
              ),
            ),
          ),

          // RAPID SCAN FLASH POPUP BANNER (Mobbin Floating White Card)
          if (rapid != null)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: rapid.status == ScanStatus.success
                            ? const Color(0xFFECFDF5)
                            : rapid.status == ScanStatus.alreadyUsed
                                ? const Color(0xFFFFFBEB)
                                : const Color(0xFFFEF2F2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        rapid.status == ScanStatus.success
                            ? Icons.check_circle_rounded
                            : rapid.status == ScanStatus.alreadyUsed
                                ? Icons.warning_amber_rounded
                                : Icons.cancel_rounded,
                        color: rapid.status == ScanStatus.success
                            ? const Color(0xFF059669)
                            : rapid.status == ScanStatus.alreadyUsed
                                ? const Color(0xFFD97706)
                                : const Color(0xFFDC2626),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      rapid.status == ScanStatus.success
                          ? 'CHECK-IN BERHASIL'
                          : rapid.status == ScanStatus.alreadyUsed
                              ? 'TIKET SUDAH DIGUNAKAN'
                              : 'TIKET TIDAK VALID',
                      style: TextStyle(
                        color: rapid.status == ScanStatus.success
                            ? const Color(0xFF059669)
                            : rapid.status == ScanStatus.alreadyUsed
                                ? const Color(0xFFD97706)
                                : const Color(0xFFDC2626),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (rapid.attendeeName != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        rapid.attendeeName!,
                        style: const TextStyle(
                          color: Color(0xFF09090B),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    if (rapid.ticketTypeName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        rapid.ticketTypeName!,
                        style: const TextStyle(color: Color(0xFF71717A), fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScannerCornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double cornerRadius;

  const _ScannerCornerPainter({
    required this.color,
    this.strokeWidth = 5.0,
    this.cornerLength = 64.0,
    this.cornerRadius = 36.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final r = cornerRadius;
    final l = cornerLength;
    final half = strokeWidth / 2;

    final left = half;
    final top = half;
    final right = w - half;
    final bottom = h - half;

    // 1. Top-Left Corner
    final pathTL = Path()
      ..moveTo(left, top + l)
      ..lineTo(left, top + r)
      ..arcTo(Rect.fromLTWH(left, top, r * 2, r * 2), math.pi, math.pi / 2, false)
      ..lineTo(left + l, top);
    canvas.drawPath(pathTL, paint);

    // 2. Top-Right Corner
    final pathTR = Path()
      ..moveTo(right - l, top)
      ..lineTo(right - r, top)
      ..arcTo(Rect.fromLTWH(right - r * 2, top, r * 2, r * 2), 3 * math.pi / 2, math.pi / 2, false)
      ..lineTo(right, top + l);
    canvas.drawPath(pathTR, paint);

    // 3. Bottom-Right Corner
    final pathBR = Path()
      ..moveTo(right, bottom - l)
      ..lineTo(right, bottom - r)
      ..arcTo(Rect.fromLTWH(right - r * 2, bottom - r * 2, r * 2, r * 2), 0, math.pi / 2, false)
      ..lineTo(right - l, bottom);
    canvas.drawPath(pathBR, paint);

    // 4. Bottom-Left Corner
    final pathBL = Path()
      ..moveTo(left + l, bottom)
      ..lineTo(left + r, bottom)
      ..arcTo(Rect.fromLTWH(left, bottom - r * 2, r * 2, r * 2), math.pi / 2, math.pi / 2, false)
      ..lineTo(left, bottom - l);
    canvas.drawPath(pathBL, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerCornerPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.cornerLength != cornerLength ||
        oldDelegate.cornerRadius != cornerRadius;
  }
}
