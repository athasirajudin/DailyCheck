import 'dart:typed_data';

import 'csv_exporter_stub.dart'
    if (dart.library.io) 'csv_exporter_io.dart'
    if (dart.library.html) 'csv_exporter_web.dart'
    as impl;

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
  return impl.exportFileBytes(
    bytes: bytes,
    filename: filename,
    mimeType: mimeType,
  );
}
