import 'package:fitforge/core/utils/workout_duration_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime.utc(2026, 8, 20, 18);

  test('keeps wall clock when the session ended soon after the last set', () {
    final last = start.add(const Duration(minutes: 55));
    final resolved = WorkoutDurationGuard.resolve(
      wallClockMinutes: 58,
      startedAt: start,
      lastActivityAt: last,
    );
    expect(resolved.minutes, 58);
    expect(resolved.trimmed, isFalse);
  });

  test('trims overnight idle after the last set', () {
    final last = start.add(const Duration(minutes: 70));
    final resolved = WorkoutDurationGuard.resolve(
      wallClockMinutes: 14 * 60,
      startedAt: start,
      lastActivityAt: last,
    );
    // 70 min of work + 3 min rest buffer
    expect(resolved.minutes, 73);
    expect(resolved.trimmed, isTrue);
    expect(resolved.trimmedMinutes, greaterThan(10 * 60));
  });

  test('caps strength sessions at 4 hours even without last activity', () {
    final resolved = WorkoutDurationGuard.resolve(
      wallClockMinutes: 20 * 60,
      startedAt: start,
    );
    expect(resolved.minutes, WorkoutDurationGuard.maxStrengthMinutes);
  });

  test('does not trim runner/hyrox to last set', () {
    final last = start.add(const Duration(minutes: 30));
    final resolved = WorkoutDurationGuard.resolve(
      wallClockMinutes: 95,
      startedAt: start,
      lastActivityAt: last,
      skipIdleTrim: true,
    );
    expect(resolved.minutes, 95);
  });

  test('pauses after 25 minutes idle unless rest is running', () {
    final last = start;
    expect(
      WorkoutDurationGuard.shouldPauseForIdle(
        lastActivityAt: last,
        now: last.add(const Duration(minutes: 25)),
      ),
      isTrue,
    );
    expect(
      WorkoutDurationGuard.shouldPauseForIdle(
        lastActivityAt: last,
        now: last.add(const Duration(minutes: 24)),
      ),
      isFalse,
    );
    expect(
      WorkoutDurationGuard.shouldPauseForIdle(
        lastActivityAt: last,
        now: last.add(const Duration(minutes: 40)),
        restTimerActive: true,
      ),
      isFalse,
    );
  });
}
