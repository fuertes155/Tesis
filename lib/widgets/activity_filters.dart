import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class ActivityFilters extends StatefulWidget {
  final int daysFilter;
  final String statusFilter;
  final String searchQuery;
  final String sortMode;
  final ValueChanged<int> onDaysChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSortSelected;

  const ActivityFilters({
    super.key,
    required this.daysFilter,
    required this.statusFilter,
    required this.searchQuery,
    required this.sortMode,
    required this.onDaysChanged,
    required this.onStatusChanged,
    required this.onSearchChanged,
    required this.onSortSelected,
  });

  @override
  State<ActivityFilters> createState() => _ActivityFiltersState();
}

class _ActivityFiltersState extends State<ActivityFilters> {
  // Se crea una sola vez para no perder el cursor en cada reconstrucción.
  late final _busqueda = TextEditingController(text: widget.searchQuery);

  static const _dias = {7: 'Últimos 7 días', 30: 'Últimos 30 días', 90: 'Últimos 90 días'};
  static const _estados = {'all': 'Todos', 'completed': 'Completadas', 'pending': 'Pendientes'};
  static const _orden = {
    'date_desc': 'Más recientes primero',
    'date_asc': 'Más antiguas primero',
    'status': 'Por estado',
    'patient': 'Por paciente',
  };

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _MenuPill<int>(
          icon: Icons.calendar_month_rounded,
          value: widget.daysFilter,
          options: _dias,
          onSelected: widget.onDaysChanged,
        ),
        _MenuPill<String>(
          icon: Icons.filter_list_rounded,
          value: widget.statusFilter,
          options: _estados,
          onSelected: widget.onStatusChanged,
        ),
        SizedBox(
          width: 200,
          height: 38,
          child: TextField(
            controller: _busqueda,
            onChanged: widget.onSearchChanged,
            style: theme.textTheme.bodyMedium,
            decoration: const InputDecoration(
              hintText: 'Buscar paciente…',
              prefixIcon: Icon(Icons.search_rounded, size: 18),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        _MenuPill<String>(
          icon: Icons.swap_vert_rounded,
          value: widget.sortMode,
          options: _orden,
          onSelected: widget.onSortSelected,
          compact: true,
          tooltip: 'Ordenar',
        ),
      ],
    );
  }
}

/// Botón tipo píldora que abre un menú con opciones y marca la seleccionada.
class _MenuPill<T> extends StatelessWidget {
  const _MenuPill({
    required this.icon,
    required this.value,
    required this.options,
    required this.onSelected,
    this.compact = false,
    this.tooltip,
  });

  final IconData icon;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onSelected;

  /// Solo muestra el ícono.
  final bool compact;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return PopupMenuButton<T>(
      tooltip: tooltip ?? '',
      initialValue: value,
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final entry in options.entries)
          PopupMenuItem<T>(
            value: entry.key,
            height: 40,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: entry.key == value
                      ? Icon(Icons.check_rounded, size: 18, color: cs.primary)
                      : null,
                ),
                Text(entry.value),
              ],
            ),
          ),
      ],
      child: Container(
        height: 38,
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: context.radii.radiusMd,
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: cs.onSurfaceVariant),
            if (!compact) ...[
              const SizedBox(width: 8),
              Text(options[value] ?? '', style: theme.textTheme.labelLarge?.copyWith(color: cs.onSurface)),
              const SizedBox(width: 4),
              Icon(Icons.expand_more_rounded, size: 18, color: cs.onSurfaceVariant),
            ],
          ],
        ),
      ),
    );
  }
}
