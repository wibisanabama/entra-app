import 'package:flutter/material.dart';
import '../models/balance.dart';
import '../models/withdrawal.dart';
import '../services/withdrawal_service.dart';

class WithdrawalProvider extends ChangeNotifier {
  final WithdrawalService _withdrawalService = WithdrawalService();
  bool _disposed = false;

  OrganizerBalance _balance = OrganizerBalance.empty();
  List<Withdrawal> _withdrawals = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  OrganizerBalance get balance => _balance;
  List<Withdrawal> get withdrawals => _withdrawals;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBalanceAndWithdrawals(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    bool balanceFailed = false;
    bool withdrawalsFailed = false;
    String? balanceError;
    String? withdrawalsError;

    final balanceFuture = _withdrawalService.getOrganizerBalance(token).then((data) {
      _balance = data;
    }).catchError((e) {
      balanceFailed = true;
      balanceError = e.toString().replaceAll('Exception: ', '');
    });

    final withdrawalsFuture = _withdrawalService.getOrganizerWithdrawals(token).then((data) {
      _withdrawals = data;
    }).catchError((e) {
      withdrawalsFailed = true;
      withdrawalsError = e.toString().replaceAll('Exception: ', '');
    });

    await Future.wait([balanceFuture, withdrawalsFuture]);

    if (balanceFailed && withdrawalsFailed) {
      _errorMessage = balanceError ?? withdrawalsError ?? 'Gagal memuat informasi keuangan.';
    } else {
      _errorMessage = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> requestWithdrawal({
    required String token,
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountName,
    String? notes,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _withdrawalService.requestWithdrawal(
        token: token,
        amount: amount,
        bankName: bankName,
        accountNumber: accountNumber,
        accountName: accountName,
        notes: notes,
      );

      // Refresh data
      await fetchBalanceAndWithdrawals(token);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearData() {
    _balance = OrganizerBalance.empty();
    _withdrawals = [];
    _isLoading = false;
    _isSubmitting = false;
    _errorMessage = null;
    notifyListeners();
  }
}
