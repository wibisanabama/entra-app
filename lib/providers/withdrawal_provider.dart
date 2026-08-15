import 'package:flutter/material.dart';
import '../models/balance.dart';
import '../models/withdrawal.dart';
import '../services/withdrawal_service.dart';

class WithdrawalProvider extends ChangeNotifier {
  final WithdrawalService _withdrawalService = WithdrawalService();

  OrganizerBalance _balance = OrganizerBalance.empty();
  List<Withdrawal> _withdrawals = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  OrganizerBalance get balance => _balance;
  List<Withdrawal> get withdrawals => _withdrawals;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBalanceAndWithdrawals(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _withdrawalService.getOrganizerBalance(token),
        _withdrawalService.getOrganizerWithdrawals(token),
      ]);

      _balance = results[0] as OrganizerBalance;
      _withdrawals = results[1] as List<Withdrawal>;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
}
