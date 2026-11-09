import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/database_helper.dart';
import '../models/nodo.dart';

/// Formulario para crear (CREATE) o editar (UPDATE) un nodo.
class NodoFormScreen extends StatefulWidget {
  const NodoFormScreen({super.key, this.nodo});

  final Nodo? nodo;

  @override
  State<NodoFormScreen> createState() => _NodoFormScreenState();
}

class _NodoFormScreenState extends State<NodoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper.instance;
  late final _nombre = TextEditingController(text: widget.nodo?.nombre ?? '');
  late final _valor = TextEditingController(text: widget.nodo?.valor.toString() ?? '');
  late final _ubicacion = TextEditingController(text: widget.nodo?.ubicacion ?? '');
  late String _tipo = widget.nodo?.tipo ?? Nodo.tipos.first;
  bool _saving = false;

  bool get _isEdit => widget.nodo != null;

  @override
  void dispose() {
    _nombre.dispose();
    _valor.dispose();
    _ubicacion.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ubicacion = _ubicacion.text.trim();
    final nodo = Nodo(
      id: widget.nodo?.id,
      nombre: _nombre.text.trim(),
      tipo: _tipo,
      valor: double.parse(_valor.text),
      fechaRegistro: widget.nodo?.fechaRegistro ?? DateTime.now(),
      ubicacion: ubicacion.isEmpty ? null : ubicacion,
    );
    if (_isEdit) {
      await _db.update(nodo);
    } else {
      await _db.insert(nodo);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Editar nodo #${widget.nodo!.id}' : 'Nuevo nodo')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe un nombre' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo de sensor', border: OutlineInputBorder()),
              items: [for (final t in Nodo.tipos) DropdownMenuItem(value: t, child: Text(t))],
              onChanged: (v) => setState(() => _tipo = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valor,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]'))],
              decoration: InputDecoration(
                labelText: 'Valor',
                suffixText: Nodo.unidades[_tipo],
                border: const OutlineInputBorder(),
              ),
              validator: (v) => double.tryParse(v ?? '') == null ? 'Escribe un número válido' : null,
            ),
            // El campo solo aparece cuando la BD ya está en la versión 2.
            if (_db.hasUbicacion) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _ubicacion,
                decoration: const InputDecoration(
                  labelText: 'Ubicación del nodo',
                  hintText: 'Ej. Invernadero A',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(_isEdit ? 'Guardar cambios' : 'Agregar nodo'),
            ),
          ],
        ),
      ),
    );
  }
}
