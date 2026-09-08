import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/gate_stats.dart';
import '../providers/auth_provider.dart';
import '../services/gate_service.dart';
import '../utils/qr_normalizer.dart';
import '../widgets/scan_result_dialog.dart';

class RecentScanItem {
  final String ticketCode;
  final ScanStatus status;
  final String message;
  final String? attendeeName;
  final String? ticketType;
  final DateTime timestamp;
  final String gateName;

  RecentScanItem({
    required this.ticketCode,
    required this.status,
    required this.message,
    this.attendeeName,
    this.ticketType,
    required this.timestamp,
    required this.gateName,
  });
}

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
  bool _torchEnabled = false;
  GateStats? _gateStats;

  // Gate & Lane Selection
  String _selectedGate = 'Gate Utama';
  final List<String> _availableGates = [
    'Gate Utama',
    'Gate A (VIP)',
    'Gate B (Reguler)',
    'Pintu Barat',
    'Pintu Timur',
    'Gate Festival',
  ];

  // Rapid Scan Mode
  bool _rapidMode = true;
  ScanResult? _rapidResult;
  Timer? _rapidResetTimer;

  // Recent Scans History
  final List<RecentScanItem> _recentScans = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadGateStats();
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

  Future<void> _loadGateStats() async {
    if (!mounted) return;
    final stats = await _gateService.getGateStats(widget.eventId);
    if (mounted) {
      setState(() {
        _gateStats = stats;
      });
    }
  }

  void _toggleTorch() async {
    await _controller.toggleTorch();
    if (!mounted) return;
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

    // Add to Recent Scans
    final recentItem = RecentScanItem(
      ticketCode: ticketCode,
      status: result.status,
      message: result.message,
      attendeeName: result.attendeeName,
      ticketType: result.ticketTypeName,
      timestamp: DateTime.now(),
      gateName: _selectedGate,
    );

    if (mounted) {
      setState(() {
        _recentScans.insert(0, recentItem);
        if (_recentScans.length > 30) {
          _recentScans.removeLast();
        }
      });
    }

    if (!mounted) return;

    if (_rapidMode) {
      // Rapid Mode: Show floating flash banner without blocking modal dialog
      setState(() {
        _rapidResult = result;
      });

      if (result.status == ScanStatus.success) {
        _loadGateStats();
      }

      _rapidResetTimer?.cancel();
      _rapidResetTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) {
          setState(() {
            _rapidResult = null;
            _isProcessing = false;
          });
        }
      });
    } else {
      // Modal Dialog Mode: Stop camera and show dialog
      _controller.stop();
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

  void _showGateSelectorDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const Row(
                children: [
                  Icon(Icons.door_sliding_outlined, color: Color(0xFF09090B)),
                  SizedBox(width: 8),
                  Text(
                    'Pilih Pos / Gate Masuk',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF09090B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Tandai pintu tempat Anda bertugas untuk atribusi verifikasi tiket.',
                style: TextStyle(fontSize: 13, color: Color(0xFF71717A)),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _availableGates.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (ctx, index) {
                    final gate = _availableGates[index];
                    final isSelected = gate == _selectedGate;
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                        color: isSelected ? const Color(0xFF09090B) : const Color(0xFFA1A1AA),
                      ),
                      title: Text(
                        gate,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF09090B) : const Color(0xFF71717A),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      tileColor: isSelected
                          ? const Color(0xFFF4F4F5)
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFFE4E4E7) : Colors.transparent,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedGate = gate;
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gate diubah ke: $gate'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecentScansBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_rounded, color: Color(0xFF09090B)),
                      const SizedBox(width: 8),
                      Text(
                        'Riwayat Scan Sesi Ini',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF09090B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(color: const Color(0xFFE4E4E7)),
                        ),
                        child: Text(
                          '${_recentScans.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF09090B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Tutup', style: TextStyle(color: Color(0xFF09090B), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _recentScans.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada tiket yang dipindai pada sesi ini.',
                        style: TextStyle(color: Color(0xFF71717A), fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: _recentScans.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (ctx, index) {
                        final item = _recentScans[index];
                        final isSuccess = item.status == ScanStatus.success;
                        final isDuplicate = item.status == ScanStatus.alreadyUsed;

                        final statusBg = isSuccess
                            ? const Color(0xFFECFDF5)
                            : (isDuplicate ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2));
                        final statusText = isSuccess
                            ? const Color(0xFF059669)
                            : (isDuplicate ? const Color(0xFFD97706) : const Color(0xFFDC2626));
                        final statusBorder = isSuccess
                            ? const Color(0xFFA7F3D0)
                            : (isDuplicate ? const Color(0xFFFDE68A) : const Color(0xFFFECACA));

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE4E4E7)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isSuccess
                                      ? Icons.check_circle_rounded
                                      : isDuplicate
                                          ? Icons.warning_amber_rounded
                                          : Icons.cancel_rounded,
                                  color: statusText,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.attendeeName ?? item.ticketCode,
                                      style: const TextStyle(
                                        color: Color(0xFF09090B),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.gateName} • ${item.ticketType ?? 'Tiket'} • ${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}:${item.timestamp.second.toString().padLeft(2, '0')}',
                                      style: const TextStyle(color: Color(0xFF71717A), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(9999),
                                  border: Border.all(color: statusBorder),
                                ),
                                child: Text(
                                  isSuccess ? 'VALID' : isDuplicate ? 'DUPLIKAT' : 'INVALID',
                                  style: TextStyle(
                                    color: statusText,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
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
    final stats = _gateStats;
    final rapid = _rapidResult;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scan QR Tiket',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            InkWell(
              onTap: _showGateSelectorDialog,
              borderRadius: BorderRadius.circular(9999),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedGate,
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Color(0xFF10B981), size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Rapid Mode Toggle
          IconButton(
            onPressed: () {
              setState(() {
                _rapidMode = !_rapidMode;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _rapidMode ? 'Mode Kilat Aktif (Auto-Dismiss)' : 'Mode Dialog Interaktif Aktif',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            icon: Icon(
              _rapidMode ? Icons.bolt_rounded : Icons.splitscreen_rounded,
              color: _rapidMode ? Colors.amberAccent : Colors.white70,
            ),
            tooltip: _rapidMode ? 'Mode Kilat Aktif' : 'Mode Dialog',
          ),
          IconButton(
            onPressed: _showRecentScansBottomSheet,
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            tooltip: 'Riwayat Scan',
          ),
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
        ],
      ),
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Live Gate Attendance Overlay Banner (Top - Mobbin Floating Card)
          Positioned(
            top: 10,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFE4E4E7),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                          Text(
                            'LIVE • $_selectedGate',
                            style: const TextStyle(
                              color: Color(0xFF09090B),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      if (stats != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Text(
                            '${stats.checkinRate.toStringAsFixed(1)}% Hadir',
                            style: const TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        const Text(
                          'Memuat...',
                          style: TextStyle(color: Color(0xFF71717A), fontSize: 11),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
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
                              color: Color(0xFF09090B),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Total Sudah Check-In',
                            style: TextStyle(color: Color(0xFF71717A), fontSize: 11),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            stats != null ? '${stats.remaining}' : '-',
                            style: const TextStyle(
                              color: Color(0xFFD97706),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Sisa Belum Masuk',
                            style: TextStyle(color: Color(0xFF71717A), fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (stats != null && stats.totalTickets > 0) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9999),
                      child: LinearProgressIndicator(
                        value: (stats.checkedIn / stats.totalTickets).clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFFF4F4F5),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF09090B)),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
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

          // Instruction Banner (Bottom - Mobbin Pill Badges)
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: const Color(0xFFE4E4E7)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isProcessing)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF09090B)),
                        )
                      else
                        Icon(
                          _rapidMode ? Icons.bolt_rounded : Icons.center_focus_strong_rounded,
                          color: const Color(0xFF09090B),
                          size: 16,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _isProcessing
                            ? 'Memverifikasi...'
                            : _rapidMode
                                ? 'Mode Kilat: Scan Berkelanjutan'
                                : 'Arahkan kamera ke QR Code tiket',
                        style: const TextStyle(
                          color: Color(0xFF09090B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
