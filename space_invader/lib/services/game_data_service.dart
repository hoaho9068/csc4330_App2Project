import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.name,
    required this.score,
    required this.wave,
    required this.date,
  });

  final String name;
  final int score;
  final int wave;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'wave': wave,
        'date': date.toIso8601String(),
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        name: json['name'] as String? ?? 'Player',
        score: json['score'] as int,
        wave: json['wave'] as int,
        date: DateTime.parse(json['date'] as String),
      );
}

class PlayerStats {
  const PlayerStats({
    this.name = 'Player',
    this.gamesPlayed = 0,
    this.highScore = 0,
    this.bestWave = 0,
  });

  final String name;
  final int gamesPlayed;
  final int highScore;
  final int bestWave;

  PlayerStats copyWith({String? name, int? gamesPlayed, int? highScore, int? bestWave}) =>
      PlayerStats(
        name: name ?? this.name,
        gamesPlayed: gamesPlayed ?? this.gamesPlayed,
        highScore: highScore ?? this.highScore,
        bestWave: bestWave ?? this.bestWave,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'gamesPlayed': gamesPlayed,
        'highScore': highScore,
        'bestWave': bestWave,
      };

  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
        name: json['name'] as String? ?? 'Player',
        gamesPlayed: json['gamesPlayed'] as int? ?? 0,
        highScore: json['highScore'] as int? ?? 0,
        bestWave: json['bestWave'] as int? ?? 0,
      );
}

// Persists player stats and a local leaderboard of past runs via
// shared_preferences. There's no backend or accounts — everything here
// lives only on this device.
class GameDataService {
  static const _statsKey = 'player_stats';
  static const _leaderboardKey = 'leaderboard';
  static const _maxLeaderboardEntries = 20;

  Future<PlayerStats> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statsKey);
    if (raw == null) return const PlayerStats();
    return PlayerStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveStats(PlayerStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statsKey, jsonEncode(stats.toJson()));
  }

  Future<List<LeaderboardEntry>> loadLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_leaderboardKey);
    if (raw == null) return [];
    final entries = raw
        .map((s) => LeaderboardEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    entries.sort((a, b) => b.score.compareTo(a.score));
    return entries;
  }

  // Records a finished game under the given name: adds it to the
  // leaderboard and updates the player's aggregate stats, including saving
  // `name` as the current profile name (the player just typed it in on the
  // game-over screen, so it becomes their identity going forward too, same
  // as classic arcade high-score entry). Returns the updated stats.
  Future<PlayerStats> recordGameResult({
    required String name,
    required int score,
    required int wave,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final stats = await loadStats();

    final entries = await loadLeaderboard();
    entries.add(LeaderboardEntry(name: name, score: score, wave: wave, date: DateTime.now()));
    entries.sort((a, b) => b.score.compareTo(a.score));
    final trimmed = entries.take(_maxLeaderboardEntries).toList();
    await prefs.setStringList(
      _leaderboardKey,
      trimmed.map((e) => jsonEncode(e.toJson())).toList(),
    );

    final updated = stats.copyWith(
      name: name,
      gamesPlayed: stats.gamesPlayed + 1,
      highScore: score > stats.highScore ? score : stats.highScore,
      bestWave: wave > stats.bestWave ? wave : stats.bestWave,
    );
    await saveStats(updated);
    return updated;
  }
}
