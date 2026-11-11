class SavingsGoal {
  final int id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
  });

  double get percent =>
      targetAmount <= 0
          ? 0
          : (currentAmount / targetAmount * 100).clamp(0, 100);

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,

      name: json['name']?.toString() ?? '',

      targetAmount: double.tryParse(
            json['target_amount']?.toString() ?? '',
          ) ??
          0.0,

      currentAmount: double.tryParse(
            json['current_amount']?.toString() ?? '',
          ) ??
          0.0,

      targetDate: json['target_date'] != null &&
              json['target_date'].toString().isNotEmpty
          ? DateTime.tryParse(json['target_date'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'target_amount': targetAmount,
        'target_date': targetDate?.toIso8601String().split('T').first,
      };
}