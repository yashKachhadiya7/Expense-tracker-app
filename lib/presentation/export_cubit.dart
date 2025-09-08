import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';


import '../transactions/domain.dart';

part 'export_state.dart';

class ExportCubit extends Cubit<ExportState> {
  ExportCubit() : super(const ExportState.idle());

  Future<void> exportCsv(List<TransactionEntity> items) async {
    emit(const ExportState.exporting('CSV'));
    try {
      final csv = _buildCsv(items);
      final file = await _writeFile('expenses_${_stamp()}.csv', csv.codeUnits);
      await Share.shareXFiles([XFile(file.path)], text: 'Expense export (CSV)');
      emit(ExportState.success('CSV exported to: ${file.path}'));
    } catch (e) {
      emit(ExportState.failure('CSV export failed: $e'));
    }
  }

  Future<void> exportPdf(List<TransactionEntity> items) async {
    emit(const ExportState.exporting('PDF'));
    try {
      final pdfBytes = await _buildPdf(items);
      final file = await _writeFile('expenses_${_stamp()}.pdf', pdfBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Expense export (PDF)');
      emit(ExportState.success('PDF exported to: ${file.path}'));
    } catch (e) {
      emit(ExportState.failure('PDF export failed: $e'));
    }
  }

  // helpers
  static String _stamp() => DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

  String _buildCsv(List<TransactionEntity> items) {
    final df = DateFormat('yyyy-MM-dd');
    final buf = StringBuffer();
    buf.writeln('Date,Type,Category,Note,Amount');
    for (final t in items) {
      final date = df.format(t.date);
      final type = t.type == TransactionType.income ? 'Income' : 'Expense';
      final note = t.note.replaceAll(',', ' ');
      buf.writeln('$date,$type,${t.category},$note,${t.amount.toStringAsFixed(2)}');
    }
    return buf.toString();
  }

  Future<List<int>> _buildPdf(List<TransactionEntity> items) async {
    final doc = pw.Document();
    final df = DateFormat('yyyy-MM-dd');

    final totalIncome = items
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (a, b) => a + b.amount);
    final totalExpense = items
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (a, b) => a + b.amount);
    final balance = totalIncome - totalExpense;

    doc.addPage(
      pw.MultiPage(
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text('Expense Report', style: pw.TextStyle(fontSize: 22))),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Generated: ${DateTime.now()}'),
              pw.Text('Total: ${items.length} records'),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Date', 'Type', 'Category', 'Note', 'Amount'],
            data: items.map((t) => [
              df.format(t.date),
              t.type == TransactionType.income ? 'Income' : 'Expense',
              t.category,
              t.note,
              t.amount.toStringAsFixed(2),
            ]).toList(),
            headerDecoration: const pw.BoxDecoration(color: PdfColorGrey(0.9)),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerStyle: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            columnWidths: {
              0: const pw.FixedColumnWidth(70),
              1: const pw.FixedColumnWidth(55),
              2: const pw.FixedColumnWidth(90),
              3: const pw.FlexColumnWidth(),
              4: const pw.FixedColumnWidth(60),
            },
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('Total Income:  ${totalIncome.toStringAsFixed(2)}'),
                pw.Text('Total Expense: ${totalExpense.toStringAsFixed(2)}'),
                pw.Text('Net Balance:   ${balance.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ]),
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<File> _writeFile(String filename, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
