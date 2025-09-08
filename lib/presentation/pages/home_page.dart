import 'package:expense_tracker/presentation/pages/settings_page.dart';
import 'package:expense_tracker/presentation/pages/summary_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../transactions/domain.dart';
import '../../utility/soft_app_bar.dart';
import '../transaction_bloc.dart';
import '../filter_cubit.dart';
import '../category_presets.dart';
import 'add_transaction_page.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FilterCubit(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Expense Tracker'),
      //   actions: [
      //     IconButton(
      //       tooltip: 'Summary',
      //       onPressed: () => Navigator.push(
      //         context,
      //         MaterialPageRoute(builder: (_) => const SummaryPage()),
      //       ),
      //       icon: const Icon(Icons.pie_chart),
      //     ),
      //     IconButton(
      //       tooltip: 'Settings',
      //       onPressed: () => Navigator.push(
      //         context,
      //         MaterialPageRoute(builder: (_) => const SettingsPage()),
      //       ),
      //       icon: const Icon(Icons.settings),
      //     ),
      //   ],
      // ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(84),
        child: SoftAppBar(
          onSummary: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SummaryPage()),
          ),
          onSettings: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          ),
        ),
      ),

// (Optional) to match the light background from the screenshot:
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? const Color(0xFFF6F6F6)
          : null,
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, tState) {
          if (tState.status == TransactionStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return BlocBuilder<FilterCubit, FilterState>(
            builder: (context, fState) {
              final filtered = _applyFilter(tState.items, fState);

              return Column(
                children: [
                  _FilterBar(
                    availableYears: _availableYears(tState.items),
                    selectedMonth: fState.month,
                    selectedYear: fState.year,
                  ),
                  // const Divider(height: 1),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No transactions for selected period'))
                        : _GroupedTransactionList(items: filtered),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'income',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddTransactionPage(defaultType: TransactionType.income),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Income'),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'expense',
            backgroundColor: Colors.red,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddTransactionPage(defaultType: TransactionType.expense),
              ),
            ),
            icon: const Icon(Icons.remove),
            label: const Text('Expense'),
          ),
        ],
      ),
    );
  }

  static List<int> _availableYears(List<TransactionEntity> items) {
    final set = <int>{};
    for (final t in items) {
      set.add(t.date.year);
    }
    if (set.isEmpty) set.add(DateTime.now().year);
    final years = set.toList()..sort();
    return years;
  }

  static List<TransactionEntity> _applyFilter(List<TransactionEntity> items, FilterState f) {
    return items.where((t) {
      if (f.month != null && t.date.month != f.month) return false;
      if (f.year != null && t.date.year != f.year) return false;
      return true;
    }).toList();
  }
}

class _FilterBar extends StatelessWidget {
  final List<int> availableYears;
  final int? selectedMonth;
  final int? selectedYear;

  const _FilterBar({
    required this.availableYears,
    required this.selectedMonth,
    required this.selectedYear,
  });

  static const _kAccent = Color(0xFF6A3BFF); // purple like mock

  @override
  Widget build(BuildContext context) {
    final years = (availableYears.isEmpty ? [DateTime.now().year] : availableYears).toList()..sort();
    final activeCount = (selectedMonth != null ? 1 : 0) + (selectedYear != null ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          // MONTH pill (dropdown)
          Expanded(
            child: _MonthDropdownPill(
              selectedMonth: selectedMonth,
              onSelected: (val) => context.read<FilterCubit>().setMonth(val),
            ),
          ),
          const SizedBox(width: 12),
          // YEAR pill (dropdown)
          Expanded(
            child: _YearDropdownPill(
              years: years,
              selectedYear: selectedYear,
              onSelected: (val) => context.read<FilterCubit>().setYear(val),
            ),
          ),
          const SizedBox(width: 12),
          // Square filter button with badge (dropdown -> Clear)
          _FilterSquareBadge(
            activeCount: activeCount == 0 ? null : activeCount,
            onClear: () => context.read<FilterCubit>().clear(),
          ),
        ],
      ),
    );
  }
}

/// Rounded pill saying "Month" (or selected month) with a dropdown menu.
class _MonthDropdownPill extends StatelessWidget {
  final int? selectedMonth;
  final ValueChanged<int?> onSelected;

  const _MonthDropdownPill({
    required this.selectedMonth,
    required this.onSelected,
  });

  static const _kAccent = Color(0xFF6A3BFF);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = selectedMonth == null
        ? 'Month'
        : DateFormat.MMMM().format(DateTime(2000, selectedMonth!, 1));

    return PopupMenuButton<int?>(
      onSelected: onSelected,
      offset: const Offset(0, 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (_) => <PopupMenuEntry<int?>>[
        PopupMenuItem<int?>(value: null, child: _menuLabel('All months', selectedMonth == null)),
        const PopupMenuDivider(),
        for (int m = 1; m <= 12; m++)
          PopupMenuItem<int?>(
            value: m,
            child: Row(
              children: [
                if (selectedMonth == m)
                  const Icon(Icons.check, size: 18, color: _kAccent)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 6),
                Text(DateFormat.MMM().format(DateTime(2000, m, 1))),
              ],
            ),
          ),
      ],
      child: _pillContainer(
        context,
        Row(
          children: const [
            SizedBox(width: 16),
            Icon(Icons.expand_more, color: _kAccent),
            SizedBox(width: 8),
          ],
        ),
        Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _menuLabel(String text, bool selected) => Text(
    text,
    style: TextStyle(
      fontWeight: selected ? FontWeight.w700 : null,
      color: selected ? _kAccent : null,
    ),
  );

  Widget _pillContainer(BuildContext context, Widget leading, Widget middle) {
    final theme = Theme.of(context);
    return Ink(
      height: 56,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light ? Colors.white : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.brightness == Brightness.light
              ? const Color(0xFFE9E7FB)
              : theme.colorScheme.outlineVariant.withOpacity(.3),
        ),
      ),
      child: Row(children: [leading, middle, const SizedBox(width: 16)]),
    );
  }
}

/// Rounded pill saying "Year" (or selected year) with a dropdown menu.
class _YearDropdownPill extends StatelessWidget {
  final List<int> years;
  final int? selectedYear;
  final ValueChanged<int?> onSelected;

  const _YearDropdownPill({
    required this.years,
    required this.selectedYear,
    required this.onSelected,
  });

  static const _kAccent = Color(0xFF6A3BFF);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = selectedYear == null ? 'Year' : selectedYear.toString();

    return PopupMenuButton<int?>(
      onSelected: onSelected,
      offset: const Offset(0, 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (_) => <PopupMenuEntry<int?>>[
        PopupMenuItem<int?>(value: null, child: _menuLabel('All years', selectedYear == null)),
        const PopupMenuDivider(),
        for (final y in years)
          PopupMenuItem<int?>(
            value: y,
            child: Row(
              children: [
                if (selectedYear == y)
                  const Icon(Icons.check, size: 18, color: _kAccent)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 6),
                Text('$y'),
              ],
            ),
          ),
      ],
      child: _pillContainer(
        context,
        Row(
          children: const [
            SizedBox(width: 16),
            Icon(Icons.expand_more, color: _kAccent),
            SizedBox(width: 8),
          ],
        ),
        Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _menuLabel(String text, bool selected) => Text(
    text,
    style: TextStyle(
      fontWeight: selected ? FontWeight.w700 : null,
      color: selected ? _kAccent : null,
    ),
  );

  Widget _pillContainer(BuildContext context, Widget leading, Widget middle) {
    final theme = Theme.of(context);
    return Ink(
      height: 56,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light ? Colors.white : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.brightness == Brightness.light
              ? const Color(0xFFE9E7FB)
              : theme.colorScheme.outlineVariant.withOpacity(.3),
        ),
      ),
      child: Row(children: [leading, middle, const SizedBox(width: 16)]),
    );
  }
}

/// Square filter button with purple badge; opens a small dropdown that lets you Clear filters.
class _FilterSquareBadge extends StatelessWidget {
  final int? activeCount;
  final VoidCallback onClear;

  const _FilterSquareBadge({required this.activeCount, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      onSelected: (_) => onClear(),
      offset: const Offset(0, 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (_) => const [
        PopupMenuItem<String>(
          value: 'clear',
          child: Row(
            children: [
              Icon(Icons.filter_alt_off, size: 18),
              SizedBox(width: 6),
              Text('Clear filters'),
            ],
          ),
        ),
      ],
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Ink(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light ? Colors.white : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.brightness == Brightness.light
                    ? const Color(0xFFE9E7FB)
                    : theme.colorScheme.outlineVariant.withOpacity(.3),
              ),
            ),
            child: Icon(Icons.tune, color: theme.colorScheme.onSurface),
          ),
          if (activeCount != null)
            Positioned(
              right: -2,
              top: -6,
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: _YearDropdownPill._kAccent, shape: BoxShape.circle),
                child: Text(
                  '$activeCount',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupedTransactionList extends StatelessWidget {
  final List<TransactionEntity> items;
  const _GroupedTransactionList({required this.items});

  @override
  Widget build(BuildContext context) {
    final groups = _groupByDate(items);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: groups.length,
      itemBuilder: (context, gi) {
        final group = groups[gi];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header: Today / Yesterday / Date
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
              child: Text(
                _sectionTitle(group.date),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            // Cards for this day
            ...group.items.map((t) => _TxCard(item: t)),
          ],
        );
      },
    );
  }

  static List<_DateGroup> _groupByDate(List<TransactionEntity> items) {
    final map = <DateTime, List<TransactionEntity>>{};
    for (final t in items) {
      final d = DateTime(t.date.year, t.date.month, t.date.day); // strip time
      (map[d] ??= <TransactionEntity>[]).add(t);
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key)); // newest day first
    return entries
        .map((e) => _DateGroup(
      date: e.key,
      items: e.value..sort((a, b) => b.date.compareTo(a.date)),
    ))
        .toList();
  }

  static String _sectionTitle(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    return DateFormat.yMMMMd().format(date); // e.g. July 5, 2025
  }
}

class _TxCard extends StatelessWidget {
  final TransactionEntity item;
  const _TxCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isInc = item.type == TransactionType.income;
    final color = CategoryPresets.colorFor(item.category, isIncome: isInc);
    final icon = CategoryPresets.iconFor(item.category, isIncome: isInc);
    final title = _labelForCategory(item);
    final time = DateFormat.jm().format(item.date); // 10:00 AM

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          // subtle soft shadow like the screenshot
          if (Theme.of(context).brightness == Brightness.light)
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          // Icon tile
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),

          // Title + note (left side)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category display (e.g., Shopping / Salary / Food)
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                // Note (small, grey)
                Text(
                  item.note.isEmpty ? '—' : item.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Amount + time (right side)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatAmount(item),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isInc ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _labelForCategory(TransactionEntity t) {
    final isInc = t.type == TransactionType.income;
    final map = isInc ? CategoryPresets.income : CategoryPresets.expense;
    return map[t.category] ?? t.category;
  }

  // Formats like the screenshot: "+ ₹5000" / "- ₹120"
  String _formatAmount(TransactionEntity t) {
    // Use INR symbol to match the screenshot; change to locale if you prefer:
    // final fmt = NumberFormat.simpleCurrency(); // locale-based
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final amount = fmt.format(t.amount.abs());
    return '${t.type == TransactionType.income ? '+' : '-'} $amount';
  }
}

class _DateGroup {
  final DateTime date;
  final List<TransactionEntity> items;
  _DateGroup({required this.date, required this.items});
}
