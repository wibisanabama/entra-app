import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/attendee_provider.dart';
import '../providers/auth_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attendeeProvider = Provider.of<AttendeeProvider>(context);

    final attendees = attendeeProvider.attendees;
    final total = attendeeProvider.totalCount;
    final checkedIn = attendeeProvider.checkedInCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Hadir Peserta'),
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
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHigh,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Attendance Count Badges
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Total: $total',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Hadir: $checkedIn',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Belum: ${total - checkedIn}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
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
                                return AttendeeTile(attendee: attendees[index]);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
