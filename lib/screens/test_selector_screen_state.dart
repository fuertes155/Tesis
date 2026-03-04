part of 'test_selector_screen.dart';

class TestSelectorScreenState extends State<TestSelectorScreen> {
  final Map<String, bool> _selectedTests = {
    'Prueba de Memoria Visual': false,
    'Prueba de Atención Sostenida': false,
    'Prueba de Fluidez Verbal': false,
    'Prueba de Funciones Ejecutivas (Stroop)': false,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Seleccionar Pruebas'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  'Configurar Sesión',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seleccione las pruebas específicas a realizar',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _selectedTests.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final key = _selectedTests.keys.elementAt(index);
                final isSelected = _selectedTests[key]!;

                IconData icon;
                if (key.contains('Memoria')) {
                  icon = Icons.memory_rounded;
                } else if (key.contains('Atención')) {
                  icon = Icons.timer_rounded;
                } else if (key.contains('Fluidez')) {
                  icon = Icons.record_voice_over_rounded;
                } else {
                  icon = Icons.psychology_alt_rounded;
                }

                return Card(
                  elevation: 0,
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.05)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.grey.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: CheckboxListTile(
                    contentPadding: const EdgeInsets.all(16),
                    secondary: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Colors.white : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                    title: Text(
                      key,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.black87,
                      ),
                    ),
                    value: isSelected,
                    activeColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onChanged: (bool? value) {
                      setState(() {
                        _selectedTests[key] = value!;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedTests.containsValue(true)
                    ? () {
                        if (_selectedTests['Prueba de Memoria Visual'] ==
                            true) {
                          context.push('/game_memory');
                        } else if (_selectedTests['Prueba de Atención Sostenida'] ==
                            true) {
                          context.push('/game_reaction');
                        } else if (_selectedTests['Prueba de Fluidez Verbal'] ==
                            true) {
                          context.push('/game_fluency');
                        } else if (_selectedTests['Prueba de Funciones Ejecutivas (Stroop)'] ==
                            true) {
                          context.push('/game_stroop');
                        } else {
                          context.push('/test_placeholder');
                        }
                      }
                    : null,
                child: const Text('COMENZAR EVALUACIÓN'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
