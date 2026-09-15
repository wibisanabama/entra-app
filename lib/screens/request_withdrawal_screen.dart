import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/withdrawal_provider.dart';

class RequestWithdrawalScreen extends StatefulWidget {
  const RequestWithdrawalScreen({super.key});

  @override
  State<RequestWithdrawalScreen> createState() => _RequestWithdrawalScreenState();
}

class _RequestWithdrawalScreenState extends State<RequestWithdrawalScreen> {
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


  Future<void> _submit(double availableBalance) async {
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

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permintaan penarikan dana berhasil diajukan'),
          backgroundColor: Color(0xFF09090B),
          duration: Duration(seconds: 3),
        ),
      );
      context.pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(withdrawalProvider.errorMessage ?? 'Gagal mengajukan penarikan'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final withdrawalProvider = Provider.of<WithdrawalProvider>(context);
    final availableBalance = withdrawalProvider.balance.availableBalance;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF09090B)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Tarik Saldo Pendapatan',
          style: TextStyle(
            color: Color(0xFF09090B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Available Balance Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SALDO TERSEDIA',
                          style: TextStyle(
                            color: Color(0xFF71717A),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(availableBalance),
                          style: const TextStyle(
                            color: Color(0xFF09090B),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: const Text(
                        'Min. Rp 10rb',
                        style: TextStyle(
                          color: Color(0xFF71717A),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Amount Input
              const Text(
                'Nominal Penarikan (Rp)',
                style: TextStyle(
                  color: Color(0xFF09090B),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: Color(0xFF09090B),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: const TextStyle(
                    color: Color(0xFF09090B),
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: '0',
                  hintStyle: const TextStyle(color: Color(0xFFA1A1AA)),
                  filled: true,
                  fillColor: const Color(0xFFF4F4F5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nominal penarikan wajib diisi';
                  }
                  final amount = double.tryParse(val.trim());
                  if (amount == null || amount < 10000) {
                    return 'Minimal penarikan adalah Rp 10.000';
                  }
                  if (amount > availableBalance) {
                    return 'Nominal melebihi saldo tersedia';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),


              // Bank Selection Dropdown
              const Text(
                'Bank Tujuan',
                style: TextStyle(
                  color: Color(0xFF09090B),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedBank,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(
                      color: Color(0xFF09090B),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
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
              const SizedBox(height: 22),

              // Account Number
              const Text(
                'Nomor Rekening',
                style: TextStyle(
                  color: Color(0xFF09090B),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: Color(0xFF09090B),
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Contoh: 1234567890',
                  hintStyle: const TextStyle(color: Color(0xFFA1A1AA)),
                  filled: true,
                  fillColor: const Color(0xFFF4F4F5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nomor rekening wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),

              // Account Name
              const Text(
                'Nama Pemilik Rekening',
                style: TextStyle(
                  color: Color(0xFF09090B),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _accountNameController,
                style: const TextStyle(
                  color: Color(0xFF09090B),
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Sesuai dengan nama di buku tabungan',
                  hintStyle: const TextStyle(color: Color(0xFFA1A1AA)),
                  filled: true,
                  fillColor: const Color(0xFFF4F4F5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama pemilik rekening wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),

              // Notes
              const Text(
                'Catatan Penarikan (Opsional)',
                style: TextStyle(
                  color: Color(0xFF71717A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                style: const TextStyle(color: Color(0xFF09090B)),
                decoration: InputDecoration(
                  hintText: 'Contoh: Pencairan tiket batch 1',
                  hintStyle: const TextStyle(color: Color(0xFFA1A1AA)),
                  filled: true,
                  fillColor: const Color(0xFFF4F4F5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                ),
              ),
              const SizedBox(height: 24),

              // Fee Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Biaya Layanan Admin',
                      style: TextStyle(color: Color(0xFF71717A), fontSize: 13),
                    ),
                    Text(
                      'Gratis (Rp 0)',
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF09090B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: withdrawalProvider.isSubmitting
                      ? null
                      : () => _submit(availableBalance),
                  child: withdrawalProvider.isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Konfirmasi & Tarik Dana',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
