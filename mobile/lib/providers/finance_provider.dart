import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/category_repository.dart';
import '../services/transaction_repository.dart';

class FinanceProvider extends ChangeNotifier {
  final ApiService api;
  late final CategoryRepository categoryRepo = CategoryRepository(api);
  late final TransactionRepository transactionRepo = TransactionRepository(api);

  FinanceProvider(this.api);

  List<Category> categories = [];
  List<Transaction> transactions = [];
  bool loading = false;
  String? error;

  Future<void> loadCategories({String? type}) async {
    loading = true;
    notifyListeners();
    try {
      categories = await categoryRepo.list(type: type);
      error = null;
    } catch (e) {
      error = 'Could not load categories.';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> loadTransactions({String? type, String? q}) async {
    loading = true;
    notifyListeners();
    try {
      transactions = await transactionRepo.list(type: type, q: q);
      error = null;
    } catch (e) {
      error = 'Could not load transactions.';
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> addTransaction({
    required int categoryId,
    required String type,
    required double amount,
    String? note,
    required DateTime date,
  }) async {
    try {
      await transactionRepo.create(categoryId: categoryId, type: type, amount: amount, note: note, date: date);
      await loadTransactions();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      await transactionRepo.delete(id);
      transactions.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      error = 'Could not delete transaction.';
      notifyListeners();
      return false;
    }
  }
}
