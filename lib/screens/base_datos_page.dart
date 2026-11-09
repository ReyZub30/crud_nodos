import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../utils/sample_data.dart';
import 'widgets.dart';

/// Módulo de base de datos: versión del esquema, migración e inserción masiva.
class BaseDatosPage extends StatefulWidget {
  const BaseDatosPage({super.key});

  @override
  State<BaseDatosPage> createState() => _BaseDatosPageState();
}

class _BaseDatosPageState extends State<BaseDatosPage> {
  final _db = DatabaseHelper.instance;
  int _count = 0;
  int _cantidad = 1000;
  bool _inserting = false;
  String? _batchMsg;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final count = await _db.count();
    if (mounted) setState(() => _count = count);
  }

  Future<void> _insertBatch() async {
    setState(() {
      _inserting = true;
      _batchMsg = null;
    });
    final nodos = generarNodos(_cantidad, conUbicacion: _db.hasUbicacion, desde: _count + 1);
    final time = await _db.insertMany(nodos);
    await _refresh();
    if (!mounted) return;
    setState(() {
      _inserting = false;
      _batchMsg = 'Se insertaron $_cantidad nodos en una sola transacción con batch '
          'en ${time.inMilliseconds} ms. La interfaz siguió respondiendo durante la operación.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Base de datos')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ModuleCard(
              icon: Icons.info_outline,
              title: 'Estado del esquema',
              children: [
                Row(
                  children: [
                    Chip(
                      avatar: const Icon(Icons.layers, size: 18),
                      label: Text('Versión v$kDbVersion'),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      avatar: const Icon(Icons.dataset_outlined, size: 18),
                      label: Text('$_count registros'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Columnas de la tabla "nodos":', style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in _db.columns)
                      Chip(
                        label: Text(c),
                        backgroundColor: c == 'ubicacion_nodo' ? theme.colorScheme.tertiaryContainer : null,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                StatusBox(message: _db.log, ok: true),
                const SizedBox(height: 8),
                Text('Ruta de la base de datos:', style: theme.textTheme.labelLarge),
                MonoBox(_db.path),
              ],
            ),
            const SizedBox(height: 12),
            ModuleCard(
              icon: Icons.bolt,
              title: 'Inserción masiva (transacción + batch)',
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 100, label: Text('100')),
                    ButtonSegment(value: 1000, label: Text('1,000')),
                    ButtonSegment(value: 5000, label: Text('5,000')),
                  ],
                  selected: {_cantidad},
                  onSelectionChanged: _inserting ? null : (s) => setState(() => _cantidad = s.first),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _inserting ? null : _insertBatch,
                  icon: _inserting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.playlist_add),
                  label: Text(_inserting ? 'Insertando…' : 'Insertar $_cantidad nodos en lote'),
                ),
                if (_inserting) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                if (_batchMsg != null) StatusBox(message: _batchMsg!, ok: true),
              ],
            ),
            const SizedBox(height: 12),
            ModuleCard(
              icon: Icons.upgrade,
              title: 'Cómo probar la migración v1 → v2',
              children: const [
                Text(
                  '1. Con kDbVersion = 1, agrega o genera nodos.\n'
                  '2. En lib/data/database_helper.dart cambia kDbVersion a 2 y guarda.\n'
                  '3. Presiona R en la terminal (hot restart).\n'
                  '4. Aquí verás la versión v2, la nueva columna ubicacion_nodo '
                  'y el mismo número de registros.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
