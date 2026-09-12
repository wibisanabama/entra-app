import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/ticket_tier.dart';
import '../providers/attendee_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../services/event_service.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final EventService _eventService = EventService();
  List<TicketTier> _ticketTiers = [];
  bool _loadingTiers = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendeeProvider = Provider.of<AttendeeProvider>(context, listen: false);

    if (authProvider.token != null) {
      setState(() {
        _loadingTiers = true;
      });

      await Future.wait([
        attendeeProvider.fetchAttendees(widget.eventId, authProvider.token!),
        _loadTiers(authProvider.token!),
      ]);
    }
  }

  Future<void> _loadTiers(String token) async {
    final tiers = await _eventService.getEventTicketTiers(widget.eventId, token);
    if (mounted) {
      setState(() {
        _ticketTiers = tiers;
        _loadingTiers = false;
      });
    }
  }

  String _formatCurrency(num amount) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final attendeeProvider = Provider.of<AttendeeProvider>(context);

    final event = eventProvider.getEventById(widget.eventId);

    if (event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Event')),
        body: const Center(
          child: Text('Event tidak ditemukan'),
        ),
      );
    }

    final totalAttendees = attendeeProvider.totalCount;
    final checkedIn = attendeeProvider.checkedInCount;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detail Event'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Banner / Header Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: event.isPublished ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        event.status.toUpperCase(),
                        style: TextStyle(
                          color: event.isPublished ? const Color(0xFF059669) : const Color(0xFFD97706),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF09090B),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFFA1A1AA)),
                        const SizedBox(width: 6),
                        Text(
                          event.startDate.isNotEmpty ? event.startDate.split('T').first : '-',
                          style: const TextStyle(color: Color(0xFF71717A), fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons Section
              const Text(
                'Aksi Lapangan',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF09090B),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 12),

              // Scan QR Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push('/events/${event.id}/scan');
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
                  label: const Text(
                    'Scan QR Tiket Peserta',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF09090B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // View Attendee List Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push('/events/${event.id}/attendees');
                  },
                  icon: const Icon(Icons.people_alt_outlined, size: 20, color: Color(0xFF09090B)),
                  label: const Text(
                    'Daftar Hadir Peserta',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF09090B)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4F4F5),
                    foregroundColor: const Color(0xFF09090B),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Live Check-in Stats
              const Text(
                'Statistik Kehadiran Gate',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF09090B),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '$totalAttendees',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            color: Color(0xFF09090B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Total Terdaftar',
                          style: TextStyle(
                            color: Color(0xFF71717A),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '$checkedIn',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            color: Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sudah Check-in',
                          style: TextStyle(
                            color: Color(0xFF71717A),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '${totalAttendees - checkedIn}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Belum Hadir',
                          style: TextStyle(
                            color: Color(0xFF71717A),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Rincian Kategori & Kuota Tiket
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Rincian Kategori & Kuota Tiket',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF09090B),
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (_loadingTiers)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF09090B)),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_ticketTiers.length} Kategori',
                        style: const TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (_loadingTiers)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Memuat rincian tiket...', style: TextStyle(color: Color(0xFF71717A), fontSize: 13)),
                )
              else if (_ticketTiers.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'Belum ada kategori tiket untuk event ini.',
                      style: TextStyle(color: Color(0xFF71717A), fontSize: 13),
                    ),
                  ),
                )
              else
                Column(
                  children: _ticketTiers.map((tier) {
                    final isSoldOut = tier.isSoldOut;
                    final fillRate = tier.fillRate;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tier.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF09090B),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSoldOut
                                      ? const Color(0xFFFEF2F2)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  isSoldOut ? 'SOLD OUT' : _formatCurrency(tier.price),
                                  style: TextStyle(
                                    color: isSoldOut ? const Color(0xFFDC2626) : const Color(0xFF09090B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Kapasitas Kuota: ${tier.capacity} tiket',
                                style: const TextStyle(color: Color(0xFF71717A), fontSize: 12),
                              ),
                              Text(
                                tier.price > 0
                                    ? 'Harga: ${_formatCurrency(tier.price)}'
                                    : 'Gratis',
                                style: const TextStyle(color: Color(0xFF09090B), fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          if (tier.description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              tier.description,
                              style: const TextStyle(color: Color(0xFF71717A), fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: fillRate > 0 ? fillRate : 0.05,
                              backgroundColor: Colors.white,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isSoldOut ? const Color(0xFFDC2626) : const Color(0xFF09090B),
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 24),

              // Description Section
              if (event.description.isNotEmpty) ...[
                const Text(
                  'Deskripsi Event',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF09090B),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.description,
                  style: const TextStyle(
                    color: Color(0xFF71717A),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
