import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../models/budget.dart';
import '../../models/saving_goal.dart';
import '../budget/budget_form_screen.dart';
import '../savings/savings_goal_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();

  Map<String, dynamic>? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final data = await _api.getDashboardSummary();

      if (!mounted) return;

      setState(() {
        _summary = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not load dashboard: $e';
        _loading = false;
      });
    }
  }

  int? _idFrom(dynamic value) {
    return int.tryParse(value?.toString() ?? '');
  }

  double _number(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _categoryName(Map<String, dynamic> budget) {
    final category = budget['category'];

    if (category is Map) {
      return category['name']?.toString() ?? 'Uncategorized';
    }

    final name = budget['category_name']?.toString();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    if (category != null && category.toString().isNotEmpty) {
      return category.toString();
    }

    return 'Uncategorized';
  }

  Future<void> _deleteBudget(Map<String, dynamic> budget) async {
    final id = _idFrom(budget['id']);

    if (id == null) {
      _showMessage('Invalid budget ID.');
      return;
    }

    final name = _categoryName(budget);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Budget'),
          content: Text(
            'Are you sure you want to delete the "$name" budget?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _api.deleteBudget(id);

      if (!mounted) return;

      _showMessage('Budget deleted successfully.');
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed to delete budget: $e');
    }
  }

  Future<void> _editBudget(Map<String, dynamic> budget) async {
    final id = _idFrom(budget['id']);

    if (id == null) {
      _showMessage('Invalid budget ID.');
      return;
    }

    try {
      final existing = Budget.fromJson(budget);

      final updated = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => BudgetFormScreen(existing: existing),
        ),
      );

      if (updated == true) {
        await _load();
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not open budget editor: $e');
    }
  }

  Future<void> _addSavingsMoney(Map<String, dynamic> goal) async {
    final id = _idFrom(goal['id']);

    if (id == null) {
      _showMessage('Invalid savings goal ID.');
      return;
    }

    final name = goal['name']?.toString() ?? 'Savings Goal';
    final target = _number(goal['target_amount']);
    final current = _number(goal['current_amount']);

    final remaining = (target - current).clamp(0, double.infinity).toDouble();

    if (remaining <= 0) {
      _showMessage('This savings goal is already complete.');
      return;
    }

    final controller = TextEditingController();

    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        String? error;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Add money to "$name"'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remaining to goal: '
                    '\$${remaining.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '\$ ',
                      errorText: error,
                    ),
                    onChanged: (_) {
                      if (error != null) {
                        setDialogState(() => error = null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = double.tryParse(
                      controller.text.trim(),
                    );

                    if (value == null || value <= 0) {
                      setDialogState(
                        () => error = 'Enter a valid amount.',
                      );
                      return;
                    }

                    if (value > remaining) {
                      setDialogState(
                        () => error =
                            'Maximum for this goal is '
                            '\$${remaining.toStringAsFixed(2)}.',
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, value);
                  },
                  child: const Text('Add Money'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (amount == null) return;

    try {
      final result = await _api.addSavingsProgress(id, amount);

      if (!mounted) return;

      final availableBalance = _number(result['available_balance']);

      _showMessage(
        'Added \$${amount.toStringAsFixed(2)}. '
        'Available balance: \$${availableBalance.toStringAsFixed(2)}',
      );

      await _load();
    } catch (e) {
      if (!mounted) return;

      _showMessage('Could not add money: $e');
    }
  }

  Future<void> _editSavingsGoal(Map<String, dynamic> goal) async {
    final id = _idFrom(goal['id']);

    if (id == null) {
      _showMessage('Invalid savings goal ID.');
      return;
    }

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SavingsGoalFormScreen(
          existing: SavingsGoal.fromJson(goal),
        ),
      ),
    );

    if (updated == true) {
      await _load();
    }
  }

  Future<void> _deleteSavingsGoal(Map<String, dynamic> goal) async {
    final id = _idFrom(goal['id']);

    if (id == null) {
      _showMessage('Invalid savings goal ID.');
      return;
    }

    final name = goal['name']?.toString() ?? 'Savings Goal';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Savings Goal'),
          content: Text(
            'Are you sure you want to delete "$name"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _api.deleteSavingsGoal(id);

      if (!mounted) return;

      _showMessage('Savings goal deleted successfully.');
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed to delete savings goal: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final s = _summary ?? {};

    final budgets = List<Map<String, dynamic>>.from(
      s['budgets'] ?? const [],
    );

    final goals = List<Map<String, dynamic>>.from(
      s['savings_goals'] ?? const [],
    );

    return Scaffold(
      floatingActionButton: PopupMenuButton<String>(
        onSelected: (choice) async {
          bool? result;

          if (choice == 'budget') {
            result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => const BudgetFormScreen(),
              ),
            );
          } else if (choice == 'goal') {
            result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => const SavingsGoalFormScreen(),
              ),
            );
          }

          if (result == true) {
            await _load();
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem<String>(
            value: 'budget',
            child: Text('Add budget'),
          ),
          PopupMenuItem<String>(
            value: 'goal',
            child: Text('Add savings goal'),
          ),
        ],
        child: const FloatingActionButton(
          onPressed: null,
          child: Icon(Icons.add),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    'Income',
                    s['total_income'],
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _summaryCard(
                    'Expense',
                    s['total_expense'],
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _summaryCard(
                    'Balance',
                    s['balance'],
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Budgets',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            if (budgets.isEmpty)
              const Text(
                'No budgets set yet.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...budgets.map(_budgetTile),
            const SizedBox(height: 24),
            const Text(
              'Savings Goals',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            if (goals.isEmpty)
              const Text(
                'No savings goals yet.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...goals.map(_goalTile),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(
    String label,
    dynamic value,
    Color color,
  ) {
    final amount = _number(value);

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amount.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _budgetTile(Map<String, dynamic> budget) {
    final percentUsed = _number(budget['percent_used']);
    final progress = (percentUsed / 100).clamp(0, 1).toDouble();
    final over = percentUsed > 100;

    final category = _categoryName(budget);
    final spent = _number(budget['spent']);
    final amount = _number(budget['amount']);

    final budgetId = _idFrom(budget['id']);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${percentUsed.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: over ? Colors.red : Colors.black,
                  ),
                ),
                if (budgetId != null) ...[
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit budget',
                    onPressed: () => _editBudget(budget),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    tooltip: 'Delete budget',
                    onPressed: () => _deleteBudget(budget),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              color: over ? Colors.red : Colors.blue,
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 4),
            Text(
              'Spent \$${spent.toStringAsFixed(2)} '
              'of \$${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalTile(Map<String, dynamic> goal) {
    final percent = _number(goal['percent']);
    final progress = (percent / 100).clamp(0, 1).toDouble();

    final goalId = _idFrom(goal['id']);
    final name = goal['name']?.toString() ?? 'Savings Goal';
    final current = _number(goal['current_amount']);
    final target = _number(goal['target_amount']);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (goalId != null) ...[
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit savings goal',
                    onPressed: () => _editSavingsGoal(goal),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: Colors.green,
                    ),
                    tooltip: 'Add money',
                    onPressed: () => _addSavingsMoney(goal),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    tooltip: 'Delete savings goal',
                    onPressed: () => _deleteSavingsGoal(goal),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              color: Colors.green,
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 4),
            Text(
              '\$${current.toStringAsFixed(2)} '
              'of \$${target.toStringAsFixed(2)} '
              '(${percent.toStringAsFixed(0)}%)',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
