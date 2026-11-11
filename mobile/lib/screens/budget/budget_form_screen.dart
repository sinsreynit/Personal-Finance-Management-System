import 'package:flutter/material.dart';

import '../../models/budget.dart';
import '../../models/category.dart';
import '../../services/api_service.dart';
import '../../services/category_repository.dart';

class BudgetFormScreen extends StatefulWidget {
  final Budget? existing;

  const BudgetFormScreen({
    super.key,
    this.existing,
  });

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _api = ApiService();
  late final CategoryRepository _categoryRepository;

  late TextEditingController _amountController;

  String _period = 'monthly';

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(
    const Duration(days: 30),
  );

  List<Category> _categories = [];
  int? _categoryId;

  bool _loadingCategories = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _categoryRepository = CategoryRepository(_api);

    final b = widget.existing;

    _amountController = TextEditingController(
      text: b?.amount.toString() ?? '',
    );

    _period = b?.period ?? 'monthly';

    _startDate = b?.startDate ?? DateTime.now();

    _endDate = b?.endDate ??
        DateTime.now().add(
          const Duration(days: 30),
        );

    _categoryId = b?.categoryId;

    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryRepository.list(
        type: 'expense',
      );

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingCategories = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load categories: $e',
          ),
        ),
      );
    }
  }

  Future<void> _pickDate({
    required bool isStart,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;

        if (!_endDate.isAfter(_startDate)) {
          _endDate = _startDate.add(
            const Duration(days: 30),
          );
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a category.',
          ),
        ),
      );
      return;
    }

    if (!_endDate.isAfter(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'End date must be after start date.',
          ),
        ),
      );
      return;
    }

    final amount = double.tryParse(
      _amountController.text.trim(),
    );

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid amount.',
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
        'category_id': _categoryId,
        'amount': amount,
        'period': _period,
        'start_date':
            _startDate.toIso8601String().split('T').first,
        'end_date':
            _endDate.toIso8601String().split('T').first,
      };

      if (widget.existing == null) {
        await _api.createBudget(payload);
      } else {
        await _api.updateBudget(
          widget.existing!.id,
          payload,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existing == null
                ? 'Budget created successfully.'
                : 'Budget updated successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save budget: $e',
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
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Budget' : 'Create Budget',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_loadingCategories)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                DropdownButtonFormField<int>(
                  value: _categories.any(
                    (category) =>
                        category.id == _categoryId,
                  )
                      ? _categoryId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map(
                    (category) {
                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(category.name),
                      );
                    },
                  ).toList(),
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() {
                            _categoryId = value;
                          });
                        },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Amount is required';
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

              DropdownButtonFormField<String>(
                value: _period,
                decoration: const InputDecoration(
                  labelText: 'Period',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'weekly',
                    child: Text('Weekly'),
                  ),
                  DropdownMenuItem(
                    value: 'monthly',
                    child: Text('Monthly'),
                  ),
                  DropdownMenuItem(
                    value: 'yearly',
                    child: Text('Yearly'),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value == null) return;

                        setState(() {
                          _period = value;
                        });
                      },
              ),

              const SizedBox(height: 8),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start date'),
                subtitle: Text(
                  _startDate
                      .toIso8601String()
                      .split('T')
                      .first,
                ),
                trailing: const Icon(
                  Icons.calendar_today,
                ),
                onTap: _saving
                    ? null
                    : () => _pickDate(
                          isStart: true,
                        ),
              ),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('End date'),
                subtitle: Text(
                  _endDate
                      .toIso8601String()
                      .split('T')
                      .first,
                ),
                trailing: const Icon(
                  Icons.calendar_today,
                ),
                onTap: _saving
                    ? null
                    : () => _pickDate(
                          isStart: false,
                        ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isEdit
                            ? 'Update Budget'
                            : 'Create Budget',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}