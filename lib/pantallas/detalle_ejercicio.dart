import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db/database_helper.dart';
import '../pantallas/principal.dart';

class PantallaDetalleEjercicio extends StatefulWidget {
  final Ejercicio ejercicio;

  const PantallaDetalleEjercicio({super.key, required this.ejercicio});

  @override
  State<PantallaDetalleEjercicio> createState() => _PantallaDetalleEjercicioState();
}

class _PantallaDetalleEjercicioState extends State<PantallaDetalleEjercicio> {
  late TextEditingController _pesoCtrl;
  late TextEditingController _repsCtrl;
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _seriesList = [];
  int? _editingNoteIndex;
  late TextEditingController _notaCtrl;
  List<Ejercicio> _historial = [];

  static const List<String> _mesesCortos = [
    'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
    'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'
  ];

  // Variables para el cronómetro
  Timer? _timer;
  int _seconds = 0;
  bool _timerRunning = false;

  @override
  void initState() {
    super.initState();
    _pesoCtrl = TextEditingController(text: widget.ejercicio.peso == 0 ? '' : widget.ejercicio.peso.toString());
    _repsCtrl = TextEditingController(text: widget.ejercicio.repeticiones == 0 ? '' : widget.ejercicio.repeticiones.toString());
    _notaCtrl = TextEditingController();
    
    if (widget.ejercicio.detalles != null && widget.ejercicio.detalles!.isNotEmpty) {
      try {
        _seriesList = List<Map<String, dynamic>>.from(jsonDecode(widget.ejercicio.detalles!));
      } catch (e) {
        _seriesList = [];
      }
    }
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    final history = await DatabaseHelper.instance.readHistoryByNombre(widget.ejercicio.nombre);
    setState(() {
      _historial = history;
    });
  }

  void _mostrarHistorial() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HISTORIAL DE PROGRESO',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _historial.isEmpty 
                ? const Center(child: Text('No hay registros previos', style: TextStyle(color: Color(0xFF444444))))
                : ListView.builder(
                    itemCount: _historial.length,
                    itemBuilder: (context, index) {
                      final item = _historial[index];
                      final fecha = DateTime.fromMillisecondsSinceEpoch(int.parse(item.id));
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A0A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1E1E1E)),
                        ),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${fecha.day} ${_mesesCortos[fecha.month-1]} ${fecha.year}',
                                  style: const TextStyle(color: Color(0xFFE8FF00), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.series} SERIES COMPLETADAS',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${item.peso}kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text('${item.repeticiones} reps', style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _repsCtrl.dispose();
    _notaCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_timerRunning) return;
    setState(() => _timerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _seconds++);
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _timerRunning = false);
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _seconds = 0;
      _timerRunning = false;
    });
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _agregarSerie() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _seriesList.add({
        'peso': double.tryParse(_pesoCtrl.text) ?? 0,
        'reps': int.tryParse(_repsCtrl.text) ?? 0,
        'nota': '',
      });
    });
    HapticFeedback.lightImpact();
  }

  void _eliminarSerie(int index) {
    setState(() {
      _seriesList.removeAt(index);
      if (_editingNoteIndex == index) _editingNoteIndex = null;
    });
    HapticFeedback.mediumImpact();
  }

  void _toggleNota(int index) {
    setState(() {
      if (_editingNoteIndex == index) {
        _seriesList[index]['nota'] = _notaCtrl.text;
        _editingNoteIndex = null;
      } else {
        if (_editingNoteIndex != null) {
          _seriesList[_editingNoteIndex!]['nota'] = _notaCtrl.text;
        }
        _editingNoteIndex = index;
        _notaCtrl.text = _seriesList[index]['nota'] ?? '';
      }
    });
  }

  Future<void> _guardar() async {
    if (_editingNoteIndex != null) {
      _seriesList[_editingNoteIndex!]['nota'] = _notaCtrl.text;
    }

    double pesoFinal = widget.ejercicio.peso;
    int repsFinal = widget.ejercicio.repeticiones;
    
    if (_seriesList.isNotEmpty) {
      pesoFinal = _seriesList.last['peso'];
      repsFinal = _seriesList.last['reps'];
    }

    final actualizado = Ejercicio(
      id: widget.ejercicio.id,
      nombre: widget.ejercicio.nombre,
      peso: pesoFinal,
      repeticiones: repsFinal,
      series: _seriesList.length,
      dia: widget.ejercicio.dia,
      detalles: jsonEncode(_seriesList),
    );

    await DatabaseHelper.instance.update(actualizado);
    HapticFeedback.mediumImpact();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8FF00),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.ejercicio.nombre.toUpperCase(),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 42,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('NUEVA SERIE'),
                      GestureDetector(
                        onTap: _mostrarHistorial,
                        child: Row(
                          children: const [
                            Icon(Icons.history, color: Color(0xFFE8FF00), size: 14),
                            SizedBox(width: 6),
                            Text(
                              'VER HISTORIAL',
                              style: TextStyle(
                                color: Color(0xFFE8FF00),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _buildInput(
                          controller: _pesoCtrl,
                          label: 'PESO (KG)',
                          hint: '0.0',
                          icon: Icons.fitness_center,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInput(
                          controller: _repsCtrl,
                          label: 'REPS',
                          hint: '0',
                          icon: Icons.repeat,
                          isInteger: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _agregarSerie,
                        child: Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8FF00),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add, color: Color(0xFF0A0A0A), size: 32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  _buildSectionTitle('SERIES COMPLETADAS'),
                  const SizedBox(height: 16),
                  if (_seriesList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No has añadido series todavía.',
                        style: TextStyle(color: Color(0xFF444444), fontSize: 14),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _seriesList.length,
                      itemBuilder: (context, index) {
                        final serie = _seriesList[index];
                        final bool isEditing = _editingNoteIndex == index;
                        final bool hasNote = (serie['nota'] ?? '').toString().isNotEmpty;

                        return Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF111111),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF1E1E1E)),
                              ),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'SERIE ${index + 1}',
                                            style: const TextStyle(
                                              color: Color(0xFFE8FF00),
                                              fontWeight: FontWeight.w900,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                            icon: Icon(
                                              hasNote ? Icons.sticky_note_2 : Icons.note_add_outlined,
                                              color: hasNote ? const Color(0xFFE8FF00) : const Color(0xFF444444),
                                              size: 18,
                                            ),
                                            onPressed: () => _toggleNota(index),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${serie['peso']}kg',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${serie['reps']} REPES',
                                    style: const TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.close, color: Color(0xFF444444), size: 18),
                                    onPressed: () => _eliminarSerie(index),
                                  ),
                                ],
                              ),
                            ),
                            if (isEditing)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE8FF00).withOpacity(0.3)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _notaCtrl,
                                        autofocus: true,
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                        maxLines: 2,
                                        decoration: const InputDecoration(
                                          hintText: 'Añadir observación...',
                                          hintStyle: TextStyle(color: Color(0xFF444444)),
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.check_circle_outline, color: Color(0xFFE8FF00), size: 20),
                                      onPressed: () => _toggleNota(index),
                                    ),
                                  ],
                                ),
                              )
                            else if (hasNote)
                              GestureDetector(
                                onTap: () => _toggleNota(index),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF161616),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    serie['nota'],
                                    style: const TextStyle(color: Color(0xFF888888), fontSize: 12, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8FF00),
                        foregroundColor: const Color(0xFF0A0A0A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'GUARDAR SESIÓN',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
          
          // Cronómetro Flotante
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8FF00).withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Color(0xFFE8FF00), size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _formatTime(_seconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _timerRunning ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: const Color(0xFFE8FF00),
                      size: 32,
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _timerRunning ? _pauseTimer() : _startTimer();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF444444), size: 24),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _stopTimer();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF444444),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isInteger = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFFE8FF00).withOpacity(0.5), size: 20),
            filled: true,
            fillColor: const Color(0xFF111111),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E1E1E)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E1E1E)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8FF00), width: 1),
            ),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? '!' : null,
        ),
      ],
    );
  }
}
