import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db/database_helper.dart';
import '../models/ejercicio_maestro.dart';
import '../models/ejercicio.dart';
import '../services/settings_service.dart';
import 'detalle_ejercicio.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal>
    with TickerProviderStateMixin {
  late DateTime _fechaSeleccionada;
  late AnimationController _headerAnimController;
  late AnimationController _fabAnimController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _fabScale;
  String _unit = 'kg';

  final Map<String, List<Ejercicio>> _ejerciciosCache = {};

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

  String _formatearFecha(DateTime fecha) {
    return '${_diasCompletos[fecha.weekday - 1]} ${fecha.day} ${_meses[fecha.month - 1]} ${fecha.year}';
  }

  @override
  void initState() {
    super.initState();
    _fechaSeleccionada = DateTime.now();

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

    _cargarConfig();
    _cargarEjercicios();
    _headerAnimController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fabAnimController.forward();
    });
  }

  Future<void> _cargarConfig() async {
    final unit = await SettingsService.instance.getUnit();
    if (mounted) setState(() => _unit = unit);
  }

  Future<void> _cargarEjercicios() async {
    final data = await DatabaseHelper.instance.readAllByFecha(_fechaSeleccionada);
    if (mounted) {
      setState(() {
        _ejerciciosCache[_fechaSeleccionada.toIso8601String().split('T')[0]] = data;
      });
    }
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  List<Ejercicio> get _ejerciciosHoy =>
      _ejerciciosCache[_fechaSeleccionada.toIso8601String().split('T')[0]] ?? [];

  void _cambiarFecha(DateTime nuevaFecha) {
    if (DateUtils.isSameDay(nuevaFecha, _fechaSeleccionada)) return;
    HapticFeedback.selectionClick();
    _headerAnimController.forward(from: 0);
    setState(() => _fechaSeleccionada = nuevaFecha);
    _cargarEjercicios();
  }

  void _cambiarSemana(int delta) {
    _cambiarFecha(_fechaSeleccionada.add(Duration(days: delta * 7)));
  }

  void _toggleUnit() async {
    final newUnit = _unit == 'kg' ? 'lb' : 'kg';
    await SettingsService.instance.setUnit(newUnit);
    setState(() => _unit = newUnit);
    HapticFeedback.mediumImpact();
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
            dia: _fechaSeleccionada.weekday - 1,
            fecha: _fechaSeleccionada,
          );
          await DatabaseHelper.instance.insert(nuevoEjercicio);
          _cargarEjercicios();
        },
      ),
    );
  }

  void _abrirModalRutinas() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ModalGestionarRutinas(
        soloGestion: false,
        onImportar: (ejercicios) async {
          for (var nombre in ejercicios) {
            final nuevo = Ejercicio(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              nombre: nombre,
              peso: 0,
              repeticiones: 0,
              series: 0,
              dia: _fechaSeleccionada.weekday - 1,
              fecha: _fechaSeleccionada,
            );
            await DatabaseHelper.instance.insert(nuevo);
            await Future.delayed(const Duration(milliseconds: 1));
          }
          _cargarEjercicios();
        },
      ),
    );
  }

  void _abrirModalGestionarRutinas() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ModalGestionarRutinas(
        soloGestion: true,
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
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity! > 0) {
                    _cambiarFecha(_fechaSeleccionada.subtract(const Duration(days: 1)));
                  } else if (details.primaryVelocity! < 0) {
                    _cambiarFecha(_fechaSeleccionada.add(const Duration(days: 1)));
                  }
                },
                child: _buildListaEjercicios(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'import_routine',
                onPressed: _abrirModalRutinas,
                backgroundColor: const Color(0xFF161616),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: const Color(0xFFE8FF00).withOpacity(0.3)),
                ),
                label: const Text(
                  'IMPORTAR',
                  style: TextStyle(
                    color: Color(0xFFE8FF00),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                icon: const Icon(Icons.download_rounded, color: Color(0xFFE8FF00), size: 20),
              ),
              const SizedBox(width: 12),
              FloatingActionButton(
                heroTag: 'add_exercise',
                onPressed: _abrirModalAgregar,
                backgroundColor: const Color(0xFFE8FF00),
                child: const Icon(Icons.add, size: 28, color: Color(0xFF0A0A0A)),
              ),
            ],
          ),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Row(
                    children: [
                      _buildBotonAccion(
                        icon: Icons.assignment_rounded,
                        label: 'RUTINAS',
                        onTap: _abrirModalGestionarRutinas,
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _toggleUnit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161616),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF2A2A2A)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _unit.toUpperCase(),
                                style: const TextStyle(color: Color(0xFFE8FF00), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.swap_horiz, color: Color(0xFF444444), size: 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _formatearFecha(_fechaSeleccionada),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Color(0xFFE8FF00)),
                        onPressed: () => _cambiarSemana(-1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: Color(0xFFE8FF00)),
                        onPressed: () => _cambiarSemana(1),
                      ),
                    ],
                  ),
                ],
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

  Widget _buildBotonAccion({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE8FF00).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8FF00).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFE8FF00), size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Color(0xFFE8FF00), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorDias() {
    final lunes = _fechaSeleccionada.subtract(Duration(days: _fechaSeleccionada.weekday - 1));
    
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: 7,
        itemBuilder: (context, index) {
          final dia = lunes.add(Duration(days: index));
          final bool activo = DateUtils.isSameDay(dia, _fechaSeleccionada);
          final bool hoy = DateUtils.isSameDay(dia, DateTime.now());
          
          return GestureDetector(
            onTap: () => _cambiarFecha(dia),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _diasCortos[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: activo
                          ? const Color(0xFF0A0A0A)
                          : const Color(0xFF666666),
                    ),
                  ),
                  Text(
                    '${dia.day}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: activo
                          ? const Color(0xFF0A0A0A)
                          : const Color(0xFF444444),
                    ),
                  ),
                ],
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
          unit: _unit,
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
            'Toca + para agregar un ejercicio\no usa una RUTINA para importar varias',
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
  final String unit;
  final VoidCallback onEliminar;
  final VoidCallback onTap;

  const _TarjetaEjercicio({
    required this.ejercicio,
    required this.index,
    required this.unit,
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
                            _Chip(label: '${widget.ejercicio.peso} ${widget.unit}'),
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

class _ModalGestionarRutinas extends StatefulWidget {
  final bool soloGestion;
  final Function(List<String>)? onImportar;
  const _ModalGestionarRutinas({this.soloGestion = false, this.onImportar});

  @override
  State<_ModalGestionarRutinas> createState() => _ModalGestionarRutinasState();
}

class _ModalGestionarRutinasState extends State<_ModalGestionarRutinas> {
  List<Map<String, dynamic>> _rutinas = [];

  @override
  void initState() {
    super.initState();
    _cargarRutinas();
  }

  Future<void> _cargarRutinas() async {
    final data = await DatabaseHelper.instance.readAllRutinas();
    setState(() => _rutinas = data);
  }

  void _crearNuevaRutina() {
    String nombreRutina = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF1E1E1E))),
        title: const Text('NOMBRE DE LA RUTINA', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        content: TextField(
          onChanged: (v) => nombreRutina = v,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Ej: Upper Day, Pierna...',
            hintStyle: const TextStyle(color: Color(0xFF444444)),
            filled: true,
            fillColor: const Color(0xFF0A0A0A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Color(0xFF555555), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nombreRutina.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8FF00),
              foregroundColor: const Color(0xFF0A0A0A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('CONTINUAR', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    ).then((confirmado) {
      if (confirmado == true) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _ModalSeleccionarMultiplesEjercicios(
            titulo: nombreRutina.toUpperCase(),
            onFinalizar: (nombres) async {
              if (nombres.isEmpty) return;
              await DatabaseHelper.instance.insertRutina(nombreRutina.trim(), nombres);
              _cargarRutinas();
            },
          ),
        );
      }
    });
  }

  void _editarRutina(String id, String nombreActual) async {
    final actuales = await DatabaseHelper.instance.readEjerciciosByRutina(id);
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalSeleccionarMultiplesEjercicios(
        titulo: 'EDITAR: ${nombreActual.toUpperCase()}',
        seleccionadosIniciales: actuales,
        onFinalizar: (nuevos) async {
          await DatabaseHelper.instance.updateRutina(id, nuevos);
          _cargarRutinas();
        },
      ),
    );
  }

  void _eliminarRutina(String id) async {
    await DatabaseHelper.instance.deleteRutina(id);
    _cargarRutinas();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.soloGestion ? 'GESTIONAR RUTINAS' : 'IMPORTAR RUTINA',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
              if (widget.soloGestion)
                IconButton(onPressed: _crearNuevaRutina, icon: const Icon(Icons.add_circle, color: Color(0xFFE8FF00))),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _rutinas.isEmpty
              ? const Center(child: Text('No tienes rutinas creadas', style: TextStyle(color: Color(0xFF444444))))
              : ListView.builder(
                  itemCount: _rutinas.length,
                  itemBuilder: (context, i) {
                    final r = _rutinas[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161616),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: ListTile(
                        title: Text(r['nombre'].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.soloGestion)
                              IconButton(
                                icon: const Icon(Icons.edit_note_rounded, color: Color(0xFFE8FF00), size: 22),
                                onPressed: () => _editarRutina(r['id'], r['nombre']),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Color(0xFF444444), size: 20),
                              onPressed: () => _eliminarRutina(r['id']),
                            ),
                            if (!widget.soloGestion)
                              const Icon(Icons.download_rounded, color: Color(0xFFE8FF00)),
                          ],
                        ),
                        onTap: widget.soloGestion 
                          ? () => _editarRutina(r['id'], r['nombre'])
                          : () async {
                              final ejercicios = await DatabaseHelper.instance.readEjerciciosByRutina(r['id']);
                              widget.onImportar!(ejercicios);
                              Navigator.pop(context);
                            },
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

class _ModalSeleccionarMultiplesEjercicios extends StatefulWidget {
  final String? titulo;
  final List<String>? seleccionadosIniciales;
  final Function(List<String>) onFinalizar;
  const _ModalSeleccionarMultiplesEjercicios({this.titulo, this.seleccionadosIniciales, required this.onFinalizar});

  @override
  State<_ModalSeleccionarMultiplesEjercicios> createState() => _ModalSeleccionarMultiplesEjerciciosState();
}

class _ModalSeleccionarMultiplesEjerciciosState extends State<_ModalSeleccionarMultiplesEjercicios> {
  late final List<String> _seleccionados;
  String? _grupoSeleccionado;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  List<EjercicioMaestro> _ejerciciosMaestrosCompletos = [];

  @override
  void initState() {
    super.initState();
    _seleccionados = widget.seleccionadosIniciales != null ? List.from(widget.seleccionadosIniciales!) : [];
    _cargarEjercicios();
  }

  Future<void> _cargarEjercicios() async {
    final custom = await DatabaseHelper.instance.readAllEjerciciosMaestrosCustom();
    final customList = custom.map((e) => EjercicioMaestro(
      nombre: e['nombre'],
      grupoMuscular: e['grupo_muscular'],
    )).toList();
    
    setState(() {
      _ejerciciosMaestrosCompletos = [...LISTA_EJERCICIOS_MAESTRA, ...customList];
    });
  }

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
                autofocus: true,
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
              onPressed: () async {
                if (nuevoNombre.trim().isNotEmpty) {
                  await DatabaseHelper.instance.insertEjercicioMaestroCustom(nuevoNombre.trim(), grupoSeleccionado);
                  setState(() {
                    _seleccionados.add(nuevoNombre.trim());
                  });
                  _cargarEjercicios();
                  if (mounted) Navigator.pop(context);
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
    for (var e in _ejerciciosMaestrosCompletos) {
      agrupados.putIfAbsent(e.grupoMuscular, () => []).add(e);
    }
    
    // Sort exercises within groups
    agrupados.forEach((key, value) {
      value.sort((a, b) => a.nombre.compareTo(b.nombre));
    });

    List<EjercicioMaestro> filtrados = [];
    if (_searchQuery.isNotEmpty) {
      filtrados = _ejerciciosMaestrosCompletos
          .where((e) {
            final matches = e.nombre.toLowerCase().contains(_searchQuery.toLowerCase());
            if (_grupoSeleccionado != null) {
              return matches && e.grupoMuscular == _grupoSeleccionado;
            }
            return matches;
          })
          .toList();
      filtrados.sort((a, b) => a.nombre.compareTo(b.nombre));
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Color(0xFF111111), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.titulo != null)
                        Text(widget.titulo!, style: const TextStyle(color: Color(0xFFE8FF00), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      Text(_grupoSeleccionado ?? 'SELECCIONA EJERCICIOS', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.onFinalizar(_seleccionados);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE8FF00)),
                  child: Text('LISTO (${_seleccionados.length})', style: const TextStyle(color: Color(0xFF0A0A0A), fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Buscador
            Container(
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
                  hintText: _grupoSeleccionado == null ? 'BUSCAR GLOBAL...' : 'BUSCAR EN ${_grupoSeleccionado!.toUpperCase()}...',
                  hintStyle: const TextStyle(color: Color(0xFF555555), fontSize: 12, letterSpacing: 1.5),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: const Color(0xFFE8FF00).withOpacity(0.5), size: 20),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Botón destacado para crear ejercicio
            GestureDetector(
              onTap: _mostrarDialogoNuevoEjercicio,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FF00).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8FF00).withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_circle_outline, color: Color(0xFFE8FF00), size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      '¿NO ESTÁ EN LA LISTA? CREAR EJERCICIO',
                      style: TextStyle(color: Color(0xFFE8FF00), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _searchQuery.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_grupoSeleccionado != null)
                          ListTile(
                            leading: const Icon(Icons.arrow_back, color: Color(0xFFE8FF00)),
                            title: const Text('VOLVER A GRUPOS', style: TextStyle(color: Color(0xFFE8FF00))),
                            onTap: () => setState(() {
                              _grupoSeleccionado = null;
                              _searchQuery = '';
                              _searchCtrl.clear();
                            }),
                          ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filtrados.length,
                            itemBuilder: (context, i) => CheckboxListTile(
                              value: _seleccionados.contains(filtrados[i].nombre),
                              title: Text(filtrados[i].nombre, style: const TextStyle(color: Colors.white)),
                              subtitle: _grupoSeleccionado == null 
                                  ? Text(filtrados[i].grupoMuscular.toUpperCase(), style: const TextStyle(color: Color(0xFF444444), fontSize: 10))
                                  : null,
                              onChanged: (v) {
                                setState(() {
                                  if (v!) _seleccionados.add(filtrados[i].nombre);
                                  else _seleccionados.remove(filtrados[i].nombre);
                                });
                              },
                              activeColor: const Color(0xFFE8FF00),
                              checkColor: const Color(0xFF0A0A0A),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _grupoSeleccionado == null
                      ? ListView(
                          children: (agrupados.keys.toList()..sort()).map((g) => ListTile(
                            title: Text(g.toUpperCase(), style: const TextStyle(color: Colors.white)),
                            onTap: () => setState(() => _grupoSeleccionado = g),
                            trailing: const Icon(Icons.chevron_right, color: Color(0xFF444444)),
                          )).toList(),
                        )
                      : Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.arrow_back, color: Color(0xFFE8FF00)),
                              title: const Text('VOLVER', style: TextStyle(color: Color(0xFFE8FF00))),
                              onTap: () => setState(() => _grupoSeleccionado = null),
                            ),
                            Expanded(
                              child: ListView(
                                children: agrupados[_grupoSeleccionado]!.map((e) => CheckboxListTile(
                                  value: _seleccionados.contains(e.nombre),
                                  title: Text(e.nombre, style: const TextStyle(color: Colors.white)),
                                  onChanged: (v) {
                                    setState(() {
                                      if (v!) _seleccionados.add(e.nombre);
                                      else _seleccionados.remove(e.nombre);
                                    });
                                  },
                                  activeColor: const Color(0xFFE8FF00),
                                  checkColor: const Color(0xFF0A0A0A),
                                )).toList(),
                              ),
                            ),
                          ],
                        ),
            ),
          ],
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
  List<EjercicioMaestro> _ejerciciosMaestrosCompletos = [];

  @override
  void initState() {
    super.initState();
    _cargarEjercicios();
  }

  Future<void> _cargarEjercicios() async {
    final custom = await DatabaseHelper.instance.readAllEjerciciosMaestrosCustom();
    final customList = custom.map((e) => EjercicioMaestro(
      nombre: e['nombre'],
      grupoMuscular: e['grupo_muscular'],
    )).toList();
    
    setState(() {
      _ejerciciosMaestrosCompletos = [...LISTA_EJERCICIOS_MAESTRA, ...customList];
    });
  }

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
                autofocus: true,
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
              onPressed: () async {
                if (nuevoNombre.trim().isNotEmpty) {
                  await DatabaseHelper.instance.insertEjercicioMaestroCustom(nuevoNombre.trim(), grupoSeleccionado);
                  widget.onSeleccionado(nuevoNombre.trim());
                  if (mounted) Navigator.pop(context);
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
    for (var e in _ejerciciosMaestrosCompletos) {
      agrupados.putIfAbsent(e.grupoMuscular, () => []).add(e);
    }
    
    // Sort exercises within groups
    agrupados.forEach((key, value) {
      value.sort((a, b) => a.nombre.compareTo(b.nombre));
    });

    List<EjercicioMaestro> filtrados = [];
    if (_searchQuery.isNotEmpty) {
      filtrados = _ejerciciosMaestrosCompletos
          .where((e) {
            final matches = e.nombre.toLowerCase().contains(_searchQuery.toLowerCase());
            if (_grupoSeleccionado != null) {
              return matches && e.grupoMuscular == _grupoSeleccionado;
            }
            return matches;
          })
          .toList();
      filtrados.sort((a, b) => a.nombre.compareTo(b.nombre));
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        height: MediaQuery.of(context).size.height * 0.75,
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
                        hintText: _grupoSeleccionado == null ? 'BUSCAR GLOBAL...' : 'BUSCAR EN ${_grupoSeleccionado!.toUpperCase()}...',
                        hintStyle: const TextStyle(color: Color(0xFF555555), fontSize: 12, letterSpacing: 1.5),
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: const Color(0xFFE8FF00).withOpacity(0.5), size: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _mostrarDialogoNuevoEjercicio,
                  child: Container(
                    height: 48, width: 48,
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
            Expanded(
              child: _searchQuery.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_grupoSeleccionado != null)
                          ListTile(
                            leading: const Icon(Icons.arrow_back, color: Color(0xFFE8FF00)),
                            title: const Text('VOLVER A GRUPOS', style: TextStyle(color: Color(0xFFE8FF00))),
                            onTap: () => setState(() {
                              _grupoSeleccionado = null;
                              _searchQuery = '';
                              _searchCtrl.clear();
                            }),
                          ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filtrados.length,
                            itemBuilder: (context, i) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(filtrados[i].nombre, style: const TextStyle(color: Color(0xFFCCCCCC))),
                              subtitle: _grupoSeleccionado == null 
                                  ? Text(filtrados[i].grupoMuscular.toUpperCase(), style: const TextStyle(color: Color(0xFF444444), fontSize: 10))
                                  : null,
                              onTap: () {
                                widget.onSeleccionado(filtrados[i].nombre);
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        Expanded(
                          child: _grupoSeleccionado == null
                              ? ListView(
                                  children: (agrupados.keys.toList()..sort()).map((g) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(g.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF333333)),
                                    onTap: () => setState(() => _grupoSeleccionado = g),
                                  )).toList(),
                                )
                              : ListView(
                                  children: (agrupados[_grupoSeleccionado] ?? []).map((e) => ListTile(
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
            ),
          ],
        ),
      ),
    );
  }
}
