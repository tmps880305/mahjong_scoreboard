import 'package:shared_preferences/shared_preferences.dart';

class GameStorage {
  static Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();

    // seat-based names (preferred)
    final seatNamesExist =
        prefs.containsKey('name_bottom') ||
        prefs.containsKey('name_right') ||
        prefs.containsKey('name_top') ||
        prefs.containsKey('name_left');

    final names = seatNamesExist
        ? {
            'bottom': prefs.getString('name_bottom') ?? 'プレイヤー1',
            'right': prefs.getString('name_right') ?? 'プレイヤー2',
            'top': prefs.getString('name_top') ?? 'プレイヤー3',
            'left': prefs.getString('name_left') ?? 'プレイヤー4',
          }
        : {
            'bottom': prefs.getString('name_東') ?? 'プレイヤー1',
            'right': prefs.getString('name_南') ?? 'プレイヤー2',
            'top': prefs.getString('name_西') ?? 'プレイヤー3',
            'left': prefs.getString('name_北') ?? 'プレイヤー4',
          };

    return {
      'scores': {
        'bottom': prefs.getInt('score_bottom') ?? 25000,
        'right': prefs.getInt('score_right') ?? 25000,
        'top': prefs.getInt('score_top') ?? 25000,
        'left': prefs.getInt('score_left') ?? 25000,
      },
      'names': names,
      'riichiStatus': {
        'bottom': prefs.getBool('riichi_bottom') ?? false,
        'right': prefs.getBool('riichi_right') ?? false,
        'top': prefs.getBool('riichi_top') ?? false,
        'left': prefs.getBool('riichi_left') ?? false,
      },
      'riichiSticks': prefs.getInt('riichiSticks') ?? 0,
      'currentRound': prefs.getString('currentRound') ?? '東1局',
      'honba': prefs.getInt('honba') ?? 0,
    };
  }

  static Future<void> save({
    required Map<String, int> scores,
    required Map<String, String> names,
    required Map<String, bool> riichiStatus,
    required int riichiSticks,
    required String currentRound,
    required int honba,
    required Map<String, String> seatWind,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in scores.entries) {
      await prefs.setInt('score_${entry.key}', entry.value);
    }
    for (final entry in names.entries) {
      await prefs.setString('name_${entry.key}', entry.value);
    }
    for (final entry in riichiStatus.entries) {
      await prefs.setBool('riichi_${entry.key}', entry.value);
    }
    await prefs.setInt('riichiSticks', riichiSticks);
    await prefs.setString('currentRound', currentRound);
    await prefs.setInt('honba', honba);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
