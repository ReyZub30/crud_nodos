import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Directorio asignado para los archivos JSON y CSV.
///
/// En Android se usa el almacenamiento externo propio de la app:
/// /storage/emulated/0/Android/data/<paquete>/files
/// Esa carpeta se puede revisar con `adb shell` o desde la PC por USB.
Future<Directory> appFilesDir() async {
  if (Platform.isAndroid) {
    final external = await getExternalStorageDirectory();
    if (external != null) return external;
  }
  return getApplicationDocumentsDirectory();
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}

String formatDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}
