import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/finance_provider.dart';
import '../../models/transaction.dart';
import 'transaction_form_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceProvider>().loadCategories();
      context.read<FinanceProvider>().loadTransactions();
    });
  }

  void _search() {
    context.read<FinanceProvider>().loadTransactions(type: _typeFilter, q: _searchController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final currency = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search note or category...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: _typeFilter,
                  hint: const Text('All'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'income', child: Text('Income')),
                    DropdownMenuItem(value: 'expense', child: Text('Expense')),
                  ],
                  onChanged: (v) {
                    setState(() => _typeFilter = v);
                    _search();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.transactions.isEmpty
                    ? const Center(child: Text('No transactions found.'))
                    : ListView.builder(
                        itemCount: provider.transactions.length,
                        itemBuilder: (ctx, i) {
                          final Transaction t = provider.transactions[i];
                          final isIncome = t.type == 'income';
                          return Dismissible(
                            key: ValueKey(t.id),
                            direction: DismissDirection.endToStart,
                            background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                            onDismissed: (_) => context.read<FinanceProvider>().deleteTransaction(t.id),
                            child: ListTile(
                              leading: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: isIncome ? Colors.green : Colors.red),
                              title: Text(t.category?.name ?? 'Uncategorized'),
                              subtitle: Text('${DateFormat.yMMMd().format(t.date)}${t.note != null ? ' • ${t.note}' : ''}'),
                              trailing: Text(
                                '${isIncome ? '+' : '-'}${currency.format(t.amount)}',
                                style: TextStyle(color: isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                              ),
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TransactionFormScreen(transaction: t))),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransactionFormScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
