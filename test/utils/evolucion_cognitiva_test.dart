import 'package:flutter_application_1/utils/evolucion_cognitiva.dart';
import 'package:flutter_test/flutter_test.dart';

/// Resultado tal como lo devuelve `/sessions/results/latest` (timestamp UTC sin zona).
Map<String, dynamic> resultado(String juego, num score, String timestamp) =>
    {'game_name': juego, 'score': score, 'timestamp': timestamp};

/// Día local que corresponde a un instante UTC (independiente de la zona del equipo).
DateTime diaLocal(int y, int m, int d, [int h = 15]) {
  final local = DateTime.utc(y, m, d, h).toLocal();
  return DateTime(local.year, local.month, local.day);
}

void main() {
  group('fechaLocalDesdeApi', () {
    test('interpreta un timestamp sin zona como UTC y lo pasa a hora local', () {
      expect(
        fechaLocalDesdeApi('2026-11-04T15:30:00.123456'),
        DateTime.utc(2026, 11, 4, 15, 30, 0, 123, 456).toLocal(),
      );
    });

    test('respeta la zona si viene indicada', () {
      expect(fechaLocalDesdeApi('2026-11-04T15:30:00Z'), DateTime.utc(2026, 11, 4, 15, 30).toLocal());
      expect(fechaLocalDesdeApi('2026-11-04T10:30:00-05:00'), DateTime.utc(2026, 11, 4, 15, 30).toLocal());
    });

    test('devuelve null con valores vacíos o inválidos', () {
      expect(fechaLocalDesdeApi(null), isNull);
      expect(fechaLocalDesdeApi(''), isNull);
      expect(fechaLocalDesdeApi('no-es-fecha'), isNull);
    });
  });

  group('agruparEvolucion', () {
    test('sin resultados la evolución queda vacía', () {
      final evo = agruparEvolucion([]);
      expect(evo.vacia, isTrue);
      expect(evo.juegos, isEmpty);
    });

    test('agrupa por día, ordena de lo más antiguo a lo más reciente y separa por juego', () {
      // Llegan del más reciente al más antiguo, como los entrega la API.
      final evo = agruparEvolucion([
        resultado('fluency', 37, '2026-09-16T15:20:00'),
        resultado('stroop', 34, '2026-09-16T15:18:00'),
        resultado('reaction', 45, '2026-09-16T15:16:00'),
        resultado('visual_memory', 40, '2026-09-16T15:14:00'),
        resultado('fluency', 43, '2026-05-01T15:20:00'),
        resultado('stroop', 40, '2026-05-01T15:18:00'),
        resultado('reaction', 51, '2026-05-01T15:16:00'),
        resultado('visual_memory', 50, '2026-05-01T15:14:00'),
      ]);

      expect(evo.fechas, [diaLocal(2026, 5, 1), diaLocal(2026, 9, 16)]);
      expect(evo.juegos, ['visual_memory', 'reaction', 'stroop', 'fluency']);
      expect(evo.puntajes['visual_memory'], [50, 40]);
      expect(evo.puntajes['fluency'], [43, 37]);
    });

    test('si un juego se repite el mismo día conserva el más reciente', () {
      final evo = agruparEvolucion([
        resultado('reaction', 80, '2026-11-04T16:00:00'),
        resultado('reaction', 60, '2026-11-04T15:00:00'),
      ]);
      expect(evo.puntajes['reaction'], [80]);
    });

    test('un día sin cierta prueba queda como hueco (null)', () {
      final evo = agruparEvolucion([
        resultado('visual_memory', 70, '2026-11-04T15:00:00'),
        resultado('visual_memory', 60, '2026-10-01T15:00:00'),
        resultado('reaction', 55, '2026-10-01T15:05:00'),
      ]);
      expect(evo.puntajes['reaction'], [55, null]);
      expect(evo.puntajes['visual_memory'], [60, 70]);
    });

    test('ignora juegos desconocidos y registros incompletos', () {
      final evo = agruparEvolucion([
        resultado('Memoria 360', 90, '2026-11-04T15:00:00'),      // nombre antiguo
        {'game_name': 'stroop', 'score': null, 'timestamp': '2026-11-04T15:00:00'},
        {'game_name': 'stroop', 'score': 50, 'timestamp': 'fecha-rota'},
        'no-es-un-mapa',
        resultado('fluency', 75, '2026-11-04T15:00:00'),
      ]);
      expect(evo.juegos, ['fluency']);
      expect(evo.fechas, hasLength(1));
    });
  });
}
