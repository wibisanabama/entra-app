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
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.door_sliding_rounded, color: Color(0xFF7C3AED)),
                  SizedBox(width: 8),
                  Text(
                    'Pilih Pos / Gate Masuk',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Tandai pintu tempat Anda bertugas untuk atribusi verifikasi tiket.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableGates.length,
                  itemBuilder: (ctx, index) {
                    final gate = _availableGates[index];
                    final isSelected = gate == _selectedGate;
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                        color: isSelected ? const Color(0xFF10B981) : Colors.grey,
                      ),
                      title: Text(
                        gate,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade300,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      tileColor: isSelected
                          ? const Color(0xFF7C3AED).withValues(alpha: 0.15)
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_rounded, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 8),
                      Text(
                        'Riwayat Scan Sesi Ini (${_recentScans.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _recentScans.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada tiket yang dipindai pada sesi ini.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: _recentScans.length,
                      separatorBuilder: (_, _) => const Divider(color: Colors.white12, height: 1),
                      itemBuilder: (ctx, index) {
                        final item = _recentScans[index];
                        final isSuccess = item.status == ScanStatus.success;
                        final isDuplicate = item.status == ScanStatus.alreadyUsed;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: isSuccess
                                ? Colors.green.withValues(alpha: 0.2)
                                : isDuplicate
                                    ? Colors.amber.withValues(alpha: 0.2)
                                    : Colors.red.withValues(alpha: 0.2),
                            child: Icon(
                              isSuccess
                                  ? Icons.check_circle_rounded
                                  : isDuplicate
                                      ? Icons.warning_amber_rounded
                                      : Icons.cancel_rounded,
                              color: isSuccess
                                  ? Colors.greenAccent
                                  : isDuplicate
                                      ? Colors.amberAccent
                                      : Colors.redAccent,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item.attendeeName ?? item.ticketCode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            '${item.gateName} • ${item.ticketType ?? 'Tiket'} • ${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}:${item.timestamp.second.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSuccess
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isSuccess ? 'VALID' : isDuplicate ? 'DUPLIKAT' : 'INVALID',
                              style: TextStyle(
                                color: isSuccess ? Colors.greenAccent : Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
      backgroundColor: const Color(0xFF111827),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Masukkan Kode Tiket / UUID',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1F2937),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final raw = textController.text.trim();
                final code = QrNormalizer.normalize(raw);
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

          // Live Gate Attendance Overlay Banner (Top)
          Positioned(
            top: 10,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF111827).withValues(alpha: 0.92),
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
                          Text(
                            'LIVE • $_selectedGate',
                            style: const TextStyle(
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
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _rapidResult != null
                      ? (_rapidResult!.status == ScanStatus.success
                          ? Colors.greenAccent
                          : _rapidResult!.status == ScanStatus.alreadyUsed
                              ? Colors.amberAccent
                              : Colors.redAccent)
                      : (_isProcessing ? Colors.amberAccent : const Color(0xFF7C3AED)),
                  width: 3.5,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          // RAPID SCAN FLASH POPUP BANNER (Center Overlay)
          if (rapid != null)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: rapid.status == ScanStatus.success
                      ? const Color(0xFF065F46).withValues(alpha: 0.95)
                      : rapid.status == ScanStatus.alreadyUsed
                          ? const Color(0xFF78350F).withValues(alpha: 0.95)
                          : const Color(0xFF7F1D1D).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      rapid.status == ScanStatus.success
                          ? Icons.check_circle_rounded
                          : rapid.status == ScanStatus.alreadyUsed
                              ? Icons.warning_amber_rounded
                              : Icons.cancel_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rapid.status == ScanStatus.success
                          ? 'CHECK-IN BERHASIL'
                          : rapid.status == ScanStatus.alreadyUsed
                              ? 'TIKET SUDAH DIGUNAKAN'
                              : 'TIKET TIDAK VALID',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (rapid.attendeeName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        rapid.attendeeName!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    if (rapid.ticketTypeName != null)
                      Text(
                        rapid.ticketTypeName!,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),

          // Instruction Banner (Bottom)
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                        Icon(
                          _rapidMode ? Icons.bolt_rounded : Icons.center_focus_strong_rounded,
                          color: _rapidMode ? Colors.amberAccent : Colors.white,
                          size: 18,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _isProcessing
                            ? 'Memverifikasi...'
                            : _rapidMode
                                ? 'Mode Kilat: Scan Berkelanjutan'
                                : 'Arahkan kamera ke QR Code tiket',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _showManualInputDialog,
                  icon: const Icon(Icons.keyboard_alt_outlined, color: Colors.white70, size: 18),
                  label: const Text(
                    'Input Kode Manual',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
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
