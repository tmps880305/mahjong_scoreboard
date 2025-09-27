import 'package:shared_preferences/shared_preferences.dart';
import 'game_storage.dart';

class GameService {
  static Future<Map<String, dynamic>> ensureFirstBootInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    final initialized = prefs.getBool('initialized') ?? false;
    if (!initialized) {
      await GameStorage.save(
        scores: {'bottom': 25000, 'right': 25000, 'top': 25000, 'left': 25000},
        names: {
          'bottom': 'プレイヤー1',
          'right': 'プレイヤー2',
          'top': 'プレイヤー3',
          'left': 'プレイヤー4',
        },
        riichiStatus: {
          'bottom': false,
          'right': false,
          'top': false,
          'left': false,
        },
        riichiSticks: 0,
        currentRound: '東1局',
        honba: 0,
        seatWind: {'bottom': '東', 'right': '南', 'top': '西', 'left': '北'},
      );
      await prefs.setBool('initialized', true);
    }

    return GameStorage.load();
  }

  /// Reset everything to init state (new game)
  static Future<Map<String, dynamic>> resetGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool('initialized', true);

    await GameStorage.save(
      scores: {'bottom': 25000, 'right': 25000, 'top': 25000, 'left': 25000},
      names: {
        'bottom': 'プレイヤー1',
        'right': 'プレイヤー2',
        'top': 'プレイヤー3',
        'left': 'プレイヤー4',
      },
      riichiStatus: {
        'bottom': false,
        'right': false,
        'top': false,
        'left': false,
      },
      riichiSticks: 0,
      currentRound: '東1局',
      honba: 0,
      seatWind: {'bottom': '東', 'right': '南', 'top': '西', 'left': '北'},
    );

    return GameStorage.load();
  }

  /// Shortcut to load
  static Future<Map<String, dynamic>> loadData() async {
    return GameStorage.load();
  }

  /// Shortcut to save
  static Future<void> saveData({
    required Map<String, int> scores,
    required Map<String, String> names,
    required Map<String, bool> riichiStatus,
    required int riichiSticks,
    required String currentRound,
    required int honba,
    required Map<String, String> seatWind,
  }) async {
    await GameStorage.save(
      scores: scores,
      names: names,
      riichiStatus: riichiStatus,
      riichiSticks: riichiSticks,
      currentRound: currentRound,
      honba: honba,
      seatWind: seatWind,
    );
  }
}
