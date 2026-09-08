import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/attendee.dart';
import '../providers/attendee_provider.dart';
import '../providers/auth_provider.dart';
import '../services/gate_service.dart';
import '../widgets/attendee_tile.dart';

class AttendeeListScreen extends StatefulWidget {
  final String eventId;

  const AttendeeListScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<AttendeeListScreen> createState() => _AttendeeListScreenState();
}

class _AttendeeListScreenState extends State<AttendeeListScreen> {
  final _searchController = TextEditingController();
  String? _processingTicketCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendeeProvider = Provider.of<AttendeeProvider>(context, listen: false);

    if (authProvider.token != null) {
      await attendeeProvider.fetchAttendees(widget.eventId, authProvider.token!);
    }
  }

  Future<void> _performManualCheckIn(Attendee attendee) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendeeProvider = Provider.of<AttendeeProvider>(context, listen: false);

    if (authProvider.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi telah berakhir, silakan login kembali.')),
      );
      return;
    }

    // Show Confirmation Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE4E4E7)),
        ),
        title: const Row(
          children: [
            Icon(Icons.how_to_reg_rounded, color: Color(0xFF09090B)),
            SizedBox(width: 8),
            Text(
              'Konfirmasi Check-In',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF09090B)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Check-in manual untuk peserta:',
              style: TextStyle(color: Color(0xFF71717A), fontSize: 13),
            ),
            const SizedBox(height: 10),
            Text(
              attendee.userName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF09090B)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE4E4E7)),
              ),
              child: Text(
                'Kode: ${attendee.ticketCode}',
                style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF09090B), fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF71717A), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF09090B),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Check-In Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _processingTicketCode = attendee.ticketCode;
    });

    final result = await attendeeProvider.manualCheckIn(
      attendee,
      authProvider.token!,
      eventId: widget.eventId,
    );

    if (!mounted) return;

    setState(() {
      _processingTicketCode = null;
    });

    if (result.status == ScanStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF09090B),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Check-in berhasil untuk ${attendee.userName}!',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (result.status == ScanStatus.alreadyUsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF09090B),
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF09090B),
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _exportManifestSummary(AttendeeProvider attendeeProvider) {
    HapticFeedback.mediumImpact();
    final total = attendeeProvider.totalCount;
    final checkedIn = attendeeProvider.checkedInCount;
    final unchecked = attendeeProvider.uncheckedCount;
    final rate = total > 0 ? (checkedIn / total * 100).toStringAsFixed(1) : '0.0';

    final buffer = StringBuffer();
    buffer.writeln('=== MANIFEST KEHADIRAN EVENT ENTRA ===');
    buffer.writeln('Event ID: ${widget.eventId}');
    buffer.writeln('Total Peserta Terdaftar: $total');
    buffer.writeln('Sudah Masuk Gate: $checkedIn ($rate%)');
    buffer.writeln('Belum Masuk: $unchecked');
    buffer.writeln('Waktu Laporan: ${DateTime.now().toLocal()}');
    buffer.writeln('======================================');

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF09090B),
        content: Row(
          children: [
            Icon(Icons.copy_all_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Ringkasan manifest berhasil disalin ke clipboard!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendeeProvider = Provider.of<AttendeeProvider>(context);

    final attendees = attendeeProvider.attendees;
    final total = attendeeProvider.totalCount;
    final checkedIn = attendeeProvider.checkedInCount;
    final unchecked = attendeeProvider.uncheckedCount;
    final currentFilter = attendeeProvider.statusFilter;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Daftar Hadir Peserta',
          style: TextStyle(
            color: Color(0xFF09090B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF09090B)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Color(0xFF09090B)),
            tooltip: 'Salin Ringkasan Manifest',
            onPressed: () => _exportManifestSummary(attendeeProvider),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF09090B)),
            tooltip: 'Refresh Peserta',
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    attendeeProvider.setSearchQuery(val);
                  },
                  style: const TextStyle(
                    color: Color(0xFF09090B),
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari nama, email, atau kode tiket...',
                    hintStyle: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF71717A), size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF71717A)),
                            onPressed: () {
                              _searchController.clear();
                              attendeeProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF4F4F5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9999),
                      borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9999),
                      borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9999),
                      borderSide: const BorderSide(color: Color(0xFF09090B), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Interactive Attendance Filter Chips (Mobbin Pill Chips)
                Row(
                  children: [
                    // Total Chip
                    Expanded(
                      child: InkWell(
                        onTap: () => attendeeProvider.setStatusFilter(AttendeeStatusFilter.all),
                        borderRadius: BorderRadius.circular(9999),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          decoration: BoxDecoration(
                            color: currentFilter == AttendeeStatusFilter.all
                                ? const Color(0xFF09090B)
                                : const Color(0xFFF4F4F5),
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(
                              color: currentFilter == AttendeeStatusFilter.all
                                  ? Colors.transparent
                                  : const Color(0xFFE4E4E7),
                            ),
                          ),
                          child: Text(
                            'Semua ($total)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: currentFilter == AttendeeStatusFilter.all
                                  ? Colors.white
                                  : const Color(0xFF71717A),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Hadir Chip
                    Expanded(
                      child: InkWell(
                        onTap: () => attendeeProvider.setStatusFilter(AttendeeStatusFilter.checkedIn),
                        borderRadius: BorderRadius.circular(9999),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          decoration: BoxDecoration(
                            color: currentFilter == AttendeeStatusFilter.checkedIn
                                ? const Color(0xFF09090B)
                                : const Color(0xFFF4F4F5),
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(
                              color: currentFilter == AttendeeStatusFilter.checkedIn
                                  ? Colors.transparent
                                  : const Color(0xFFE4E4E7),
                            ),
                          ),
                          child: Text(
                            'Hadir ($checkedIn)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: currentFilter == AttendeeStatusFilter.checkedIn
                                  ? Colors.white
                                  : const Color(0xFF059669),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Belum Hadir Chip
                    Expanded(
                      child: InkWell(
                        onTap: () => attendeeProvider.setStatusFilter(AttendeeStatusFilter.unchecked),
                        borderRadius: BorderRadius.circular(9999),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          decoration: BoxDecoration(
                            color: currentFilter == AttendeeStatusFilter.unchecked
                                ? const Color(0xFF09090B)
                                : const Color(0xFFF4F4F5),
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(
                              color: currentFilter == AttendeeStatusFilter.unchecked
                                  ? Colors.transparent
                                  : const Color(0xFFE4E4E7),
                            ),
                          ),
                          child: Text(
                            'Belum ($unchecked)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: currentFilter == AttendeeStatusFilter.unchecked
                                  ? Colors.white
                                  : const Color(0xFFD97706),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List View Body
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF09090B),
              onRefresh: _loadData,
              child: attendeeProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF09090B)))
                  : attendeeProvider.errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                              const SizedBox(height: 12),
                              Text(
                                attendeeProvider.errorMessage!,
                                style: const TextStyle(color: Color(0xFF09090B)),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF09090B),
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                ),
                                child: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        )
                      : attendees.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 80),
                                const Icon(
                                  Icons.person_search_rounded,
                                  size: 64,
                                  color: Color(0xFFD4D4D8),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  attendeeProvider.searchQuery.isNotEmpty
                                      ? 'Tidak ada peserta yang cocok'
                                      : 'Belum Ada Peserta Terdaftar',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF09090B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Peserta yang membeli tiket akan otomatis tercatat di sini.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF71717A),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: attendees.length,
                              itemBuilder: (context, index) {
                                final attendee = attendees[index];
                                return AttendeeTile(
                                  attendee: attendee,
                                  isProcessing: _processingTicketCode == attendee.ticketCode,
                                  onCheckIn: () => _performManualCheckIn(attendee),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

