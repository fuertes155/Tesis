import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../models/patient.dart';
import '../providers/api_providers.dart';
import '../providers/data_providers.dart';
import '../widgets/session_stepper.dart';

/// Pruebas disponibles. Los nombres coinciden con los del selector de pruebas.
class _Prueba {
  const _Prueba(this.id, this.nombre, this.icono, this.minutos);

  final String id;
  final String nombre;
  final IconData icono;
  final int minutos;
}

const _memoria = _Prueba('Prueba de Memoria Visual', 'Memoria visual', Icons.visibility_outlined, 8);
const _atencion = _Prueba('Prueba de Atención Sostenida', 'Atención sostenida', Icons.timer_outlined, 6);
const _fluidez = _Prueba('Prueba de Fluidez Verbal', 'Fluidez verbal', Icons.mic_none_outlined, 5);
const _stroop = _Prueba('Prueba de Funciones Ejecutivas (Stroop)', 'Funciones ejecutivas', Icons.psychology_outlined, 7);

class NewSessionScreen extends ConsumerWidget {
  final int? patientId;

  const NewSessionScreen({super.key, this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final api = ref.read(apiServiceProvider).value;
    if (patientId != null && api != null) {
      api.setCurrentPatientId(patientId!);
    }
    final pacientesAsync = ref.watch(patientsProvider);
    final pacientes = pacientesAsync.value ?? const <Patient>[];

    // Las pruebas se guardan sobre el "paciente actual"; si no es uno existente
    // (p. ej. se entró desde Inicio), los resultados quedarían sin paciente.
    void exigirPaciente(VoidCallback accion) {
      final valido = api != null && pacientes.any((p) => p.id == api.currentPatientId);
      if (valido) {
        accion();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero selecciona el paciente que vas a evaluar.')),
      );
    }

    void abrirSelector(List<_Prueba> pruebas) => exigirPaciente(() {
          context.push('/test_selector', extra: {
            'initialSelection': [for (final p in pruebas) p.id],
          });
        });

    final baterias = [
      _Bateria(
        titulo: 'Protocolo integral',
        descripcion: 'Evaluación completa de las funciones cognitivas principales.',
        icono: Icons.psychology_alt_rounded,
        etiqueta: 'Recomendado',
        color: cs.primary,
        pruebas: const [_memoria, _atencion, _fluidez, _stroop],
        recomendado: true,
      ),
      _Bateria(
        titulo: 'Atención y memoria',
        descripcion: 'Enfoque en retención de información y procesos atencionales.',
        icono: Icons.center_focus_strong_rounded,
        etiqueta: 'Especializado',
        color: cs.tertiary,
        pruebas: const [_memoria, _atencion],
      ),
      _Bateria(
        titulo: 'Screening rápido',
        descripcion: 'Evaluación breve para detección temprana.',
        icono: Icons.bolt_rounded,
        etiqueta: 'Rápido',
        color: cs.secondary,
        pruebas: const [_memoria],
      ),
    ];

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Nueva sesión'),
        shape: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7))),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final ancho = constraints.maxWidth;
          final margen = ancho > 1128 ? (ancho - 1080) / 2 : (ancho < 600 ? 16.0 : 24.0);
          final enColumnas = ancho >= 900;

          final tarjetas = [
            for (var i = 0; i < baterias.length; i++)
              _TarjetaBateria(
                bateria: baterias[i],
                alturaFija: enColumnas,
                onElegir: () => abrirSelector(baterias[i].pruebas),
              )
                  .animate()
                  .fadeIn(delay: (120 + i * 80).ms, duration: 300.ms)
                  .moveY(begin: 12, end: 0, delay: (120 + i * 80).ms, duration: 300.ms),
          ];

          return ListView(
            padding: EdgeInsets.fromLTRB(margen, 28, margen, 40),
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SessionStepper(current: 0),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                '¿Qué evaluación vas a aplicar?',
                style: theme.textTheme.headlineMedium?.copyWith(color: cs.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                'Elige un protocolo. En el siguiente paso podrás agregar o quitar pruebas.',
                style: theme.textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: _SelectorPaciente(
                  pacientes: pacientes,
                  cargando: pacientesAsync.isLoading,
                  seleccionadoId: api?.currentPatientId,
                  fijo: patientId != null,
                  onSeleccionar: (p) {
                    api?.setCurrentPatientId(p.id);
                    api?.setCurrentPatientName(p.name);
                  },
                ),
              ),
              const SizedBox(height: 28),
              if (enColumnas)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < tarjetas.length; i++) ...[
                        if (i > 0) const SizedBox(width: 20),
                        Expanded(child: tarjetas[i]),
                      ],
                    ],
                  ),
                )
              else
                for (var i = 0; i < tarjetas.length; i++) ...[
                  if (i > 0) const SizedBox(height: 16),
                  tarjetas[i],
                ],
              const SizedBox(height: 28),
              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      '¿Prefieres elegir las pruebas una por una?',
                      style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    TextButton.icon(
                      onPressed: () => exigirPaciente(() => context.push('/test_selector')),
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('Personalizar'),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),
            ],
          );
        },
      ),
    );
  }
}

class _Bateria {
  const _Bateria({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.etiqueta,
    required this.color,
    required this.pruebas,
    this.recomendado = false,
  });

  final String titulo;
  final String descripcion;
  final IconData icono;
  final String etiqueta;
  final Color color;
  final List<_Prueba> pruebas;
  final bool recomendado;

  int get minutos => pruebas.fold(0, (total, p) => total + p.minutos);
}

class _TarjetaBateria extends StatefulWidget {
  const _TarjetaBateria({
    required this.bateria,
    required this.onElegir,
    required this.alturaFija,
  });

  final _Bateria bateria;
  final VoidCallback onElegir;

  /// Si la tarjeta recibe una altura fija (en columnas), el botón se alinea abajo.
  final bool alturaFija;

  @override
  State<_TarjetaBateria> createState() => _TarjetaBateriaState();
}

class _TarjetaBateriaState extends State<_TarjetaBateria> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final b = widget.bateria;
    final radio = context.radii.radiusXl;
    final nPruebas = b.pruebas.length;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: radio,
          border: Border.all(
            color: b.recomendado
                ? cs.primary
                : (_hover ? b.color.withValues(alpha: 0.4) : cs.outlineVariant),
            width: b.recomendado ? 2 : 1,
          ),
          boxShadow: [
            ...context.premiumShadows,
            if (_hover || b.recomendado)
              BoxShadow(
                color: b.color.withValues(alpha: _hover ? 0.18 : 0.10),
                blurRadius: 28,
                spreadRadius: -8,
                offset: const Offset(0, 14),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radio,
            onTap: widget.onElegir,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (b.recomendado)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      gradient: context.glass.headerGradient,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(context.radii.xl - 2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Más completo',
                          style: theme.textTheme.labelMedium?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: b.color.withValues(alpha: 0.12),
                              borderRadius: context.radii.radiusMd,
                            ),
                            child: Icon(b.icono, color: b.color, size: 26),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: b.color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              b.etiqueta,
                              style: theme.textTheme.labelMedium?.copyWith(color: b.color),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(b.titulo, style: theme.textTheme.titleLarge?.copyWith(color: cs.onSurface)),
                      const SizedBox(height: 6),
                      Text(
                        b.descripcion,
                        style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _Dato(icono: Icons.schedule_rounded, texto: '~${b.minutos} min'),
                          const SizedBox(width: 16),
                          _Dato(
                            icono: Icons.checklist_rounded,
                            texto: '$nPruebas ${nPruebas == 1 ? 'prueba' : 'pruebas'}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: cs.outlineVariant),
                      const SizedBox(height: 14),
                      Text(
                        'INCLUYE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final p in b.pruebas)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_rounded, size: 18, color: b.color),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  p.nombre,
                                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                                ),
                              ),
                              Text('${p.minutos} min', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.alturaFija) const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                  child: b.recomendado
                      ? FilledButton(
                          onPressed: widget.onElegir,
                          child: const _TextoBoton(),
                        )
                      : OutlinedButton(
                          onPressed: widget.onElegir,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: b.color,
                            side: BorderSide(color: b.color.withValues(alpha: 0.4), width: 1.2),
                          ),
                          child: const _TextoBoton(),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TextoBoton extends StatelessWidget {
  const _TextoBoton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Elegir protocolo'),
        SizedBox(width: 6),
        Icon(Icons.arrow_forward_rounded, size: 18),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 5),
        Text(texto, style: theme.textTheme.labelLarge?.copyWith(color: cs.onSurface)),
      ],
    );
  }
}

/// Paciente a evaluar: chip fijo si se llegó desde su ficha; si no, un buscador.
class _SelectorPaciente extends StatefulWidget {
  const _SelectorPaciente({
    required this.pacientes,
    required this.cargando,
    required this.seleccionadoId,
    required this.fijo,
    required this.onSeleccionar,
  });

  final List<Patient> pacientes;
  final bool cargando;
  final int? seleccionadoId;
  final bool fijo;
  final ValueChanged<Patient> onSeleccionar;

  @override
  State<_SelectorPaciente> createState() => _SelectorPacienteState();
}

class _SelectorPacienteState extends State<_SelectorPaciente> {
  int? _elegido;

  @override
  Widget build(BuildContext context) {
    final idActual = _elegido ?? widget.seleccionadoId;
    Patient? actual;
    for (final p in widget.pacientes) {
      if (p.id == idActual) actual = p;
    }

    if (widget.fijo && actual != null) {
      return _ChipPaciente(nombre: actual.name);
    }
    if (widget.cargando && widget.pacientes.isEmpty) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final ordenados = [...widget.pacientes]..sort((a, b) => a.name.compareTo(b.name));
    final anchoPantalla = MediaQuery.sizeOf(context).width;
    return DropdownMenu<int>(
      // Se recrea al llegar la lista para que tome la selección inicial.
      key: ValueKey('pacientes_${widget.pacientes.length}'),
      width: anchoPantalla < 452 ? anchoPantalla - 32 : 420,
      menuHeight: 320,
      initialSelection: actual?.id,
      enableFilter: true,
      requestFocusOnTap: true,
      leadingIcon: const Icon(Icons.person_search_rounded),
      label: const Text('Paciente a evaluar'),
      hintText: 'Busca y selecciona un paciente',
      dropdownMenuEntries: [
        for (final p in ordenados)
          DropdownMenuEntry(value: p.id, label: p.name),
      ],
      onSelected: (id) {
        if (id == null) return;
        final p = widget.pacientes.firstWhere((x) => x.id == id);
        setState(() => _elegido = id);
        widget.onSeleccionar(p);
      },
    );
  }
}

class _ChipPaciente extends StatelessWidget {
  const _ChipPaciente({required this.nombre});

  final String nombre;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: cs.primaryContainer,
            child: Icon(Icons.person_rounded, size: 16, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 8),
          Text('Paciente: ', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          Text(nombre, style: theme.textTheme.labelLarge?.copyWith(color: cs.onSurface)),
        ],
      ),
    );
  }
}
