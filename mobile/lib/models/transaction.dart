import 'category.dart';

class Transaction {
  final int id;
  final int categoryId;
  final Category? category;
  final String type; // income | expense
  final double amount;
  final String? note;
  final DateTime date;

  Transaction({
    required this.id,
    required this.categoryId,
    this.category,
    required this.type,
    required this.amount,
    this.note,
    required this.date,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        categoryId: json['category_id'],
        category: json['category'] != null ? Category.fromJson(json['category']) : null,
        type: json['type'],
        amount: double.parse(json['amount'].toString()),
        note: json['note'],
        date: DateTime.parse(json['transaction_date']),
      );
}
