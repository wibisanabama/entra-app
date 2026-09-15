import 'dart:async';
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

          // Viewfinder Overlay Frame (Mobbin Rounded 28)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _rapidResult != null
                      ? (_rapidResult!.status == ScanStatus.success
                          ? const Color(0xFF10B981)
                          : _rapidResult!.status == ScanStatus.alreadyUsed
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFEF4444))
                      : (_isProcessing ? const Color(0xFFF59E0B) : Colors.white),
                  width: 3.5,
                ),
                borderRadius: BorderRadius.circular(28),
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
