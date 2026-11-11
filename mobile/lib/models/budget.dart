class Budget {
  final int id;
  final int? categoryId;
  final String? categoryName;
  final double amount;
  final String period;
  final DateTime startDate;
  final DateTime endDate;

  Budget({
    required this.id,
    this.categoryId,
    this.categoryName,
    required this.amount,
    required this.period,
    required this.startDate,
    required this.endDate,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    final category = json['category'];

    int? categoryId;
    if (json['category_id'] != null) {
      categoryId = int.tryParse(
        json['category_id'].toString(),
      );
    } else if (category is Map &&
        category['id'] != null) {
      categoryId = int.tryParse(
        category['id'].toString(),
      );
    }

    String? categoryName;
    if (json['category_name'] != null) {
      categoryName = json['category_name'].toString();
    } else if (category is Map &&
        category['name'] != null) {
      categoryName = category['name'].toString();
    } else if (category != null) {
      categoryName = category.toString();
    }

    return Budget(
      id: int.tryParse(
            json['id']?.toString() ?? '',
          ) ??
          0,
      categoryId: categoryId,
      categoryName: categoryName,
      amount: double.tryParse(
            json['amount']?.toString() ?? '',
          ) ??
          0.0,
      period: json['period']?.toString() ?? 'monthly',
      startDate: DateTime.tryParse(
            json['start_date']?.toString() ?? '',
          ) ??
          DateTime.now(),
      endDate: DateTime.tryParse(
            json['end_date']?.toString() ?? '',
          ) ??
          DateTime.now().add(
            const Duration(days: 30),
          ),
    );
  }

  Map<String, dynamic> toJson() => {
        'category_id': categoryId,
        'amount': amount,
        'period': period,
        'start_date':
            startDate.toIso8601String().split('T').first,
        'end_date':
            endDate.toIso8601String().split('T').first,
      };
}
