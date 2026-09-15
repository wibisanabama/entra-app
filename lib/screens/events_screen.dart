import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../widgets/event_card.dart';
import '../widgets/user_avatar.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _selectedStatusFilter = 'ALL';
  double _previousBottomInset = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
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

  Future<void> _loadEvents() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final eventProvider = Provider.of<EventProvider>(context, listen: false);

    if (authProvider.token != null) {
      await eventProvider.fetchDashboardData(authProvider.token!);
    }
  }

  List<EventModel> _getFilteredEvents(List<EventModel> allEvents) {
    return allEvents.where((e) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          e.title.toLowerCase().contains(query) ||
          e.description.toLowerCase().contains(query);

      final matchesStatus = _selectedStatusFilter == 'ALL' ||
          e.status.toUpperCase() == _selectedStatusFilter.toUpperCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventProvider = Provider.of<EventProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final allEvents = eventProvider.events;
    final filteredEvents = _getFilteredEvents(allEvents);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Daftar Event',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: UserAvatar(
                avatarUrl: authProvider.user?.avatarUrl,
                name: authProvider.user?.name ?? '',
                size: 34,
                onTap: () => context.push('/profile'),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (_searchFocusNode.hasFocus) {
            _searchFocusNode.unfocus();
          }
        },
        child: RefreshIndicator(
          onRefresh: _loadEvents,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: const TextStyle(color: Color(0xFF09090B), fontSize: 13),
                  onTapOutside: (_) {
                    _searchFocusNode.unfocus();
                  },
                  onSubmitted: (_) {
                    _searchFocusNode.unfocus();
                  },
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                decoration: InputDecoration(
                  hintText: 'Cari judul, deskripsi, atau lokasi...',
                  hintStyle: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFFA1A1AA)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF71717A)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF4F4F5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
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
                  final tabWidth = innerWidth / 4;
                  final activeIndex = _getFilterIndex(_selectedStatusFilter);

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
                            _buildSegmentTab('ALL', 'Semua', allEvents.length),
                            _buildSegmentTab(
                              'PUBLISHED',
                              'Published',
                              allEvents.where((e) => e.status.toUpperCase() == 'PUBLISHED').length,
                            ),
                            _buildSegmentTab(
                              'DRAFT',
                              'Draft',
                              allEvents.where((e) => e.status.toUpperCase() == 'DRAFT').length,
                            ),
                            _buildSegmentTab(
                              'COMPLETED',
                              'Selesai',
                              allEvents.where((e) => e.status.toUpperCase() == 'COMPLETED').length,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Event Count Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Menampilkan Event',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF09090B),
                      letterSpacing: -0.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${filteredEvents.length} dari ${allEvents.length} Event',
                      style: const TextStyle(
                        color: Color(0xFF71717A),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Event List or Empty State
              if (eventProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (eventProvider.errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(eventProvider.errorMessage!),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadEvents,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (allEvents.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum Ada Event',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Buat event baru dari dashboard web entra-web',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (filteredEvents.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Column(
                      children: [
                        Icon(
                          Icons.filter_alt_off_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak Ada Event yang Cocok',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Coba ubah kata kunci pencarian atau ganti filter status',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _selectedStatusFilter = 'ALL';
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF09090B)),
                          label: const Text(
                            'Reset Filter',
                            style: TextStyle(
                              color: Color(0xFF09090B),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF4F4F5),
                            foregroundColor: const Color(0xFF09090B),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    return EventCard(
                      event: event,
                      onTap: () {
                        context.push('/events/${event.id}');
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  int _getFilterIndex(String filter) {
    switch (filter) {
      case 'PUBLISHED':
        return 1;
      case 'DRAFT':
        return 2;
      case 'COMPLETED':
        return 3;
      case 'ALL':
      default:
        return 0;
    }
  }

  Widget _buildSegmentTab(String filterKey, String label, int count) {
    final isSelected = _selectedStatusFilter == filterKey;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_selectedStatusFilter != filterKey) {
            setState(() {
              _selectedStatusFilter = filterKey;
            });
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
