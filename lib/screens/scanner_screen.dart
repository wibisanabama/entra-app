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

  void _showManualInputDialog() {
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E4E7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Input Kode Tiket Manual',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF09090B)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Gunakan jika kamera mengalami kesulitan membaca QR code.',
              style: TextStyle(fontSize: 13, color: Color(0xFF71717A)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              autofocus: true,
              style: const TextStyle(color: Color(0xFF09090B), fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Masukkan Kode Tiket / UUID',
                hintStyle: const TextStyle(color: Color(0xFFA1A1AA)),
                filled: true,
                fillColor: const Color(0xFFF4F4F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF09090B), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final raw = textController.text.trim();
                  final code = QrNormalizer.normalize(raw);
                  if (code.isNotEmpty) {
                    Navigator.pop(ctx);
                    _processTicketScan(code);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF09090B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: const Text('Verifikasi Check-in', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
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

          // Bottom Actions (Input Kode Manual)
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: Center(
              child: SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: _showManualInputDialog,
                  icon: const Icon(Icons.keyboard_alt_outlined, color: Color(0xFF09090B), size: 16),
                  label: const Text(
                    'Input Kode Manual',
                    style: TextStyle(color: Color(0xFF09090B), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF09090B),
                    elevation: 0,
                    shape: const StadiumBorder(),
                    side: const BorderSide(color: Color(0xFFE4E4E7)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
