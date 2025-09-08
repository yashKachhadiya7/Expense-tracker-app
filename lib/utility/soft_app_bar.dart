import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../presentation/filter_cubit.dart';

class SoftAppBar extends StatelessWidget {
  final VoidCallback onSummary;
  final VoidCallback onSettings;
  const SoftAppBar({required this.onSummary, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: light ? const Color(0xFFF6F6F6) : theme.colorScheme.surface,
          boxShadow: light
              ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              // Title + small subtitle showing current filter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expense Tracker',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    BlocBuilder<FilterCubit, FilterState>(
                      builder: (context, f) {
                        final subtitle = _filterSubtitle(f);
                        return Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _RoundIconButton(icon: Icons.pie_chart, onTap: onSummary),
              const SizedBox(width: 8),
              _RoundIconButton(icon: Icons.settings, onTap: onSettings),
            ],
          ),
        ),
      ),
    );
  }

  String _filterSubtitle(FilterState f) {
    if (f.month == null && f.year == null) return 'All time';
    if (f.month != null && f.year != null) {
      return '${DateFormat.MMMM().format(DateTime(2000, f.month!))} ${f.year}';
    }
    if (f.month != null) {
      return DateFormat.MMMM().format(DateTime(2000, f.month!));
    }
    return '${f.year}';
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: light ? Colors.white : theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          boxShadow: light
              ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
    );
  }
}
