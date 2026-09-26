import 'package:flutter/material.dart';

/// Indicador de pasos del flujo de evaluación: Protocolo → Pruebas → Evaluación.
class SessionStepper extends StatelessWidget {
  const SessionStepper({super.key, required this.current});

  /// Paso actual (0 = Protocolo, 1 = Pruebas, 2 = Evaluación).
  final int current;

  static const _pasos = ['Protocolo', 'Pruebas', 'Evaluación'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _pasos.length; i++) ...[
          if (i > 0)
            Container(
              width: 32,
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: i <= current ? cs.primary : cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          _Paso(
            numero: i + 1,
            etiqueta: _pasos[i],
            estado: i < current
                ? _EstadoPaso.hecho
                : i == current
                    ? _EstadoPaso.actual
                    : _EstadoPaso.pendiente,
          ),
        ],
      ],
    );
  }
}

enum _EstadoPaso { hecho, actual, pendiente }

class _Paso extends StatelessWidget {
  const _Paso({required this.numero, required this.etiqueta, required this.estado});

  final int numero;
  final String etiqueta;
  final _EstadoPaso estado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final activo = estado != _EstadoPaso.pendiente;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: activo ? cs.primary : Colors.transparent,
            border: activo ? null : Border.all(color: cs.outline, width: 1.5),
          ),
          child: estado == _EstadoPaso.hecho
              ? Icon(Icons.check_rounded, size: 16, color: cs.onPrimary)
              : Text(
                  '$numero',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: activo ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          etiqueta,
          style: theme.textTheme.labelLarge?.copyWith(
            color: estado == _EstadoPaso.actual ? cs.onSurface : cs.onSurfaceVariant,
            fontWeight: estado == _EstadoPaso.actual ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
