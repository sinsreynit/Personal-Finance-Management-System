import '../models/transaction.dart';
import 'api_service.dart';

class TransactionRepository {
  final ApiService api;
  TransactionRepository(this.api);

  Future<List<Transaction>> list({String? type, String? q}) async {
    final path = (q != null && q.isNotEmpty) ? '/transactions/search' : '/transactions';
    final res = await api.get(path, query: {'type': type, 'q': q});
    final data = res['data'] as List;
    return data.map((e) => Transaction.fromJson(e)).toList();
  }

  // US-007 Add Income / US-010 Add Expense
  Future<Transaction> create({
    required int categoryId,
    required String type,
    required double amount,
    String? note,
    required DateTime date,
  }) async {
    final res = await api.post('/transactions', {
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'note': note,
      'transaction_date': date.toIso8601String().split('T').first,
    });
    return Transaction.fromJson(res);
  }

  Future<Transaction> update(int id, {
    required int categoryId,
    required String type,
    required double amount,
    String? note,
    required DateTime date,
  }) async {
    final res = await api.put('/transactions/$id', {
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'note': note,
      'transaction_date': date.toIso8601String().split('T').first,
    });
    return Transaction.fromJson(res);
  }

  Future<void> delete(int id) => api.delete('/transactions/$id');
}
