import 'dart:math';

import '../models/nodo.dart';

const List<String> kUbicaciones = [
  'Invernadero A',
  'Invernadero B',
  'Bodega',
  'Laboratorio',
  'Parcela Norte',
];

/// Genera [cantidad] nodos con datos aleatorios para la inserción masiva.
List<Nodo> generarNodos(int cantidad, {required bool conUbicacion, int desde = 1}) {
  final random = Random();
  final ahora = DateTime.now();
  return List.generate(cantidad, (i) {
    final tipo = Nodo.tipos[random.nextInt(Nodo.tipos.length)];
    final valor = switch (tipo) {
      'Temperatura' => 15 + random.nextDouble() * 20,
      'Humedad' => 30 + random.nextDouble() * 60,
      'Luz' => random.nextDouble() * 1000,
      _ => 980 + random.nextDouble() * 50,
    };
    return Nodo(
      nombre: 'Nodo-${(desde + i).toString().padLeft(4, '0')}',
      tipo: tipo,
      valor: double.parse(valor.toStringAsFixed(1)),
      fechaRegistro: ahora.subtract(Duration(minutes: random.nextInt(60 * 24 * 7))),
      ubicacion: conUbicacion ? kUbicaciones[random.nextInt(kUbicaciones.length)] : null,
    );
  });
}
