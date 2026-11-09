import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../models/nodo.dart';
import '../utils/storage.dart';

/// Se lanza cuando el archivo CSV no pasa la verificación de integridad.
class CsvIntegrityException implements Exception {
  const CsvIntegrityException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CsvExportResult {
  const CsvExportResult({required this.file, required this.checksum, required this.rows});
  final File file;
  final String checksum;
  final int rows;
}

class CsvImportResult {
  const CsvImportResult({required this.nodos, required this.checksum});
  final List<Nodo> nodos;
  final String checksum;
}

/// Práctica guiada 1: exporta e importa nodos en CSV con firma SHA-256.
///
/// Formato del archivo:
///   # CHECKSUM:<sha256 del contenido de abajo>
///   id,nombre,tipo,valor,fecha_registro[,ubicacion_nodo]
///   1,Nodo-0001,Temperatura,24.5,2026-11-08T12:00:00.000
///   ...
///
/// La firma se calcula sobre TODO lo que va después de la primera línea.
/// Si alguien modifica un solo carácter, el hash cambia y el archivo se rechaza.
class CsvNodeManager {
  static const String fileName = 'nodos.csv';
  static const String checksumPrefix = '# CHECKSUM:';
  static const List<String> baseColumns = ['id', 'nombre', 'tipo', 'valor', 'fecha_registro'];

  Future<File> file() async => File(p.join((await appFilesDir()).path, fileName));

  static String sha256Of(String text) => sha256.convert(utf8.encode(text)).toString();

  // ---------------------------------------------------------------------------
  // Exportar
  // ---------------------------------------------------------------------------

  Future<CsvExportResult> export(List<Nodo> nodos, {required bool includeUbicacion}) async {
    final headers = [...baseColumns, if (includeUbicacion) 'ubicacion_nodo'];
    final buffer = StringBuffer(headers.join(','));
    for (final nodo in nodos) {
      final map = nodo.toMap(includeUbicacion: includeUbicacion);
      buffer
        ..write('\n')
        ..write(headers.map((h) => _escape('${map[h] ?? ''}')).join(','));
    }
    final body = buffer.toString();
    final checksum = sha256Of(body);

    final f = await file();
    await f.writeAsString('$checksumPrefix$checksum\n$body', flush: true);
    return CsvExportResult(file: f, checksum: checksum, rows: nodos.length);
  }

  // ---------------------------------------------------------------------------
  // Importar (verificando antes de procesar)
  // ---------------------------------------------------------------------------

  Future<CsvImportResult> importVerified() async {
    final f = await file();
    if (!await f.exists()) {
      throw const CsvIntegrityException('No existe el archivo CSV. Exporta primero.');
    }
    final content = await f.readAsString();

    // 1. Separar la cabecera del checksum del contenido.
    final newline = content.indexOf('\n');
    if (newline < 0) throw const CsvIntegrityException('El archivo está vacío o incompleto.');
    final firstLine = content.substring(0, newline).trim();
    if (!firstLine.startsWith(checksumPrefix)) {
      throw const CsvIntegrityException('Falta la cabecera "# CHECKSUM:". Archivo rechazado.');
    }
    final expected = firstLine.substring(checksumPrefix.length).trim();
    final body = content.substring(newline + 1);

    // 2. Recalcular y comparar ANTES de procesar cualquier dato.
    final actual = sha256Of(body);
    if (expected != actual) {
      throw CsvIntegrityException(
        'El checksum no coincide: el archivo fue alterado y se rechazó.\n'
        'Esperado: ${_short(expected)}\nCalculado: ${_short(actual)}',
      );
    }

    // 3. Solo si es íntegro, se convierte a objetos.
    final lines = body.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return CsvImportResult(nodos: const [], checksum: actual);
    final headers = _parseLine(lines.first);
    final nodos = <Nodo>[];
    for (final line in lines.skip(1)) {
      final values = _parseLine(line);
      final row = <String, String>{
        for (var i = 0; i < headers.length && i < values.length; i++) headers[i]: values[i],
      };
      nodos.add(Nodo(
        id: int.tryParse(row['id'] ?? ''),
        nombre: row['nombre'] ?? '',
        tipo: row['tipo'] ?? Nodo.tipos.first,
        valor: double.tryParse(row['valor'] ?? '') ?? 0,
        fechaRegistro: DateTime.tryParse(row['fecha_registro'] ?? '') ?? DateTime.now(),
        ubicacion: row['ubicacion_nodo'],
      ));
    }
    return CsvImportResult(nodos: nodos, checksum: actual);
  }

  /// Solo para la demostración: cambia el valor del primer registro
  /// SIN actualizar el checksum, como si alguien editara el archivo a mano.
  Future<void> tamperForDemo() async {
    final f = await file();
    if (!await f.exists()) throw const CsvIntegrityException('No existe el archivo CSV. Exporta primero.');
    final lines = (await f.readAsString()).split('\n');
    if (lines.length < 3) throw const CsvIntegrityException('El CSV no tiene registros para alterar.');
    final fields = _parseLine(lines[2]); // [0]=checksum, [1]=encabezados, [2]=primer registro
    fields[3] = fields[3] == '999.9' ? '111.1' : '999.9';
    lines[2] = fields.map(_escape).join(',');
    await f.writeAsString(lines.join('\n'), flush: true);
  }

  /// Primeras líneas del archivo, para mostrarlas en pantalla.
  Future<String> preview({int maxLines = 4}) async {
    final f = await file();
    if (!await f.exists()) return '';
    return (await f.readAsLines()).take(maxLines).join('\n');
  }

  // ---------------------------------------------------------------------------
  // Utilidades CSV
  // ---------------------------------------------------------------------------

  static String _short(String hash) => hash.length > 16 ? '${hash.substring(0, 16)}…' : hash;

  static String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static List<String> _parseLine(String line) {
    final result = <String>[];
    final current = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (inQuotes) {
        if (c == '"' && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else if (c == '"') {
          inQuotes = false;
        } else {
          current.write(c);
        }
      } else if (c == '"') {
        inQuotes = true;
      } else if (c == ',') {
        result.add(current.toString());
        current.clear();
      } else if (c != '\r') {
        current.write(c);
      }
    }
    result.add(current.toString());
    return result;
  }
}
