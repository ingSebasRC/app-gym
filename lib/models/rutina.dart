class Rutina {
  final String id;
  final String nombre;
  final List<String> ejercicios;

  Rutina({
    required this.id,
    required this.nombre,
    required this.ejercicios,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }

  factory Rutina.fromMap(Map<String, dynamic> map, List<String> ejercicios) {
    return Rutina(
      id: map['id'],
      nombre: map['nombre'],
      ejercicios: ejercicios,
    );
  }
}
