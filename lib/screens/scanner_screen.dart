import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/gate_stats.dart';
import '../providers/auth_provider.dart';
import '../services/gate_service.dart';
import '../widgets/scan_result_dialog.dart';

class ScannerScreen extends StatefulWidget {
  final String eventId;

  const ScannerScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final GateService _gateService = GateService();
  bool _isProcessing = false;
  bool _torchEnabled = false;
  GateStats? _gateStats;
  bool _statsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGateStats();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadGateStats() async {
    if (!mounted) return;
    setState(() {
      _statsLoading = true;
    });

    final stats = await _gateService.getGateStats(widget.eventId);
    if (mounted) {
      setState(() {
        _gateStats = stats;
        _statsLoading = false;
      });
    }
  }

  void _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() {
      _torchEnabled = !_torchEnabled;
    });
  }

  void _switchCamera() async {
    await _controller.switchCamera();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawCode = barcodes.first.rawValue;
    if (rawCode == null || rawCode.trim().isEmpty) return;

    _processTicketScan(rawCode.trim());
  }

  Future<void> _processTicketScan(String ticketCode) async {
    setState(() {
      _isProcessing = true;
    });

    _controller.stop();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token ?? '';

    final ScanResult result = await _gateService.scanTicket(
      ticketCode,
      token,
      eventId: widget.eventId,
    );

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => ScanResultDialog(
          result: result,
          onDismiss: () {
            setState(() {
              _isProcessing = false;
            });
            _controller.start();
            if (result.status == ScanStatus.success) {
              _loadGateStats();
            }
          },
        ),
      );
    }
  }

  void _showManualInputDialog() {
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Input Kode Tiket Manual',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gunakan jika kamera mengalami kesulitan membaca QR code.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Masukkan UUID Tiket',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final code = textController.text.trim();
                if (code.isNotEmpty) {
                  Navigator.pop(ctx);
                  _processTicketScan(code);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Verifikasi Check-in', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _gateStats;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Scan QR Tiket', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _toggleTorch,
            icon: Icon(
              _torchEnabled ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _torchEnabled ? Colors.amberAccent : Colors.white,
            ),
            tooltip: 'Senter Kamera',
          ),
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
            tooltip: 'Ganti Kamera',
          ),
          IconButton(
            onPressed: _loadGateStats,
            icon: Icon(
              Icons.refresh_rounded,
              color: _statsLoading ? Colors.amberAccent : Colors.white70,
            ),
            tooltip: 'Segarkan Statistik',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Live Gate Attendance Overlay Banner (Top)
          Positioned(
            top: 16,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF111827).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'LIVE GATE IN',
                            style: TextStyle(
                              color: Color(0xFF7C3AED),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      if (stats != null)
                        Text(
                          '${stats.checkinRate.toStringAsFixed(1)}% Hadir',
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        const Text(
                          'Memuat...',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stats != null ? '${stats.checkedIn} / ${stats.totalTickets}' : '- / -',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const Text(
                            'Total Sudah Check-In',
                            style: TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            stats != null ? '${stats.remaining}' : '-',
                            style: const TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const Text(
                            'Sisa Belum Masuk',
                            style: TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (stats != null && stats.totalTickets > 0) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (stats.checkedIn / stats.totalTickets).clamp(0.0, 1.0),
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Viewfinder Overlay Frame
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isProcessing ? Colors.amberAccent : const Color(0xFF7C3AED),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          // Instruction Banner (Bottom)
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isProcessing)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amberAccent),
                        )
                      else
                        const Icon(Icons.center_focus_strong_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _isProcessing ? 'Memverifikasi...' : 'Arahkan kamera ke QR Code tiket',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _showManualInputDialog,
                  icon: const Icon(Icons.keyboard_alt_outlined, color: Colors.white70),
                  label: const Text(
                    'Input Kode Manual',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
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
