import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../providers/withdrawal_provider.dart';
import '../widgets/entra_logo.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final withdrawalProvider = Provider.of<WithdrawalProvider>(context, listen: false);

    if (authProvider.token != null) {
      await Future.wait([
        eventProvider.fetchDashboardData(authProvider.token!),
        withdrawalProvider.fetchBalanceAndWithdrawals(authProvider.token!),
      ]);
    }
  }

  String _formatCurrency(dynamic amount) {
    num val = 0;
    if (amount is num) val = amount;
    if (amount is String) val = num.tryParse(amount) ?? 0;
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(val);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final eventProvider = Provider.of<EventProvider>(context);
    final withdrawalProvider = Provider.of<WithdrawalProvider>(context);

    final stats = eventProvider.stats;
    final allEvents = eventProvider.events;
    final balance = withdrawalProvider.balance;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            const EntraLogo(size: 26),
            const SizedBox(width: 10),
            const Text(
              'Entra',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Color(0xFF09090B), size: 22),
            tooltip: 'Profil',
            onPressed: () => context.push('/profile'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Greeting
              Text(
                'Halo, ${authProvider.user?.name ?? "Organizer"}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ringkasan event dan tiket terjual Anda',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              // Saldo Tersedia Card (Main Highlight)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saldo Tersedia',
                      style: TextStyle(
                        color: Color(0xFF71717A),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatCurrency(balance.availableBalance),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF09090B),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stats Section
              StatCard(
                title: 'Total Pendapatan',
                value: _formatCurrency(stats['total_revenue']),
                icon: Icons.payments_rounded,
                iconColor: Colors.greenAccent,
              ),
              const SizedBox(height: 8),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Tiket Terjual',
                        value: '${stats['tickets_sold'] ?? 0}',
                        icon: Icons.confirmation_number_rounded,
                        iconColor: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        title: 'Event Aktif',
                        value: '${allEvents.where((e) => e.status.toUpperCase() == 'PUBLISHED').length}',
                        icon: Icons.event_rounded,
                        iconColor: const Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
