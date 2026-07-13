import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/reporte_cognitivo_model.dart';
import '../../providers/api_providers.dart';
import 'game_results.dart';

class GameFlow extends ConsumerStatefulWidget {
  final List<String> gameRoutes;

  const GameFlow({super.key, required this.gameRoutes});

  @override
  ConsumerState<GameFlow> createState() => _GameFlowState();
}

class _GameFlowState extends ConsumerState<GameFlow> {
  int _currentIndex = 0;
  int? _age;
  String _patientName = 'Paciente';
  String _patientExternalId = 'PAC-000';
  String? _patientDocument;
  String? _patientPhone;
  String? _patientDiagnosis;
  late DateTime _startTime;
  final List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _iniciarFlujo();
  }

  Future<void> _iniciarFlujo() async {
    await _loadPatientInfo();
    if (!mounted) return;
    _startNext();
  }

  Future<void> _loadPatientInfo() async {
    try {
      final api = await ref.read(apiServiceProvider.future);
      final pid = api.currentPatientId;
      final patient = await api.getPatient(pid);
      _age = patient.age;
      _patientName = patient.name;
      _patientExternalId = patient.documentId ?? 'PAC-${patient.id}';
      _patientDocument = patient.documentId;
      _patientPhone = patient.phone;
      _patientDiagnosis = patient.diagnosis;
    } catch (e) {
      _age = 30;
    }
    if (mounted) setState(() {});
  }

  void _startNext() {
    if (_currentIndex >= widget.gameRoutes.length) {
      _complete();
      return;
    }

    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      final route = widget.gameRoutes[_currentIndex];
      final flowIndex = _currentIndex;
      _currentIndex++;
      context
          .push(
            route,
            extra: {
              'flow': true,
              'index': flowIndex,
              'total': widget.gameRoutes.length,
              'age': _age,
            },
          )
          .then((resultado) {
            _registrarResultado(resultado);
            _startNext();
          });
    });
  }

  void _registrarResultado(Object? resultado) {
    if (resultado is! Map) return;
    final result = resultado['result'];
    if (result is Map<String, dynamic>) {
      _results.add(result);
    } else if (result is Map) {
      _results.add(Map<String, dynamic>.from(result));
    }
  }

  Future<void> _complete() async {
    final endTime = DateTime.now();
    final durationMs = endTime.difference(_startTime).inMilliseconds;
    final api = await ref.read(apiServiceProvider.future);
    await GameResults.sendSession(
      api: api,
      status: 'completed',
      notes: 'Batería de pruebas finalizada.',
      durationMs: durationMs,
    );
    if (!mounted) return;

    if (_results.isEmpty) {
      context.go('/home');
      return;
    }

    final solicitud = SolicitudReporteCognitivoModel(
      pacienteId: _patientExternalId,
      nombrePaciente: _patientName,
      edadPaciente: _age ?? 30,
      fechaEvaluacion: _fechaActualIso(),
      profesional: api.currentUsername ?? 'Profesional evaluador',
      documentoPaciente: _patientDocument,
      telefonoPaciente: _patientPhone,
      diagnosticoPaciente: _patientDiagnosis,
      institucion: 'NeuroApp360',
      pruebas: _results.map(_pruebaDesdeResultado).toList(),
    );

    context.go('/reporte_cognitivo', extra: solicitud);
  }

  PruebaCognitivaModel _pruebaDesdeResultado(Map<String, dynamic> resultado) {
    final nombrePrueba =
        resultado['nombre_prueba']?.toString() ??
        _nombrePruebaDesdeTitulo(resultado['title']?.toString() ?? '');
    final porcentaje = resultado['score'] is num
        ? (resultado['score'] as num).toDouble()
        : double.tryParse(resultado['score']?.toString() ?? '') ?? 0;
    final tiempoMs = resultado['duration_ms'] is num
        ? (resultado['duration_ms'] as num).toInt()
        : int.tryParse(resultado['duration_ms']?.toString() ?? '') ?? 0;
    final detalles = resultado['details'] as Map<String, dynamic>?;
    final metricas = resultado['metrics'] as Map<String, dynamic>?;

    return PruebaCognitivaModel(
      nombrePrueba: nombrePrueba,
      porcentajeObtenido: porcentaje.clamp(0, 100).toDouble(),
      tiempoSegundos: (tiempoMs / 1000).round(),
      detalles: detalles,
      metricas: metricas,
    );
  }

  String _nombrePruebaDesdeTitulo(String titulo) {
    final t = titulo.toLowerCase();
    if (t.contains('memoria')) return 'Memoria Visual';
    if (t.contains('atención') || t.contains('atencion')) {
      return 'Atención Sostenida';
    }
    if (t.contains('lenguaje') || t.contains('fluidez')) {
      return 'Fluidez Verbal';
    }
    if (t.contains('funciones') || t.contains('stroop')) {
      return 'Funciones Ejecutivas (Stroop)';
    }
    return titulo.isEmpty ? 'Prueba Cognitiva' : titulo;
  }

  String _fechaActualIso() {
    final ahora = DateTime.now();
    final year = ahora.year.toString().padLeft(4, '0');
    final month = ahora.month.toString().padLeft(2, '0');
    final day = ahora.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.gameRoutes.length == 1
        ? 'Iniciando prueba...'
        : 'Iniciando protocolo (${widget.gameRoutes.length} pruebas)...';
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Evaluación Cognitiva'),
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Salir'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (_age != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Paciente: $_age años',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
