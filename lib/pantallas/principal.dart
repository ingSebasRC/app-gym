import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db/database_helper.dart';
import '../models/ejercicio_maestro.dart';
import 'detalle_ejercicio.dart';

class Ejercicio {
  final String id;
  String nombre;
  double peso;
  int repeticiones;
  int series;
  int dia;
  String? detalles;

  Ejercicio({
    required this.id,
    required this.nombre,
    required this.peso,
    required this.repeticiones,
    this.series = 1,
    required this.dia,
    this.detalles,
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
    );
  }
}

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal>
    with TickerProviderStateMixin {
  late int _diaSeleccionado;
  late AnimationController _headerAnimController;
  late AnimationController _fabAnimController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _fabScale;

  final Map<int, List<Ejercicio>> _ejerciciosPorDia = {};

  static const List<String> _diasCompletos = [
    'LUNES', 'MARTES', 'MIÉRCOLES', 'JUEVES', 'VIERNES', 'SÁBADO', 'DOMINGO'
  ];
  static const List<String> _diasCortos = [
    'LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'
  ];
  static const List<String> _meses = [
    'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO',
    'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE'
  ];

  String _obtenerFechaCompleta(int indexDia) {
    final ahora = DateTime.now();
    final lunesDeEstaSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
    final fechaSeleccionada = lunesDeEstaSemana.add(Duration(days: indexDia));
    
    return '${_diasCompletos[indexDia]} ${fechaSeleccionada.day} ${_meses[fechaSeleccionada.month - 1]} ${fechaSeleccionada.year}';
  }

  @override
  void initState() {
    super.initState();
    _diaSeleccionado = (DateTime.now().weekday - 1).clamp(0, 6);

    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOutCubic),
    );
    _fabScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimController, curve: Curves.elasticOut),
    );

    _cargarEjercicios();
    _headerAnimController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fabAnimController.forward();
    });
  }

  Future<void> _cargarEjercicios() async {
    final data = await DatabaseHelper.instance.readAllByDia(_diaSeleccionado);
    setState(() {
      _ejerciciosPorDia[_diaSeleccionado] = data;
    });
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  List<Ejercicio> get _ejerciciosHoy =>
      _ejerciciosPorDia[_diaSeleccionado] ?? [];

  void _cambiarDia(int nuevoDia) {
    if (nuevoDia == _diaSeleccionado) return;
    HapticFeedback.selectionClick();
    _headerAnimController.forward(from: 0);
    setState(() => _diaSeleccionado = nuevoDia);
    _cargarEjercicios();
  }

  void _abrirModalAgregar() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalSeleccionarEjercicio(
        onSeleccionado: (nombre) async {
          final nuevoEjercicio = Ejercicio(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            nombre: nombre,
            peso: 0,
            repeticiones: 0,
            series: 0,
            dia: _diaSeleccionado,
          );
          await DatabaseHelper.instance.insert(nuevoEjercicio);
          _cargarEjercicios();
        },
      ),
    );
  }

  Future<void> _abrirModalEditar(Ejercicio ejercicio) async {
    HapticFeedback.mediumImpact();
    final bool? actualizado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaDetalleEjercicio(ejercicio: ejercicio),
      ),
    );

    if (actualizado == true) {
      _cargarEjercicios();
    }
  }

  void _eliminarEjercicio(String id) async {
    HapticFeedback.heavyImpact();
    await DatabaseHelper.instance.delete(id);
    _cargarEjercicios();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSelectorDias(),
            const SizedBox(height: 8),
            Expanded(child: _buildListaEjercicios()),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton(
          onPressed: _abrirModalAgregar,
          backgroundColor: const Color(0xFFE8FF00),
          child: const Icon(Icons.add, size: 28, color: Color(0xFF0A0A0A)),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerFade,
      child: SlideTransition(
        position: _headerSlide,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8FF00),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'IRONLOG',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      letterSpacing: 3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _obtenerFechaCompleta(_diaSeleccionado),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _ejerciciosHoy.isEmpty
                    ? 'Sin ejercicios aún'
                    : '${_ejerciciosHoy.length} ejercicio${_ejerciciosHoy.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                height: 1,
                color: const Color(0xFF1E1E1E),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorDias() {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: 7,
        itemBuilder: (context, index) {
          final bool activo = index == _diaSeleccionado;
          final bool hoy = index == (DateTime.now().weekday - 1).clamp(0, 6);
          return GestureDetector(
            onTap: () => _cambiarDia(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: activo
                    ? const Color(0xFFE8FF00)
                    : const Color(0xFF161616),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hoy && !activo
                      ? const Color(0xFFE8FF00).withOpacity(0.3)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _diasCortos[index],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: activo
                      ? const Color(0xFF0A0A0A)
                      : const Color(0xFF666666),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListaEjercicios() {
    if (_ejerciciosHoy.isEmpty) {
      return _buildEstadoVacio();
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      itemCount: _ejerciciosHoy.length,
      itemBuilder: (context, index) {
        final ejercicio = _ejerciciosHoy[index];
        return _TarjetaEjercicio(
          ejercicio: ejercicio,
          index: index,
          onEliminar: () => _eliminarEjercicio(ejercicio.id),
          onTap: () => _abrirModalEditar(ejercicio),
        );
      },
    );
  }

  Widget _buildEstadoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: Color(0xFF333333),
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'NADA POR AQUÍ',
            style: TextStyle(
              color: Color(0xFF333333),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toca + para agregar tu primer\nejercicio del día',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF333333),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaEjercicio extends StatefulWidget {
  final Ejercicio ejercicio;
  final int index;
  final VoidCallback onEliminar;
  final VoidCallback onTap;

  const _TarjetaEjercicio({
    required this.ejercicio,
    required this.index,
    required this.onEliminar,
    required this.onTap,
  });

  @override
  State<_TarjetaEjercicio> createState() => _TarjetaEjercicioState();
}

class _TarjetaEjercicioState extends State<_TarjetaEjercicio>
    with SingleTickerProviderStateMixin {
  late AnimationController _entradaController;
  late Animation<double> _entradaFade;
  late Animation<Offset> _entradaSlide;

  @override
  void initState() {
    super.initState();
    _entradaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entradaFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entradaController, curve: Curves.easeOut),
    );
    _entradaSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entradaController, curve: Curves.easeOutCubic),
    );

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _entradaController.forward();
    });
  }

  @override
  void dispose() {
    _entradaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entradaFade,
      child: SlideTransition(
        position: _entradaSlide,
        child: Dismissible(
          key: Key(widget.ejercicio.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0000),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(Icons.delete_outline, color: Color(0xFFFF4444), size: 22),
          ),
          onDismissed: (_) => widget.onEliminar(),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E1E1E)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.index + 1}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF555555)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.ejercicio.nombre.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _Chip(label: '${widget.ejercicio.peso} kg'),
                            const SizedBox(width: 8),
                            _Chip(label: '${widget.ejercicio.repeticiones} reps'),
                            const SizedBox(width: 8),
                            _Chip(label: '${widget.ejercicio.series} series', accent: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.drag_indicator_rounded, color: Color(0xFF2A2A2A), size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool accent;
  const _Chip({required this.label, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent ? const Color(0xFFE8FF00).withOpacity(0.08) : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent ? const Color(0xFFE8FF00).withOpacity(0.2) : Colors.transparent),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: accent ? const Color(0xFFE8FF00) : const Color(0xFF888888),
        ),
      ),
    );
  }
}

class _ModalSeleccionarEjercicio extends StatefulWidget {
  final Function(String) onSeleccionado;
  const _ModalSeleccionarEjercicio({required this.onSeleccionado});

  @override
  State<_ModalSeleccionarEjercicio> createState() => _ModalSeleccionarEjercicioState();
}

class _ModalSeleccionarEjercicioState extends State<_ModalSeleccionarEjercicio> {
  String? _grupoSeleccionado;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _mostrarDialogoNuevoEjercicio() {
    String nuevoNombre = '';
    String grupoSeleccionado = 'Pecho';
    final grupos = ['Pecho', 'Espalda', 'Hombro', 'Tríceps', 'Bíceps', 'Pierna', 'Abs'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF111111),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF1E1E1E))),
          title: const Text('NUEVO EJERCICIO', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                onChanged: (v) => nuevoNombre = v,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nombre del ejercicio...',
                  hintStyle: const TextStyle(color: Color(0xFF444444)),
                  filled: true,
                  fillColor: const Color(0xFF0A0A0A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              const Text('GRUPO MUSCULAR', style: TextStyle(color: Color(0xFF888888), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: grupoSeleccionado,
                    dropdownColor: const Color(0xFF111111),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    items: grupos.map((g) => DropdownMenuItem(value: g, child: Text(g.toUpperCase(), style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (v) => setDialogState(() => grupoSeleccionado = v!),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR', style: TextStyle(color: Color(0xFF555555), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nuevoNombre.trim().isNotEmpty) {
                  widget.onSeleccionado(nuevoNombre.trim());
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8FF00),
                foregroundColor: const Color(0xFF0A0A0A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('AGREGAR', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<EjercicioMaestro>> agrupados = {};
    for (var e in LISTA_EJERCICIOS_MAESTRA) {
      agrupados.putIfAbsent(e.grupoMuscular, () => []).add(e);
    }

    // Filtrar ejercicios si hay búsqueda
    List<EjercicioMaestro> filtrados = [];
    if (_searchQuery.isNotEmpty) {
      filtrados = LISTA_EJERCICIOS_MAESTRA
          .where((e) => e.nombre.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              width: 36, height: 4,
              decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          
          // Buscador y Botón Agregar
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'BUSCAR EJERCICIO...',
                      hintStyle: TextStyle(color: const Color(0xFF555555), fontSize: 12, letterSpacing: 1.5),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: const Color(0xFFE8FF00).withOpacity(0.5), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFF555555), size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _mostrarDialogoNuevoEjercicio,
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8FF00).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8FF00).withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.add, color: Color(0xFFE8FF00), size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_searchQuery.isEmpty) ...[
            Row(
              children: [
                if (_grupoSeleccionado != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFE8FF00), size: 18),
                    onPressed: () => setState(() => _grupoSeleccionado = null),
                  ),
                Text(
                  _grupoSeleccionado == null ? 'GRUPO MUSCULAR' : _grupoSeleccionado!.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          Flexible(
            child: _searchQuery.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtrados.length,
                    itemBuilder: (context, i) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(filtrados[i].nombre, style: const TextStyle(color: Color(0xFFCCCCCC))),
                      subtitle: Text(filtrados[i].grupoMuscular.toUpperCase(), style: const TextStyle(color: Color(0xFF555555), fontSize: 10, fontWeight: FontWeight.bold)),
                      onTap: () {
                        widget.onSeleccionado(filtrados[i].nombre);
                        Navigator.pop(context);
                      },
                    ),
                  )
                : _grupoSeleccionado == null
                    ? ListView(
                        shrinkWrap: true,
                        children: agrupados.keys.map((g) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(g.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.chevron_right, color: Color(0xFF333333)),
                          onTap: () => setState(() => _grupoSeleccionado = g),
                        )).toList(),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: agrupados[_grupoSeleccionado]!.map((e) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(e.nombre, style: const TextStyle(color: Color(0xFFCCCCCC))),
                          onTap: () {
                            widget.onSeleccionado(e.nombre);
                            Navigator.pop(context);
                          },
                        )).toList(),
                      ),
          ),
        ],
      ),
    );
  }
}