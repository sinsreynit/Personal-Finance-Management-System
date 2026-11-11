import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:printing/printing.dart';

import '../../services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _api = ApiService();

  DateTime _from =
      DateTime(DateTime.now().year, DateTime.now().month, 1);

  DateTime _to =
      DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  bool _loading = true;
  String? _error;
  bool _exporting = false;

  Map<String, dynamic>? _financial;
  Map<String, dynamic>? _budgetReport;
  Map<String, dynamic>? _chartData;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.getFinancialReport(
          from: _from,
          to: _to,
        ),
        _api.getBudgetReport(
          from: _from,
          to: _to,
        ),
        _api.getChartData(
          from: _from,
          to: _to,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _financial = results[0];
        _budgetReport = results[1];
        _chartData = results[2];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not load reports.';
        _loading = false;
      });
    }
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: _from,
        end: _to,
      ),
    );

    if (picked != null) {
      setState(() {
        _from = picked.start;
        _to = picked.end;
      });

      await _load();
    }
  }

  Future<void> _exportPdf() async {
    if (_exporting) return;

    setState(() {
      _exporting = true;
    });

    try {
      final List<int> bytes = await _api.exportReportPdf(
        from: _from,
        to: _to,
      );

      // Printing.layoutPdf requires Uint8List.
      final Uint8List pdfBytes = Uint8List.fromList(bytes);

      await Printing.layoutPdf(
        onLayout: (format) async {
          return pdfBytes;
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not export PDF: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickRange,
            tooltip: 'Select date range',
          ),
          IconButton(
            icon: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf),
            onPressed: _exporting ? null : _exportPdf,
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final f = _financial!;

    final monthly =
        List<Map<String, dynamic>>.from(
      _chartData?['monthly_trend'] ?? [],
    );

    final byCategory =
        List<Map<String, dynamic>>.from(
      _chartData?['expense_by_category'] ?? [],
    );

    final budgets =
        List<Map<String, dynamic>>.from(
      _budgetReport?['budgets'] ?? [],
    );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${f['from']}  –  ${f['to']}',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  'Income',
                  f['total_income'],
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryCard(
                  'Expense',
                  f['total_expense'],
                  Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryCard(
                  'Balance',
                  f['balance'],
                  Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            'Income vs Expense',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 12),

          if (monthly.isEmpty)
            const Text(
              'No transactions in this period.',
              style: TextStyle(
                color: Colors.grey,
              ),
            )
          else
            SizedBox(
              height: 220,
              child: _trendChart(monthly),
            ),

          const SizedBox(height: 24),

          const Text(
            'Expense by Category',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 12),

          if (byCategory.isEmpty)
            const Text(
              'No expenses in this period.',
              style: TextStyle(
                color: Colors.grey,
              ),
            )
          else
            SizedBox(
              height: 220,
              child: _categoryPieChart(byCategory),
            ),

          const SizedBox(height: 24),

          const Text(
            'Budget Report',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 8),

          if (budgets.isEmpty)
            const Text(
              'No budgets active in this period.',
              style: TextStyle(
                color: Colors.grey,
              ),
            )
          else
            ...budgets.map(_budgetTile),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _summaryCard(
    String label,
    dynamic value,
    Color color,
  ) {
    final amount =
        double.tryParse(value.toString()) ?? 0;

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trendChart(
    List<Map<String, dynamic>> monthly,
  ) {
    double maxY = 0;

    for (final m in monthly) {
      final income =
          (m['income'] as num).toDouble();

      final expense =
          (m['expense'] as num).toDouble();

      if (income > maxY) {
        maxY = income;
      }

      if (expense > maxY) {
        maxY = expense;
      }
    }

    if (maxY == 0) {
      maxY = 1;
    }

    return BarChart(
      BarChartData(
        maxY: maxY * 1.2,

        barGroups: [
          for (int i = 0;
              i < monthly.length;
              i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY:
                      (monthly[i]['income'] as num)
                          .toDouble(),
                  color: Colors.green,
                  width: 8,
                ),

                BarChartRodData(
                  toY:
                      (monthly[i]['expense'] as num)
                          .toDouble(),
                  color: Colors.red,
                  width: 8,
                ),
              ],
            ),
        ],

        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
            ),
          ),

          topTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),

          rightTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),

          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget:
                  (value, meta) {
                final i = value.toInt();

                if (i < 0 ||
                    i >= monthly.length) {
                  return const SizedBox.shrink();
                }

                final month =
                    monthly[i]['month']
                            ?.toString() ??
                        '';

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 6,
                  ),
                  child: Text(
                    month.length >= 7
                        ? month.substring(5)
                        : month,
                    style: const TextStyle(
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        gridData: const FlGridData(
          show: true,
        ),

        borderData: FlBorderData(
          show: false,
        ),
      ),
    );
  }

  static const _palette = [
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.indigo,
    Colors.brown,
  ];

  Widget _categoryPieChart(
    List<Map<String, dynamic>> byCategory,
  ) {
    final total = byCategory.fold<double>(
      0,
      (sum, r) =>
          sum +
          (r['total'] as num).toDouble(),
    );

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 32,

              sections: [
                for (int i = 0;
                    i < byCategory.length;
                    i++)
                  PieChartSectionData(
                    value:
                        (byCategory[i]['total']
                                as num)
                            .toDouble(),

                    title: total == 0
                        ? ''
                        : '${(((byCategory[i]['total'] as num).toDouble() / total) * 100).toStringAsFixed(0)}%',

                    color:
                        _palette[
                            i % _palette.length],

                    radius: 60,

                    titleStyle:
                        const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0;
                  i < byCategory.length;
                  i++)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        color: _palette[
                            i % _palette.length],
                      ),

                      const SizedBox(width: 6),

                      Expanded(
                        child: Text(
                          byCategory[i]['category']
                                  ?.toString() ??
                              '',
                          style:
                              const TextStyle(
                            fontSize: 11,
                          ),
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _budgetTile(
    Map<String, dynamic> b,
  ) {
    final percent =
        (double.tryParse(
                  b['percent_used'].toString(),
                ) ??
                0) /
            100;

    final over =
        b['over_budget'] == true;

    return Card(
      margin:
          const EdgeInsets.only(bottom: 8),

      child: Padding(
        padding: const EdgeInsets.all(12),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [
                Text(
                  b['category'] ??
                      'Uncategorized',
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                Text(
                  '${b['percent_used']}%',
                  style: TextStyle(
                    color: over
                        ? Colors.red
                        : Colors.black,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            LinearProgressIndicator(
              value: percent
                  .clamp(0, 1)
                  .toDouble(),

              color: over
                  ? Colors.red
                  : Colors.blue,

              backgroundColor:
                  Colors.grey.shade200,
            ),

            const SizedBox(height: 4),

            Text(
              'Spent ${b['spent']} of ${b['amount']}',
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