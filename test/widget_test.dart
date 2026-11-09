import 'package:crud_nodos/data/csv_node_manager.dart';
import 'package:crud_nodos/models/nodo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SHA-256 conocido', () {
    expect(
      CsvNodeManager.sha256Of('abc'),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });

  test('Un cambio mínimo produce un checksum distinto', () {
    expect(CsvNodeManager.sha256Of('1,Nodo,Luz,10.0'), isNot(CsvNodeManager.sha256Of('1,Nodo,Luz,10.1')));
  });

  test('Nodo ida y vuelta por mapa', () {
    final n = Nodo(id: 1, nombre: 'N1', tipo: 'Luz', valor: 3.5, fechaRegistro: DateTime(2026, 11, 8), ubicacion: 'Bodega');
    final copia = Nodo.fromMap(n.toMap());
    expect(copia.nombre, 'N1');
    expect(copia.ubicacion, 'Bodega');
  });
}
