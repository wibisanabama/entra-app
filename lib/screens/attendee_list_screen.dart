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
        title: const Row(
          children: [
            Icon(Icons.how_to_reg_rounded, color: Color(0xFF7C3AED)),
            SizedBox(width: 8),
            Text('Konfirmasi Check-In'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Check-in manual untuk peserta:'),
            const SizedBox(height: 8),
            Text(
              attendee.userName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Kode: ${attendee.ticketCode}',
              style: const TextStyle(fontFamily: 'monospace', color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Check-In Sekarang'),
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
          backgroundColor: Colors.green.shade800,
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Check-in berhasil untuk ${attendee.userName}!'),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (result.status == ScanStatus.alreadyUsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.amber.shade900,
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(result.message)),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade900,
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(result.message)),
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
        backgroundColor: Color(0xFF7C3AED),
        content: Row(
          children: [
            Icon(Icons.copy_all_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Ringkasan manifest berhasil disalin ke clipboard!'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attendeeProvider = Provider.of<AttendeeProvider>(context);

    final attendees = attendeeProvider.attendees;
    final total = attendeeProvider.totalCount;
    final checkedIn = attendeeProvider.checkedInCount;
    final unchecked = attendeeProvider.uncheckedCount;
    final currentFilter = attendeeProvider.statusFilter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Hadir Peserta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Salin Ringkasan Manifest',
            onPressed: () => _exportManifestSummary(attendeeProvider),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Peserta',
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    attendeeProvider.setSearchQuery(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari nama, email, atau kode tiket...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              attendeeProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHigh,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Interactive Attendance Filter Chips
                Row(
                  children: [
                    // Total Chip
                    Expanded(
                      child: InkWell(
                        onTap: () => attendeeProvider.setStatusFilter(AttendeeStatusFilter.all),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          decoration: BoxDecoration(
                            color: currentFilter == AttendeeStatusFilter.all
                                ? const Color(0xFF7C3AED).withValues(alpha: 0.25)
                                : theme.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: currentFilter == AttendeeStatusFilter.all
                                  ? const Color(0xFF7C3AED)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            'Semua: $total',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: currentFilter == AttendeeStatusFilter.all
                                  ? const Color(0xFF7C3AED)
                                  : theme.colorScheme.onSurface,
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
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          decoration: BoxDecoration(
                            color: currentFilter == AttendeeStatusFilter.checkedIn
                                ? Colors.green.withValues(alpha: 0.25)
                                : theme.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: currentFilter == AttendeeStatusFilter.checkedIn
                                  ? Colors.greenAccent
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            'Hadir: $checkedIn',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.greenAccent,
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
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          decoration: BoxDecoration(
                            color: currentFilter == AttendeeStatusFilter.unchecked
                                ? Colors.amber.withValues(alpha: 0.25)
                                : theme.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: currentFilter == AttendeeStatusFilter.unchecked
                                  ? Colors.amberAccent
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            'Belum: $unchecked',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.amberAccent,
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
              onRefresh: _loadData,
              child: attendeeProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : attendeeProvider.errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                              const SizedBox(height: 12),
                              Text(attendeeProvider.errorMessage!),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadData,
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        )
                      : attendees.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 60),
                                Icon(
                                  Icons.person_search_rounded,
                                  size: 64,
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  attendeeProvider.searchQuery.isNotEmpty
                                      ? 'Tidak ada peserta yang cocok'
                                      : 'Belum Ada Peserta Terdaftar',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
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

