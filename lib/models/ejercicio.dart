class Ejercicio {
  final String id;
  String nombre;
  double peso;
  int repeticiones;
  int series;
  int dia;
  String? detalles;
  DateTime fecha;

  Ejercicio({
    required this.id,
    required this.nombre,
    required this.peso,
    required this.repeticiones,
    this.series = 1,
    required this.dia,
    this.detalles,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'peso': peso,
      'repeticiones': repeticiones,
      'series': series,
      'dia': dia,
      'detalles': detalles,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory Ejercicio.fromMap(Map<String, dynamic> map) {
    return Ejercicio(
      id: map['id'],
      nombre: map['nombre'],
      peso: (map['peso'] as num).toDouble(),
      repeticiones: map['repeticiones'],
      series: map['series'],
      dia: map['dia'],
      detalles: map['detalles'],
      fecha: map['fecha'] != null 
          ? DateTime.parse(map['fecha']) 
          : DateTime.fromMillisecondsSinceEpoch(int.tryParse(map['id']) ?? DateTime.now().millisecondsSinceEpoch),
    );
  }
}
