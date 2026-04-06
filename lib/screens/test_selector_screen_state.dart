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
    final primaryColor = const Color(0xFF1A237E);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Configurar Sesión',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'SELECCIÓN DE PRUEBAS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Personalice el protocolo de evaluación seleccionando las pruebas específicas para este paciente.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _selectedTests.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final key = _selectedTests.keys.elementAt(index);
                final isSelected = _selectedTests[key]!;

                IconData icon;
                if (key.contains('Memoria')) {
                  icon = Icons.visibility_outlined;
                } else if (key.contains('Atención')) {
                  icon = Icons.timer_outlined;
                } else if (key.contains('Fluidez')) {
                  icon = Icons.mic_none_outlined;
                } else {
                  icon = Icons.psychology_outlined;
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withValues(alpha: 0.03)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: CheckboxListTile(
                    contentPadding: const EdgeInsets.all(16),
                    secondary: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF64748B),
                        size: 24,
                      ),
                    ),
                    title: Text(
                      key,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isSelected
                            ? primaryColor
                            : const Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    subtitle: Text(
                      'Duración estimada: 5-8 min',
                      style: TextStyle(
                        color: isSelected
                            ? primaryColor.withValues(alpha: 0.6)
                            : const Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                    value: isSelected,
                    activeColor: primaryColor,
                    checkboxShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
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
              height: 54,
              child: ElevatedButton(
                onPressed: _selectedTests.containsValue(true)
                    ? () {
                        final routes = <String>[];
                        if (_selectedTests['Prueba de Memoria Visual'] == true) {
                          routes.add('/game_memory');
                        }
                        if (_selectedTests['Prueba de Atención Sostenida'] ==
                            true) {
                          routes.add('/game_reaction');
                        }
                        if (_selectedTests['Prueba de Fluidez Verbal'] == true) {
                          routes.add('/game_fluency');
                        }
                        if (_selectedTests[
                                'Prueba de Funciones Ejecutivas (Stroop)'] ==
                            true) {
                          routes.add('/game_stroop');
                        }
                        if (routes.isEmpty) {
                          context.push('/test_placeholder');
                          return;
                        }
                        context.push(
                          '/game_flow',
                          extra: {'routes': routes},
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                child: const Text('COMENZAR EVALUACIÓN'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
