import 'package:flutter/material.dart';

import '../data/csv_node_manager.dart';
import '../data/database_helper.dart';
import '../data/json_manager.dart';
import '../utils/storage.dart';
import 'widgets.dart';

/// Módulo de archivos: JSON y CSV con checksum SHA-256.
class ArchivosPage extends StatefulWidget {
  const ArchivosPage({super.key});

  @override
  State<ArchivosPage> createState() => _ArchivosPageState();
}

class _ArchivosPageState extends State<ArchivosPage> {
  final _db = DatabaseHelper.instance;
  final _json = JsonManager();
  final _csv = CsvNodeManager();

  String _dirPath = '';
  bool _busy = false;

  String? _jsonMsg;
  bool _jsonOk = true;
  String? _csvMsg;
  bool _csvOk = true;
  String _csvPreview = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _db.database; // asegura que se conozcan las columnas
    final dir = await appFilesDir();
    final preview = await _csv.preview();
    if (!mounted) return;
    setState(() {
      _dirPath = dir.path;
      _csvPreview = preview;
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ----------------------------- JSON -----------------------------

  Future<void> _exportJson() => _run(() async {
        final nodos = await _db.getAll();
        final f = await _json.export(nodos, dbVersion: kDbVersion, includeUbicacion: _db.hasUbicacion);
        setState(() {
          _jsonOk = true;
          _jsonMsg = 'Se escribieron ${nodos.length} nodos en:\n${f.path}';
        });
      });

  Future<void> _readJson() => _run(() async {
        try {
          final r = await _json.readAndVerify();
          final sample = r.nodos.take(3).map((n) => '• ${n.nombre} (${n.tipo}: ${n.valor})').join('\n');
          setState(() {
            _jsonOk = r.isValid;
            _jsonMsg = '${r.isValid ? 'Archivo verificado' : 'Archivo inconsistente'}: '
                'declara ${r.declaredTotal} nodos y se leyeron ${r.nodos.length}.\n'
                'Tamaño: ${formatBytes(r.sizeBytes)} · Generado: ${r.generatedAt.substring(0, 19)}'
                '${sample.isEmpty ? '' : '\n$sample'}';
          });
        } catch (e) {
          setState(() {
            _jsonOk = false;
            _jsonMsg = 'No se pudo leer el JSON: $e';
          });
        }
      });

  // ----------------------------- CSV ------------------------------

  Future<void> _exportCsv() => _run(() async {
        final nodos = await _db.getAll();
        final r = await _csv.export(nodos, includeUbicacion: _db.hasUbicacion);
        final preview = await _csv.preview();
        setState(() {
          _csvOk = true;
          _csvMsg = 'Exportados ${r.rows} nodos con firma SHA-256:\n${r.checksum}';
          _csvPreview = preview;
        });
      });

  Future<void> _importCsv() => _run(() async {
        try {
          final r = await _csv.importVerified();
          final time = await _db.insertMany(r.nodos, keepIds: true);
          setState(() {
            _csvOk = true;
            _csvMsg = 'Checksum válido. Se importaron ${r.nodos.length} nodos '
                'en una transacción por lote (${time.inMilliseconds} ms).';
          });
        } on CsvIntegrityException catch (e) {
          setState(() {
            _csvOk = false;
            _csvMsg = e.message;
          });
        }
      });

  Future<void> _tamperCsv() => _run(() async {
        try {
          await _csv.tamperForDemo();
          final preview = await _csv.preview();
          setState(() {
            _csvOk = false;
            _csvMsg = 'Se modificó el valor del primer registro sin actualizar el checksum. '
                'Ahora presiona "Importar y verificar": el archivo debe ser rechazado.';
            _csvPreview = preview;
          });
        } on CsvIntegrityException catch (e) {
          setState(() {
            _csvOk = false;
            _csvMsg = e.message;
          });
        }
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archivos JSON y CSV')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_busy) const LinearProgressIndicator(),
          ModuleCard(
            icon: Icons.folder_open,
            title: 'Directorio asignado',
            children: [
              const Text('Aquí se guardan nodos.json y nodos.csv:'),
              MonoBox(_dirPath.isEmpty ? 'Cargando…' : _dirPath),
            ],
          ),
          const SizedBox(height: 12),
          ModuleCard(
            icon: Icons.data_object,
            title: 'JSON: escribir, leer y verificar',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : _exportJson,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Escribir JSON'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _readJson,
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Leer y verificar'),
                  ),
                ],
              ),
              if (_jsonMsg != null) StatusBox(message: _jsonMsg!, ok: _jsonOk),
            ],
          ),
          const SizedBox(height: 12),
          ModuleCard(
            icon: Icons.table_chart_outlined,
            title: 'CSV con checksum SHA-256',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : _exportCsv,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Exportar CSV'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _importCsv,
                    icon: const Icon(Icons.download),
                    label: const Text('Importar y verificar'),
                  ),
                  TextButton.icon(
                    onPressed: _busy ? null : _tamperCsv,
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Alterar archivo (prueba)'),
                  ),
                ],
              ),
              if (_csvMsg != null) StatusBox(message: _csvMsg!, ok: _csvOk),
              if (_csvPreview.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Primeras líneas de nodos.csv:'),
                MonoBox(_csvPreview),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
