import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/theme_cubit.dart';
import '../export_cubit.dart';
import '../transaction_bloc.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExportCubit(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocConsumer<ExportCubit, ExportState>(
        listener: (context, s) {
          if (s.phase == 'success' || s.phase == 'failure') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s.message ?? 'Done')),
            );
          }
        },
        builder: (context, s) {
          final exporting = s.phase == 'exporting';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: SwitchListTile(
                  value: context.watch<ThemeCubit>().state.mode == ThemeMode.dark,
                  onChanged: (v) => context.read<ThemeCubit>().toggleDark(v),
                  title: const Text('Dark mode'),
                  subtitle: const Text('Toggle app appearance'),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Export Data', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: exporting
                                  ? null
                                  : () {
                                final items = context.read<TransactionBloc>().state.items;
                                context.read<ExportCubit>().exportCsv(items);
                              },
                              icon: const Icon(Icons.table_view),
                              label: Text(exporting ? 'Exporting…' : 'Export CSV'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: exporting
                                  ? null
                                  : () {
                                final items = context.read<TransactionBloc>().state.items;
                                context.read<ExportCubit>().exportPdf(items);
                              },
                              icon: const Icon(Icons.picture_as_pdf),
                              label: Text(exporting ? 'Exporting…' : 'Export PDF'),
                            ),
                          ),
                        ],
                      ),
                      if (exporting) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(minHeight: 4),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
