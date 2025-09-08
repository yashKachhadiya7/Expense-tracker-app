import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../transactions/domain.dart';
import '../transaction_bloc.dart';
import '../category_presets.dart';

class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Summary')),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, s) {
          if (s.status == TransactionStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final income = s.totalIncome;
          final expense = s.totalExpense;
          final balance = s.balance;

          final expenseByCategory = _groupExpenses(s.items);
          final sections = _buildPieSections(expenseByCategory);

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              final content = ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: isWide
                      ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _Totals(income: income, expense: expense, balance: balance)),
                      const SizedBox(width: 24),
                      Expanded(child: _ExpensePie(sections: sections, data: expenseByCategory)),
                    ],
                  )
                      : Column(
                    children: [
                      _Totals(income: income, expense: expense, balance: balance),
                      const SizedBox(height: 24),
                      _ExpensePie(sections: sections, data: expenseByCategory),
                    ],
                  ),
                ),
              );
              return Center(child: content);
            },
          );
        },
      ),
    );
  }

  static Map<String, double> _groupExpenses(List<TransactionEntity> items) {
    final map = <String, double>{};
    for (final t in items) {
      if (t.type == TransactionType.expense) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }

  static List<PieChartSectionData> _buildPieSections(Map<String, double> data) {
    final total = data.values.fold<double>(0, (a, b) => a + b);
    if (total == 0) return [];
    final sections = <PieChartSectionData>[];
    data.forEach((key, value) {
      final color = CategoryPresets.colorFor(key, isIncome: false);
      final pct = (value / total) * 100;
      sections.add(
        PieChartSectionData(
          color: color,
          value: value,
          title: '${pct.toStringAsFixed(0)}%',
          radius: 90,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    });
    return sections;
  }
}

class _Totals extends StatelessWidget {
  final double income, expense, balance;
  const _Totals({required this.income, required this.expense, required this.balance});

  String _fmt(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CardStat(label: 'Total Income', value: _fmt(income), color: Colors.green),
        const SizedBox(height: 12),
        _CardStat(label: 'Total Expenses', value: _fmt(expense), color: Colors.red),
        const SizedBox(height: 12),
        _CardStat(label: 'Net Balance', value: _fmt(balance), color: cs.primary),
      ],
    );
  }
}

class _CardStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _CardStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withOpacity(.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(.2), child: Icon(Icons.insights, color: color)),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

class _ExpensePie extends StatelessWidget {
  final List<PieChartSectionData> sections;
  final Map<String, double> data;

  const _ExpensePie({required this.sections, required this.data});

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const Card(
        child: SizedBox(height: 280, child: Center(child: Text('No expenses yet'))),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Expense Distribution', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: data.entries.map((e) {
                final color = CategoryPresets.colorFor(e.key, isIncome: false);
                final icon = CategoryPresets.iconFor(e.key, isIncome: false);
                return Chip(
                  avatar: Icon(icon, size: 18, color: color),
                  label: Text('${e.key} (${e.value.toStringAsFixed(2)})'),
                  backgroundColor: color.withOpacity(.1),
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }
}
