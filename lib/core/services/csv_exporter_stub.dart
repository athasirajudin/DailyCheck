import 'dart:typed_data';

Future<String> exportCsvBytes({
  required Uint8List bytes,
  required String filename,
}) {
  return exportFileBytes(
    bytes: bytes,
    filename: filename,
    mimeType: 'text/csv',
  );
}

Future<String> exportFileBytes({
  required Uint8List bytes,
  required String filename,
  String? mimeType,
}) {
  throw UnsupportedError('Export file belum didukung di platform ini.');
}
