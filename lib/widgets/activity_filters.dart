import 'package:flutter/material.dart';

class ActivityFilters extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DropdownButton<int>(
          value: daysFilter,
          items: const [
            DropdownMenuItem(value: 7, child: Text('Últimos 7 días')),
            DropdownMenuItem(value: 30, child: Text('Últimos 30 días')),
            DropdownMenuItem(value: 90, child: Text('Últimos 90 días')),
          ],
          onChanged: (v) {
            if (v == null) return;
            onDaysChanged(v);
          },
        ),
        DropdownButton<String>(
          value: statusFilter,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Todos')),
            DropdownMenuItem(value: 'completed', child: Text('Completadas')),
            DropdownMenuItem(value: 'pending', child: Text('Pendientes')),
          ],
          onChanged: (v) {
            if (v == null) return;
            onStatusChanged(v);
          },
        ),
        SizedBox(
          width: 240,
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar por paciente o notas…',
              prefixIcon: Icon(Icons.search_rounded),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            controller: TextEditingController(text: searchQuery),
            onChanged: onSearchChanged,
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Ordenar',
          icon: const Icon(Icons.sort_rounded),
          onSelected: onSortSelected,
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'date_desc',
              child: Text('Fecha: reciente primero'),
            ),
            PopupMenuItem(
              value: 'date_asc',
              child: Text('Fecha: antiguo primero'),
            ),
            PopupMenuItem(
              value: 'status',
              child: Text('Por estado'),
            ),
            PopupMenuItem(
              value: 'patient',
              child: Text('Por paciente'),
            ),
          ],
        ),
      ],
    );
  }
}
