/// Un nodo de sensado (por ejemplo, un sensor de un sistema IoT).
class Nodo {
  const Nodo({
    this.id,
    required this.nombre,
    required this.tipo,
    required this.valor,
    required this.fechaRegistro,
    this.ubicacion,
  });

  final int? id;
  final String nombre;
  final String tipo;
  final double valor;
  final DateTime fechaRegistro;

  /// Columna `ubicacion_nodo`: solo existe a partir de la versión 2 de la BD.
  final String? ubicacion;

  static const List<String> tipos = ['Temperatura', 'Humedad', 'Luz', 'Presión'];

  static const Map<String, String> unidades = {
    'Temperatura': '°C',
    'Humedad': '%',
    'Luz': 'lx',
    'Presión': 'hPa',
  };

  String get unidad => unidades[tipo] ?? '';

  /// Convierte a mapa para SQLite / JSON / CSV.
  /// [includeUbicacion] es false mientras la BD siga en la versión 1.
  Map<String, Object?> toMap({bool includeId = true, bool includeUbicacion = true}) => {
        if (includeId && id != null) 'id': id,
        'nombre': nombre,
        'tipo': tipo,
        'valor': valor,
        'fecha_registro': fechaRegistro.toIso8601String(),
        if (includeUbicacion) 'ubicacion_nodo': ubicacion ?? 'Sin asignar',
      };

  factory Nodo.fromMap(Map<String, Object?> map) => Nodo(
        id: map['id'] as int?,
        nombre: map['nombre'] as String,
        tipo: map['tipo'] as String,
        valor: (map['valor'] as num).toDouble(),
        fechaRegistro: DateTime.parse(map['fecha_registro'] as String),
        ubicacion: map['ubicacion_nodo'] as String?,
      );

  Nodo copyWith({int? id, String? nombre, String? tipo, double? valor, String? ubicacion}) => Nodo(
        id: id ?? this.id,
        nombre: nombre ?? this.nombre,
        tipo: tipo ?? this.tipo,
        valor: valor ?? this.valor,
        fechaRegistro: fechaRegistro,
        ubicacion: ubicacion ?? this.ubicacion,
      );
}
