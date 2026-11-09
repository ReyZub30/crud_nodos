import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/nodo.dart';
import '../utils/storage.dart';
import 'nodo_form_screen.dart';

/// Módulo CRUD: lista, alta, edición y borrado de nodos.
class NodosPage extends StatefulWidget {
  const NodosPage({super.key});

  @override
  State<NodosPage> createState() => _NodosPageState();
}

class _NodosPageState extends State<NodosPage> {
  final _db = DatabaseHelper.instance;
  List<Nodo> _nodos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final nodos = await _db.getAll();
    if (!mounted) return;
    setState(() {
      _nodos = nodos;
      _loading = false;
    });
  }

  Future<void> _openForm([Nodo? nodo]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NodoFormScreen(nodo: nodo)),
    );
    if (saved == true) _load();
  }

  Future<bool> _confirm(String title, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _deleteAll() async {
    if (_nodos.isEmpty) return;
    if (!await _confirm('Eliminar todo', '¿Borrar los ${_nodos.length} nodos?')) return;
    await _db.deleteAll();
    _load();
  }

  IconData _icon(String tipo) => switch (tipo) {
        'Temperatura' => Icons.thermostat,
        'Humedad' => Icons.water_drop_outlined,
        'Luz' => Icons.light_mode_outlined,
        _ => Icons.speed,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Nodos (${_nodos.length})'),
        actions: [
          IconButton(
            tooltip: 'Eliminar todos',
            onPressed: _nodos.isEmpty ? null : _deleteAll,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _nodos.isEmpty
              ? const _EmptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: _nodos.length,
                    itemBuilder: (context, i) {
                      final n = _nodos[i];
                      return Dismissible(
                        key: ValueKey(n.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: scheme.errorContainer,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Icon(Icons.delete, color: scheme.onErrorContainer),
                        ),
                        confirmDismiss: (_) => _confirm('Eliminar nodo', '¿Borrar "${n.nombre}"?'),
                        onDismissed: (_) async {
                          await _db.delete(n.id!);
                          setState(() => _nodos.removeWhere((x) => x.id == n.id));
                        },
                        child: ListTile(
                          leading: CircleAvatar(child: Icon(_icon(n.tipo))),
                          title: Text(n.nombre),
                          subtitle: Text([
                            '${n.tipo}: ${n.valor} ${n.unidad}',
                            if (_db.hasUbicacion) '📍 ${n.ubicacion ?? 'Sin asignar'}',
                            formatDate(n.fechaRegistro),
                          ].join('\n')),
                          isThreeLine: true,
                          trailing: Text('#${n.id}', style: Theme.of(context).textTheme.labelSmall),
                          onTap: () => _openForm(n),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sensors_off, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            const Text('No hay nodos registrados.', textAlign: TextAlign.center),
            const SizedBox(height: 4),
            const Text(
              'Agrega uno con "Nuevo" o genera muchos en la pestaña Base de datos.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
