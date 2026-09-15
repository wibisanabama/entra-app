import 'package:flutter/material.dart';
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

class _AttendeeListScreenState extends State<AttendeeListScreen> with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String? _processingTicketCode;
  double _previousBottomInset = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!mounted) return;
    final bottomInset = View.of(context).viewInsets.bottom;
    if (_previousBottomInset > 0 && bottomInset == 0) {
      if (_searchFocusNode.hasFocus) {
        _searchFocusNode.unfocus();
      }
    }
    _previousBottomInset = bottomInset;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
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
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
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
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (_searchFocusNode.hasFocus) {
            _searchFocusNode.unfocus();
          }
        },
        child: Column(
          children: [
            // Search & Filter Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onTapOutside: (_) {
                      _searchFocusNode.unfocus();
                    },
                    onSubmitted: (_) {
                      _searchFocusNode.unfocus();
                    },
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
                                _searchFocusNode.unfocus();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF4F4F5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9999),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9999),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9999),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Status Filter Segmented Control (matches search bar width with sliding highlight)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final totalWidth = constraints.maxWidth;
                      final innerWidth = totalWidth - 8; // accounts for 4px padding on each side
                      final tabWidth = innerWidth / 3;
                      final activeIndex = _getFilterIndex(currentFilter);

                      return Container(
                        width: double.infinity,
                        height: 40,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xCCE4E4E7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Stack(
                          children: [
                            // Sliding highlight pill
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 250),
                              curve: const Cubic(0.16, 1.0, 0.3, 1.0),
                              left: activeIndex * tabWidth,
                              top: 0,
                              bottom: 0,
                              width: tabWidth,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                            // Tab labels row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildSegmentTab(
                                  label: 'Semua',
                                  count: total,
                                  filter: AttendeeStatusFilter.all,
                                  currentFilter: currentFilter,
                                  attendeeProvider: attendeeProvider,
                                ),
                                _buildSegmentTab(
                                  label: 'Hadir',
                                  count: checkedIn,
                                  filter: AttendeeStatusFilter.checkedIn,
                                  currentFilter: currentFilter,
                                  attendeeProvider: attendeeProvider,
                                ),
                                _buildSegmentTab(
                                  label: 'Belum',
                                  count: unchecked,
                                  filter: AttendeeStatusFilter.unchecked,
                                  currentFilter: currentFilter,
                                  attendeeProvider: attendeeProvider,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
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
                                    elevation: 0,
                                    shape: const StadiumBorder(),
                                  ),
                                  child: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          )
                        : attendees.isEmpty
                            ? ListView(
                                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
      ),
    );
  }

  int _getFilterIndex(AttendeeStatusFilter filter) {
    switch (filter) {
      case AttendeeStatusFilter.checkedIn:
        return 1;
      case AttendeeStatusFilter.unchecked:
        return 2;
      case AttendeeStatusFilter.all:
        return 0;
    }
  }

  Widget _buildSegmentTab({
    required String label,
    required int count,
    required AttendeeStatusFilter filter,
    required AttendeeStatusFilter currentFilter,
    required AttendeeProvider attendeeProvider,
  }) {
    final isSelected = currentFilter == filter;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_searchFocusNode.hasFocus) _searchFocusNode.unfocus();
          if (currentFilter != filter) {
            attendeeProvider.setStatusFilter(filter);
          }
        },
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isSelected ? const Color(0xFF09090B) : const Color(0xFF71717A),
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: -0.2,
            ),
            child: Text(
              '$label ($count)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

