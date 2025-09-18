import 'bank_service.dart';

class BankController {
  final BankService _bankService = BankService();

  List<Bank> banks = []; // Use Bank directly instead of BankService.Bank
  bool isLoading = false;
  String? selectedBank;
  String? selectedBankCode;

  // Load banks from API
  Future<void> loadBanks() async {
    isLoading = true;

    try {
      final response = await BankService.fetchBanks();
      banks = response.data;
      isLoading = false;
    } catch (e) {
      isLoading = false;
      rethrow;
    }
  }

  // Select a bank
  void selectBank(String? bankName) {
    selectedBank = bankName;

    if (bankName != null) {
      final bank = banks.firstWhere(
            (b) => b.bankName == bankName,
        orElse: () => Bank(bankName: '', bankCode: ''), // Adjusted to use the Bank constructor directly
      );
      selectedBankCode = bank.bankCode;
    } else {
      selectedBankCode = null;
    }
  }

  // Clear selection
  void clearSelection() {
    selectedBank = null;
    selectedBankCode = null;
  }
}