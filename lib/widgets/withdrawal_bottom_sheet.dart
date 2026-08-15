import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/withdrawal_provider.dart';

class WithdrawalBottomSheet extends StatefulWidget {
  final double availableBalance;

  const WithdrawalBottomSheet({
    super.key,
    required this.availableBalance,
  });

  static Future<bool?> show(BuildContext context, double availableBalance) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111827), // gray-900
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: WithdrawalBottomSheet(availableBalance: availableBalance),
      ),
    );
  }

  @override
  State<WithdrawalBottomSheet> createState() => _WithdrawalBottomSheetState();
}

class _WithdrawalBottomSheetState extends State<WithdrawalBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedBank = 'Bank Central Asia (BCA)';

  final List<String> _banks = [
    'Bank Central Asia (BCA)',
    'Bank Mandiri',
    'Bank Negara Indonesia (BNI)',
    'Bank Rakyat Indonesia (BRI)',
    'Bank Syariah Indonesia (BSI)',
    'CIMB Niaga',
    'Bank Permata',
    'SeaBank Indonesia',
    'Bank Jago',
    'Jenius / BTPN',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  void _setAmountPercentage(double percentage) {
    final amount = (widget.availableBalance * percentage).floorToDouble();
    _amountController.text = amount.toStringAsFixed(0);
  }

  void _setFixedAmount(double amount) {
    _amountController.text = amount.toStringAsFixed(0);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final withdrawalProvider = Provider.of<WithdrawalProvider>(context, listen: false);

    if (authProvider.token == null) return;

    final double amount = double.tryParse(_amountController.text.trim()) ?? 0;

    final success = await withdrawalProvider.requestWithdrawal(
      token: authProvider.token!,
      amount: amount,
      bankName: _selectedBank,
      accountNumber: _accountNumberController.text.trim(),
      accountName: _accountNameController.text.trim(),
      notes: _notesController.text.trim(),
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan penarikan dana berhasil dikirim!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(withdrawalProvider.errorMessage ?? 'Gagal mengajukan penarikan dana.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final withdrawalProvider = Provider.of<WithdrawalProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tarik Saldo Pendapatan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Available Balance Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saldo Tersedia',
                        style: TextStyle(color: Color(0xFFA78BFA), fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatCurrency(widget.availableBalance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Min. Rp 10.000',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Amount Input
            const Text(
              'Nominal Penarikan (Rp)',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                hintText: '0',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nominal penarikan wajib diisi';
                }
                final amount = double.tryParse(val.trim());
                if (amount == null || amount < 10000) {
                  return 'Minimal penarikan adalah Rp 10.000';
                }
                if (amount > widget.availableBalance) {
                  return 'Nominal melebihi saldo tersedia';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),

            // Quick Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    label: const Text('25%', style: TextStyle(fontSize: 11)),
                    backgroundColor: const Color(0xFF1F2937),
                    onPressed: () => _setAmountPercentage(0.25),
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    label: const Text('50%', style: TextStyle(fontSize: 11)),
                    backgroundColor: const Color(0xFF1F2937),
                    onPressed: () => _setAmountPercentage(0.50),
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    label: const Text('Tarik Semua (100%)', style: TextStyle(fontSize: 11, color: Color(0xFFA78BFA), fontWeight: FontWeight.bold)),
                    backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                    onPressed: () => _setAmountPercentage(1.0),
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    label: const Text('100rb', style: TextStyle(fontSize: 11)),
                    backgroundColor: const Color(0xFF1F2937),
                    onPressed: () => _setFixedAmount(100000),
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    label: const Text('500rb', style: TextStyle(fontSize: 11)),
                    backgroundColor: const Color(0xFF1F2937),
                    onPressed: () => _setFixedAmount(500000),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bank Selection Dropdown
            const Text(
              'Bank Tujuan',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF374151)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedBank,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1F2937),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  items: _banks.map((bank) {
                    return DropdownMenuItem<String>(
                      value: bank,
                      child: Text(bank),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedBank = val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Account Number
            const Text(
              'Nomor Rekening',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Contoh: 1234567890',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nomor rekening wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Account Name
            const Text(
              'Nama Pemilik Rekening',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _accountNameController,
              decoration: const InputDecoration(
                hintText: 'Sesuai dengan nama di buku tabungan',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nama pemilik rekening wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Notes
            const Text(
              'Catatan Penarikan (Opsional)',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Pencairan tiket batch 1',
              ),
            ),
            const SizedBox(height: 20),

            // Fee Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF030712),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Biaya Layanan Admin', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text('Gratis (Rp 0)', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: withdrawalProvider.isSubmitting ? null : _submit,
                child: withdrawalProvider.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Konfirmasi & Tarik Dana',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
