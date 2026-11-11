import 'package:flutter/material.dart';

import '../../models/saving_goal.dart';
import '../../services/api_service.dart';

class SavingsGoalFormScreen extends StatefulWidget {
  final SavingsGoal? existing;

  const SavingsGoalFormScreen({
    super.key,
    this.existing,
  });

  @override
  State<SavingsGoalFormScreen> createState() =>
      _SavingsGoalFormScreenState();
}

class _SavingsGoalFormScreenState
    extends State<SavingsGoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  late final TextEditingController _nameController;
  late final TextEditingController _targetController;

  DateTime? _targetDate;
  bool _saving = false;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();

    final goal = widget.existing;

    _nameController = TextEditingController(
      text: goal?.name ?? '',
    );

    _targetController = TextEditingController(
      text: goal?.targetAmount.toString() ?? '',
    );

    _targetDate = goal?.targetDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initialDate = _targetDate ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(DateTime.now())
          ? DateTime.now()
          : initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final targetAmount = double.tryParse(
      _targetController.text.trim(),
    );

    if (targetAmount == null || targetAmount <= 0) {
      return;
    }

    final existing = widget.existing;

    if (existing != null &&
        targetAmount < existing.currentAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Target cannot be lower than the current saved amount '
            '(\$${existing.currentAmount.toStringAsFixed(2)}).',
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final payload = {
        'name': _nameController.text.trim(),
        'target_amount': targetAmount,
        'target_date':
            _targetDate?.toIso8601String().split('T').first,
      };

      if (existing == null) {
        await _api.createSavingsGoal(payload);
      } else {
        await _api.updateSavingsGoal(
          existing.id,
          payload,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? 'Savings goal created successfully.'
                : 'Savings goal updated successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save savings goal: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Savings Goal' : 'New Savings Goal',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Goal name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Name is required';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetController,
                enabled: !_saving,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Target amount',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Target amount is required';
                  }

                  final amount = double.tryParse(
                    value.trim(),
                  );

                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Target date (optional)',
                ),
                subtitle: Text(
                  _targetDate
                          ?.toIso8601String()
                          .split('T')
                          .first ??
                      'Not set',
                ),
                trailing: const Icon(
                  Icons.calendar_today,
                ),
                onTap: _saving ? null : _pickDate,
              ),
              if (widget.existing != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Current saved: '
                  '\$${widget.existing!.currentAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isEdit
                            ? 'Update Goal'
                            : 'Create Goal',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
