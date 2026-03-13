import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  final docsDir = await _resolveTargetDirectory();
  final safeName = _sanitize(filename);
  final file = File('${docsDir.path}${Platform.pathSeparator}$safeName');
  await file.writeAsBytes(bytes, flush: true);

  if (Platform.isWindows) {
    await _openWindowsExplorer(file.path);
    return 'File tersimpan di: ${file.path}';
  }

  try {
    await Share.shareXFiles([
      XFile(file.path, mimeType: mimeType ?? _inferMimeType(safeName)),
    ], text: 'File export rekap absensi');
    return 'File siap dibagikan: ${file.path}';
  } catch (_) {
    return 'File tersimpan di: ${file.path}';
  }
}

String _sanitize(String filename) {
  final raw = filename.trim().isEmpty ? 'rekap_absensi.xlsx' : filename.trim();
  final replaced = raw.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  final lower = replaced.toLowerCase();
  if (lower.endsWith('.csv') || lower.endsWith('.xlsx')) {
    return replaced;
  }
  return '$replaced.xlsx';
}

Future<Directory> _resolveTargetDirectory() async {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    final downloads = await getDownloadsDirectory();
    if (downloads != null) {
      return downloads;
    }
  }
  return getApplicationDocumentsDirectory();
}

Future<void> _openWindowsExplorer(String filePath) async {
  try {
    final path = filePath.replaceAll('/', r'\');
    await Process.run('explorer.exe', ['/select,$path']);
  } catch (_) {
    // Ignore, file is already saved and path is shown to user.
  }
}

String _inferMimeType(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.xlsx')) {
    return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  }
  if (lower.endsWith('.csv')) {
    return 'text/csv';
  }
  return 'application/octet-stream';
}
