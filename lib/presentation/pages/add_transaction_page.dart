import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../transactions/domain.dart';
import '../transaction_bloc.dart';
import '../form_cubit.dart';
import '../category_presets.dart';

const _kAccent = Color(0xFF6A3BFF); // soft purple to match the design

class AddTransactionPage extends StatelessWidget {
  final TransactionType defaultType;
  const AddTransactionPage({super.key, required this.defaultType});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TransactionFormCubit(initialType: defaultType),
      child: const _AddForm(),
    );
  }
}

class _AddForm extends StatefulWidget {
  const _AddForm();

  @override
  State<_AddForm> createState() => _AddFormState();
}

/// NOTE: We use StatefulWidget to keep controllers alive across Bloc rebuilds.
/// No setState is used; all UI state flows through Cubits.
class _AddFormState extends State<_AddForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat.yMMMd();

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light
          ? const Color(0xFFF6F6F6)
          : theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Add Transaction'),
        backgroundColor: theme.brightness == Brightness.light
            ? const Color(0xFFF6F6F6)
            : theme.colorScheme.surface,
        elevation: 0,
      ),
      bottomNavigationBar: saveActionBar(
        context: context,
        label: 'Save',
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          final form = context.read<TransactionFormCubit>().state;
          final tx = TransactionEntity(
            id: const Uuid().v4(),
            amount: double.parse(_amountCtrl.text),
            note: _noteCtrl.text.trim(),
            date: form.date,
            type: form.type,
            category: form.category,
          );
          context.read<TransactionBloc>().add(TransactionAdded(tx));
          Navigator.pop(context);
        },
        // Optionally wire to a Bloc state:
        // loading: context.watch<TransactionBloc>().state.status == TransactionStatus.loading,
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 16),
              child: BlocBuilder<TransactionFormCubit, TransactionFormState>(
                builder: (context, formState) {
                  final isIncome = formState.type == TransactionType.income;
                  final catMap = isIncome ? CategoryPresets.income : CategoryPresets.expense;
                  final cats = catMap.entries.toList();

                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Soft card wrapper for the whole form content
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.light
                                ? Colors.white
                                : theme.colorScheme.surfaceVariant.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: theme.brightness == Brightness.light
                                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6))]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Type segmented toggle
                              SegmentedButton<TransactionType>(
                                segments: const [
                                  ButtonSegment(
                                    value: TransactionType.income,
                                    label: Text('Income'),
                                    icon: Icon(Icons.south_west),
                                  ),
                                  ButtonSegment(
                                    value: TransactionType.expense,
                                    label: Text('Expense'),
                                    icon: Icon(Icons.north_east),
                                  ),
                                ],
                                selected: {formState.type},
                                style: ButtonStyle(
                                  visualDensity: VisualDensity.comfortable,
                                  side: WidgetStatePropertyAll(
                                    BorderSide(color: theme.colorScheme.outlineVariant),
                                  ),
                                ),
                                onSelectionChanged: (set) =>
                                    context.read<TransactionFormCubit>().setType(set.first),
                              ),
                              const SizedBox(height: 16),

                              // Amount + Note row/column
                              if (isWide)
                                Row(
                                  children: [
                                    Expanded(child: _AmountField(controller: _amountCtrl)),
                                    const SizedBox(width: 12),
                                    Expanded(child: _NoteField(controller: _noteCtrl)),
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    _AmountField(controller: _amountCtrl),
                                    const SizedBox(height: 12),
                                    _NoteField(controller: _noteCtrl),
                                  ],
                                ),

                              const SizedBox(height: 16),

                              // Date picker row
                              Row(
                                children: [
                                  Icon(Icons.calendar_month, color: _kAccent),
                                  const SizedBox(width: 8),
                                  Text(df.format(formState.date),
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 10),
                                  OutlinedButton(
                                    onPressed: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
                                        initialDate: formState.date,
                                      );
                                      if (picked != null) {
                                        context.read<TransactionFormCubit>().setDate(picked);
                                      }
                                    },
                                    child: const Text('Pick Date'),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Categories grid (chips with icons)
                              Text('Category', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final e in cats)
                                    ChoiceChip(
                                      selected: formState.category == e.key,
                                      onSelected: (_) =>
                                          context.read<TransactionFormCubit>().setCategory(e.key),
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            CategoryPresets.iconFor(e.key, isIncome: isIncome),
                                            size: 18,
                                            color: CategoryPresets.colorFor(e.key, isIncome: isIncome),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(e.value),
                                        ],
                                      ),
                                      selectedColor: _kAccent.withOpacity(.12),
                                      labelStyle: TextStyle(
                                        color: formState.category == e.key ? _kAccent : null,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(22),
                                        side: BorderSide(
                                          color: formState.category == e.key
                                              ? _kAccent.withOpacity(.3)
                                              : theme.colorScheme.outlineVariant,
                                        ),
                                      ),
                                      backgroundColor: theme.brightness == Brightness.light
                                          ? Colors.white
                                          : theme.colorScheme.surface,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget saveActionBar({
    required BuildContext context,
    required VoidCallback onPressed,
    String label = 'Save',
    IconData icon = Icons.check,
    bool loading = false,
  }) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (theme.brightness == Brightness.light)
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onPressed: loading
                  ? null
                  : () {
                HapticFeedback.selectionClick();
                onPressed();
              },
              icon: loading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                ),
              )
                  : Icon(icon),
              label: Text(label),
            ),
          ),
        ),
      ),
    );
  }

}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  const _AmountField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Amount',
        prefixText: '₹ ',
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: _kAccent, width: 1.5),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      validator: (v) {
        final n = double.tryParse(v ?? '');
        if (n == null || n <= 0) return 'Enter a valid amount';
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }
}

class _NoteField extends StatelessWidget {
  final TextEditingController controller;
  const _NoteField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Note (optional)',
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: _kAccent, width: 1.5),
        ),
      ),
      textInputAction: TextInputAction.done,
    );
  }
}
