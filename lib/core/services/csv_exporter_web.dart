// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

Future<String> exportCsvBytes({
  required Uint8List bytes,
  required String filename,
}) async {
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
}) async {
  final safeName = _sanitize(filename);
  final blob = html.Blob(<Object>[bytes], mimeType ?? _inferMimeType(safeName));
  final objectUrl = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: objectUrl)
    ..download = safeName
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(objectUrl);
  return 'File sedang diunduh.';
}

String _sanitize(String filename) {
  final raw = filename.trim().isEmpty ? 'rekap_absensi.xlsx' : filename.trim();
  final replaced = raw.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  if (replaced.toLowerCase().endsWith('.csv') ||
      replaced.toLowerCase().endsWith('.xlsx')) {
    return replaced;
  }
  return '$replaced.xlsx';
}

String _inferMimeType(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.xlsx')) {
    return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  }
  if (lower.endsWith('.csv')) {
    return 'text/csv;charset=utf-8';
  }
  return 'application/octet-stream';
}
