import 'dart:math';

class GameScoring {
  static int clampScore(num v) {
    return v.isNaN ? 0 : v.clamp(0, 100).toInt();
  }

  static int ageBand(int? age) {
    final a = age ?? 30;
    if (a <= 12) return 0;
    if (a <= 17) return 1;
    if (a <= 34) return 2;
    if (a <= 49) return 3;
    if (a <= 64) return 4;
    return 5;
  }

  static int expectedReactionMs(int? age) {
    const bands = [320, 300, 280, 300, 330, 380];
    return bands[ageBand(age)];
  }

  static int reactionScoreFromAvgMs(int avgMs, {int? age, int penalty = 0}) {
    final norm = expectedReactionMs(age);
    final ratio = avgMs / max(1, norm);
    final score = 100 - ((ratio - 1) * 60);
    return clampScore(score - penalty);
  }

  static int expectedFluencyCount(int? age) {
    const bands = [10, 14, 18, 17, 15, 12];
    return bands[ageBand(age)];
  }

  static int fluencyScore(int count, {int? age}) {
    final expected = expectedFluencyCount(age);
    final ratio = count / max(1, expected);
    final score = ratio * 90;
    return clampScore(score);
  }

  static int expectedMemoryLevel(int? age) {
    const bands = [4, 5, 6, 6, 5, 4];
    return bands[ageBand(age)];
  }

  static int memoryScore({
    required int level,
    required int rawScore,
    int? age,
  }) {
    final expected = expectedMemoryLevel(age);
    final delta = level - expected;
    final score = 70 + (delta * 10) + (rawScore / 250);
    return clampScore(score);
  }

  static int stroopExecutiveScore({
    required int correct,
    required int total,
    required int avgMs,
    int? age,
  }) {
    final acc = total <= 0 ? 0 : correct / total;
    final rt = reactionScoreFromAvgMs(avgMs, age: age);
    final score = (acc * 65 * 100 / 100) + (rt * 0.35);
    return clampScore(score);
  }
}
