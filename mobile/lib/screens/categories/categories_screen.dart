import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/finance_provider.dart';
import '../../models/category.dart';

// US-006 Category Management
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<FinanceProvider>().loadCategories());
  }

  void _openForm({Category? category}) {
    final nameController = TextEditingController(text: category?.name);
    String type = category?.type ?? (_tab.index == 0 ? 'income' : 'expense');
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(category == null ? 'New category' : 'Edit category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'income', child: Text('Income')),
                  DropdownMenuItem(value: 'expense', child: Text('Expense')),
                ],
                onChanged: (v) => setDialogState(() => type = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final provider = context.read<FinanceProvider>();
                if (category == null) {
                  await provider.categoryRepo.create(nameController.text.trim(), type);
                } else {
                  await provider.categoryRepo.update(category.id, nameController.text.trim(), type);
                }
                await provider.loadCategories();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(String type) {
    final provider = context.watch<FinanceProvider>();
    final items = provider.categories.where((c) => c.type == type).toList();
    if (provider.loading) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) return const Center(child: Text('No categories yet.'));
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final c = items[i];
        return ListTile(
          leading: CircleAvatar(backgroundColor: _colorFromHex(c.color)),
          title: Text(c.name),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _openForm(category: c)),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: () async {
                final provider = context.read<FinanceProvider>();
                await provider.categoryRepo.delete(c.id);
                await provider.loadCategories();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color _colorFromHex(String hex) {
    hex = hex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(controller: _tab, tabs: const [Tab(text: 'Income'), Tab(text: 'Expense')]),
      ),
      body: TabBarView(controller: _tab, children: [_list('income'), _list('expense')]),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
    );
  }
}
