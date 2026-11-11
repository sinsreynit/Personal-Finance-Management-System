import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/finance_provider.dart';
import '../../models/transaction.dart';

class TransactionFormScreen extends StatefulWidget {
  final Transaction? transaction;
  const TransactionFormScreen({super.key, this.transaction});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  int? _categoryId;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _type = t?.type ?? 'expense';
    _amountController.text = t?.amount.toString() ?? '';
    _noteController.text = t?.note ?? '';
    _date = t?.date ?? DateTime.now();
    _categoryId = t?.categoryId;
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<FinanceProvider>().loadCategories(type: _type));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) {
      setState(() => _error = _categoryId == null ? 'Please select a category.' : null);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final provider = context.read<FinanceProvider>();
      final amount = double.parse(_amountController.text.trim());
      final note = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();

      if (_isEditing) {
        await provider.transactionRepo.update(
          widget.transaction!.id,
          categoryId: _categoryId!,
          type: _type,
          amount: amount,
          note: note,
          date: _date,
        );
        await provider.loadTransactions();
      } else {
        await provider.addTransaction(
          categoryId: _categoryId!,
          type: _type,
          amount: amount,
          note: note,
          date: _date,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (widget.transaction == null) return;
    try {
      final deleted = await context.read<FinanceProvider>()
          .deleteTransaction(widget.transaction!.id);
      if (deleted && mounted) Navigator.pop(context, true);
      if (!deleted && mounted) {
        setState(() => _error = 'Could not delete transaction.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final categoriesForType = provider.categories.where((c) => c.type == _type).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          if (_isEditing) IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'income', label: Text('Income')),
                  ButtonSegment(value: 'expense', label: Text('Expense')),
                ],
                selected: {_type},
                onSelectionChanged: (s) {
                  setState(() { _type = s.first; _categoryId = null; });
                  context.read<FinanceProvider>().loadCategories(type: _type);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder(), prefixText: '\$ '),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  return (n == null || n <= 0) ? 'Enter a valid amount' : null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _categoryId,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: categoriesForType.map<DropdownMenuItem<int>>((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Date: ${_date.toLocal().toString().split(' ').first}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isEditing ? 'Update' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
