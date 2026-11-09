import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/nodo.dart';
import '../utils/storage.dart';

class JsonReadResult {
  const JsonReadResult({
    required this.file,
    required this.nodos,
    required this.declaredTotal,
    required this.sizeBytes,
    required this.generatedAt,
  });

  final File file;
  final List<Nodo> nodos;
  final int declaredTotal;
  final int sizeBytes;
  final String generatedAt;

  /// Verificación: el total declarado coincide con los registros leídos.
  bool get isValid => declaredTotal == nodos.length;
}

/// Lectura y escritura de nodos en formato JSON.
class JsonManager {
  static const String fileName = 'nodos.json';

  Future<File> file() async => File(p.join((await appFilesDir()).path, fileName));

  Future<File> export(List<Nodo> nodos, {required int dbVersion, required bool includeUbicacion}) async {
    final data = {
      'generado': DateTime.now().toIso8601String(),
      'version_bd': dbVersion,
      'total': nodos.length,
      'nodos': nodos.map((n) => n.toMap(includeUbicacion: includeUbicacion)).toList(),
    };
    final f = await file();
    await f.writeAsString(const JsonEncoder.withIndent('  ').convert(data), flush: true);
    return f;
  }

  Future<JsonReadResult> readAndVerify() async {
    final f = await file();
    if (!await f.exists()) {
      throw FileSystemException('Todavía no existe el archivo. Exporta primero.', f.path);
    }
    final map = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    final nodos = (map['nodos'] as List)
        .map((e) => Nodo.fromMap(Map<String, Object?>.from(e as Map)))
        .toList();
    return JsonReadResult(
      file: f,
      nodos: nodos,
      declaredTotal: map['total'] as int,
      sizeBytes: await f.length(),
      generatedAt: map['generado'] as String,
    );
  }
}
