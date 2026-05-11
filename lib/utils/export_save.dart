import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Mobile: passes [bytes] into `file_picker` so SAF / document picker writes the URI.
/// Desktop: path-only dialog, then we write the file.
Future<String?> saveExportWithPicker({
  required String dialogTitle,
  required String fileName,
  required Uint8List bytes,
  FileType type = FileType.custom,
  List<String>? allowedExtensions,
  required String extensionWithoutDot,
}) async {
  if (kIsWeb) return null;

  final ext = extensionWithoutDot.toLowerCase();
  final dotExt = '.$ext';

  if (Platform.isAndroid || Platform.isIOS) {
    return FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: type,
      allowedExtensions: allowedExtensions,
      bytes: bytes,
    );
  }

  final path = await FilePicker.platform.saveFile(
    dialogTitle: dialogTitle,
    fileName: fileName,
    type: type,
    allowedExtensions: allowedExtensions,
  );
  if (path == null) return null;

  var outPath = path;
  if (!outPath.toLowerCase().endsWith(dotExt)) {
    outPath = '$outPath$dotExt';
  }
  await File(outPath).writeAsBytes(bytes);
  return outPath;
}

String exportSavedDisplayName(String? savedPath, String fallbackFileName) {
  if (savedPath == null || savedPath.isEmpty) return fallbackFileName;
  final normalized = savedPath.replaceAll(r'\', '/');
  final parts = normalized.split('/').where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return fallbackFileName;
  return parts.last;
}
