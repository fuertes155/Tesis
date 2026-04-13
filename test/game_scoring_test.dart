import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/games/common/game_scoring.dart';

void main() {
  group('GameScoring - Age Bands', () {
    test('Should return correct age band for different ages', () {
      expect(GameScoring.ageBand(10), 0); // Children
      expect(GameScoring.ageBand(15), 1); // Teenagers
      expect(GameScoring.ageBand(25), 2); // Young adults
      expect(GameScoring.ageBand(40), 3); // Middle aged
      expect(GameScoring.ageBand(55), 4); // Seniors
      expect(GameScoring.ageBand(70), 5); // Elder
      expect(GameScoring.ageBand(null), 2); // Default
    });
  });

  group('GameScoring - Reaction Score', () {
    test('Should calculate perfect score for expected reaction time', () {
      final expected = GameScoring.expectedReactionMs(30); // 280ms
      final score = GameScoring.reactionScoreFromAvgMs(expected, age: 30);
      expect(score, 100);
    });

    test('Should penalize slow reaction times', () {
      final expected = GameScoring.expectedReactionMs(30); // 280ms
      final score = GameScoring.reactionScoreFromAvgMs(expected + 200, age: 30);
      expect(score, lessThan(100));
    });

    test('Should never return scores below 0 or above 100', () {
      expect(GameScoring.reactionScoreFromAvgMs(5000, age: 30), 0);
      expect(GameScoring.reactionScoreFromAvgMs(10, age: 30), 100);
    });
  });

  group('GameScoring - Memory Score', () {
    test('Should reward performance above expectations', () {
      // Age 30 expected level is 6
      final scoreExpected = GameScoring.memoryScore(level: 6, rawScore: 0, age: 30);
      final scoreBetter = GameScoring.memoryScore(level: 7, rawScore: 0, age: 30);
      
      expect(scoreExpected, 70);
      expect(scoreBetter, 80);
    });
  });

  group('GameScoring - Stroop Executive Score', () {
    test('Should combine accuracy and reaction time correctly', () {
      final score = GameScoring.stroopExecutiveScore(
        correct: 20,
        total: 20,
        avgMs: 300,
        age: 30,
      );
      expect(score, greaterThan(90));
    });
  });
}
