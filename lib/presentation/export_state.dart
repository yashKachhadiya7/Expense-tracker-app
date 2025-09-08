part of 'export_cubit.dart';

class ExportState extends Equatable {
  final String phase; // idle/exporting/success/failure
  final String? message;
  final String? format; // CSV/PDF while exporting

  const ExportState({required this.phase, this.message, this.format});

  const ExportState.idle() : phase = 'idle', message = null, format = null;
  const ExportState.exporting(this.format) : phase = 'exporting', message = null;
  const ExportState.success(String msg) : phase = 'success', message = msg, format = null;
  const ExportState.failure(String msg) : phase = 'failure', message = msg, format = null;

  @override
  List<Object?> get props => [phase, message, format];
}
