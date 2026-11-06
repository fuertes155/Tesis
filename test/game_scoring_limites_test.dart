import 'package:flutter_application_1/games/common/game_scoring.dart';
import 'package:flutter_test/flutter_test.dart';

/// Complementa game_scoring_test.dart con los límites de cada fórmula.
void main() {
  group('Bandas de edad (límites exactos)', () {
    test('cada edad límite cae en su banda', () {
      final esperado = {12: 0, 13: 1, 17: 1, 18: 2, 34: 2, 35: 3, 49: 3, 50: 4, 64: 4, 65: 5, 100: 5};
      esperado.forEach((edad, banda) => expect(GameScoring.ageBand(edad), banda, reason: 'edad $edad'));
    });

    test('valores esperados por banda', () {
      expect(GameScoring.expectedReactionMs(70), 380);
      expect(GameScoring.expectedFluencyCount(25), 18);
      expect(GameScoring.expectedMemoryLevel(10), 4);
    });
  });

  group('clampScore', () {
    test('recorta al rango 0–100 y trata NaN como 0', () {
      expect(GameScoring.clampScore(-5), 0);
      expect(GameScoring.clampScore(150), 100);
      expect(GameScoring.clampScore(double.nan), 0);
      expect(GameScoring.clampScore(73.9), 73);
    });
  });

  group('Atención (tiempo de reacción)', () {
    test('la penalización por respuestas anticipadas resta puntos', () {
      final sin = GameScoring.reactionScoreFromAvgMs(500, age: 70);
      final con = GameScoring.reactionScoreFromAvgMs(500, age: 70, penalty: 15);
      expect(sin - con, 15);
    });

    test('el mismo tiempo puntúa mejor en un adulto mayor que en un joven', () {
      expect(
        GameScoring.reactionScoreFromAvgMs(450, age: 75),
        greaterThan(GameScoring.reactionScoreFromAvgMs(450, age: 25)),
      );
    });
  });

  group('Fluidez verbal', () {
    test('producir lo esperado para la edad da 90', () {
      expect(GameScoring.fluencyScore(GameScoring.expectedFluencyCount(30), age: 30), 90);
    });

    test('0 palabras da 0 y una producción muy alta no pasa de 100', () {
      expect(GameScoring.fluencyScore(0, age: 30), 0);
      expect(GameScoring.fluencyScore(60, age: 30), 100);
    });
  });

  group('Memoria visual', () {
    test('quedar por debajo del nivel esperado reduce el puntaje', () {
      final esperado = GameScoring.expectedMemoryLevel(70);
      expect(GameScoring.memoryScore(level: esperado, rawScore: 0, age: 70), 70);
      expect(GameScoring.memoryScore(level: esperado - 3, rawScore: 0, age: 70), 40);
    });
  });

  group('Funciones ejecutivas (Stroop)', () {
    test('sin aciertos el puntaje sale solo de la velocidad', () {
      final rapido = GameScoring.stroopExecutiveScore(correct: 0, total: 20, avgMs: 280, age: 30);
      expect(rapido, 35); // 0·65 + 100·0.35
    });

    test('con total 0 no divide por cero', () {
      expect(GameScoring.stroopExecutiveScore(correct: 0, total: 0, avgMs: 400, age: 30), inInclusiveRange(0, 100));
    });

    test('más aciertos con el mismo tiempo dan más puntaje', () {
      final pocos = GameScoring.stroopExecutiveScore(correct: 10, total: 20, avgMs: 600, age: 60);
      final muchos = GameScoring.stroopExecutiveScore(correct: 19, total: 20, avgMs: 600, age: 60);
      expect(muchos, greaterThan(pocos));
    });
  });
}
