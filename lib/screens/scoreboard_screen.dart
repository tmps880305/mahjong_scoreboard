import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mahjong_scoreboard/utils/dialog_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' show pi;

import '../widgets/center_pad.dart';
import '../widgets/player_card.dart';
import '../widgets/settings_menu.dart';

class MahjongScoreboardApp extends StatelessWidget {
  const MahjongScoreboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '麻雀点数盤',
      theme: ThemeData(
        primaryColor: const Color(0xFF4CAF50),
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        fontFamily: 'NotoSansJP',
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      ),
      home: const ScoreboardScreen(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class ScoreboardScreen extends StatefulWidget {
  const ScoreboardScreen({super.key});

  @override
  _ScoreboardScreenState createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  final List<String> seatOrder = ['bottom', 'right', 'top', 'left'];

  Map<String, String> names = {
    'bottom': 'プレイヤー1',
    'right': 'プレイヤー2',
    'top': 'プレイヤー3',
    'left': 'プレイヤー4',
  };

  // Scores tied to physical seats
  Map<String, int> scores = {
    'bottom': 25000,
    'right': 25000,
    'top': 25000,
    'left': 25000,
  };

  // Riichi status tied to seats
  Map<String, bool> riichiStatus = {
    'bottom': false,
    'right': false,
    'top': false,
    'left': false,
  };

  // Winds mapping to seats (rotates)
  Map<String, String> seatWind = {
    'bottom': '東',
    'right': '南',
    'top': '西',
    'left': '北',
  };

  // Helpers to avoid nulls
  bool isRiichiOn(String seatPos) => riichiStatus[seatPos] ?? false;

  int seatScore(String seatPos) => scores[seatPos] ?? 0;

  String windLabel(String seatPos) => seatWind[seatPos] ?? '東';

  String currentRound = '東1局';
  int honba = 0;
  int riichiSticks = 0;

  String get dealerSeat {
    try {
      return seatWind.entries.firstWhere((e) => e.value == '東').key;
    } catch (_) {
      return 'bottom'; // fallback if mapping was broken
    }
  }

  void _rotateWindsClockwise() {
    final b = seatWind['bottom'] ?? '東';
    final r = seatWind['right'] ?? '南';
    final t = seatWind['top'] ?? '西';
    final l = seatWind['left'] ?? '北';

    // clockwise rotation of winds over seats
    seatWind['bottom'] = l; // left → bottom
    seatWind['right'] = b; // bottom → right
    seatWind['top'] = r; // right → top
    seatWind['left'] = t; // top → left
  }

  @override
  void initState() {
    super.initState();
    // Lock orientation to portrait
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _loadData().then((_) => _ensureFirstBootInitialized());
  }

  Future<void> _ensureFirstBootInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    final initialized = prefs.getBool('initialized') ?? false;
    if (!initialized) {
      setState(() {
        scores = {'bottom': 25000, 'right': 25000, 'top': 25000, 'left': 25000};
        riichiStatus = {
          'bottom': false,
          'right': false,
          'top': false,
          'left': false,
        };
        names = {
          'bottom': 'プレイヤー1',
          'right': 'プレイヤー2',
          'top': 'プレイヤー3',
          'left': 'プレイヤー4',
        };
        seatWind = {'bottom': '東', 'right': '南', 'top': '西', 'left': '北'};
        currentRound = '東1局';
        honba = 0;
        riichiSticks = 0;
      });
      await _saveData();
    }
  }

  Future<void> _resetGame() async {
    setState(() {
      scores = {'bottom': 25000, 'right': 25000, 'top': 25000, 'left': 25000};
      riichiStatus = {
        'bottom': false,
        'right': false,
        'top': false,
        'left': false,
      };
      names = {
        'bottom': 'プレイヤー1',
        'right': 'プレイヤー2',
        'top': 'プレイヤー3',
        'left': 'プレイヤー4',
      };
      seatWind = {'bottom': '東', 'right': '南', 'top': '西', 'left': '北'};
      currentRound = '東1局';
      honba = 0;
      riichiSticks = 0;
    });
    await _saveData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // seat-based names (preferred)
    final seatNamesExist =
        prefs.containsKey('name_bottom') ||
        prefs.containsKey('name_right') ||
        prefs.containsKey('name_top') ||
        prefs.containsKey('name_left');

    if (seatNamesExist) {
      names = {
        'bottom': prefs.getString('name_bottom') ?? 'プレイヤー1',
        'right': prefs.getString('name_right') ?? 'プレイヤー2',
        'top': prefs.getString('name_top') ?? 'プレイヤー3',
        'left': prefs.getString('name_left') ?? 'プレイヤー4',
      };
    } else {
      // MIGRATION from old wind-based name_東 etc., assuming start mapping
      names = {
        'bottom': prefs.getString('name_東') ?? 'プレイヤー1',
        'right': prefs.getString('name_南') ?? 'プレイヤー2',
        'top': prefs.getString('name_西') ?? 'プレイヤー3',
        'left': prefs.getString('name_北') ?? 'プレイヤー4',
      };
    }

    // Try seat-based keys first
    final hasSeatBased =
        prefs.containsKey('score_bottom') ||
        prefs.containsKey('score_right') ||
        prefs.containsKey('score_top') ||
        prefs.containsKey('score_left');

    setState(() {
      if (hasSeatBased) {
        // Seat-based load
        scores = {
          'bottom': prefs.getInt('score_bottom') ?? 25000,
          'right': prefs.getInt('score_right') ?? 25000,
          'top': prefs.getInt('score_top') ?? 25000,
          'left': prefs.getInt('score_left') ?? 25000,
        };
        riichiStatus = {
          'bottom': prefs.getBool('riichi_bottom') ?? false,
          'right': prefs.getBool('riichi_right') ?? false,
          'top': prefs.getBool('riichi_top') ?? false,
          'left': prefs.getBool('riichi_left') ?? false,
        };

        // Winds (fallback to default if not saved)
        seatWind = {
          'bottom': prefs.getString('wind_bottom') ?? '東',
          'right': prefs.getString('wind_right') ?? '南',
          'top': prefs.getString('wind_top') ?? '西',
          'left': prefs.getString('wind_left') ?? '北',
        };
      } else {
        // MIGRATION: From old wind-based keys to seat-based
        // Assume default starting assignment bottom=東, right=南, top=西, left=北
        scores = {
          'bottom': prefs.getInt('score_東') ?? 25000,
          'right': prefs.getInt('score_南') ?? 25000,
          'top': prefs.getInt('score_西') ?? 25000,
          'left': prefs.getInt('score_北') ?? 25000,
        };
        riichiStatus = {
          'bottom': prefs.getBool('riichi_東') ?? false,
          'right': prefs.getBool('riichi_南') ?? false,
          'top': prefs.getBool('riichi_西') ?? false,
          'left': prefs.getBool('riichi_北') ?? false,
        };
        seatWind = {'bottom': '東', 'right': '南', 'top': '西', 'left': '北'};
      }

      // Round info
      currentRound = prefs.getString('currentRound') ?? '東1局';
      honba = prefs.getInt('honba') ?? 0;
      riichiSticks = prefs.getInt('riichiSticks') ?? 0;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('name_bottom', names['bottom'] ?? 'プレイヤー1');
    await prefs.setString('name_right', names['right'] ?? 'プレイヤー2');
    await prefs.setString('name_top', names['top'] ?? 'プレイヤー3');
    await prefs.setString('name_left', names['left'] ?? 'プレイヤー4');

    await prefs.setInt('score_bottom', scores['bottom'] ?? 25000);
    await prefs.setInt('score_right', scores['right'] ?? 25000);
    await prefs.setInt('score_top', scores['top'] ?? 25000);
    await prefs.setInt('score_left', scores['left'] ?? 25000);

    await prefs.setBool('riichi_bottom', riichiStatus['bottom'] ?? false);
    await prefs.setBool('riichi_right', riichiStatus['right'] ?? false);
    await prefs.setBool('riichi_top', riichiStatus['top'] ?? false);
    await prefs.setBool('riichi_left', riichiStatus['left'] ?? false);

    await prefs.setString('wind_bottom', seatWind['bottom'] ?? '東');
    await prefs.setString('wind_right', seatWind['right'] ?? '南');
    await prefs.setString('wind_top', seatWind['top'] ?? '西');
    await prefs.setString('wind_left', seatWind['left'] ?? '北');

    await prefs.setString('currentRound', currentRound);
    await prefs.setInt('honba', honba);
    await prefs.setInt('riichiSticks', riichiSticks);
  }

  Future<void> _toggleRiichi(String seat) async {
    final wasOn = riichiStatus[seat] ?? false;
    final current = scores[seat] ?? 0;

    setState(() {
      if (!wasOn) {
        // Turn ON → pay 1000
        scores[seat] = current - 1000;
        riichiStatus[seat] = true;
        riichiSticks += 1;
      } else {
        // Turn OFF → refund 1000
        scores[seat] = current + 1000;
        riichiStatus[seat] = false;
        if (riichiSticks > 0) riichiSticks -= 1;
      }
    });

    // Save back to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    scores.forEach((seat, score) => prefs.setInt('score_$seat', score));
    riichiStatus.forEach(
      (seat, status) => prefs.setBool('riichi_$seat', status),
    );
    prefs.setInt('riichiSticks', riichiSticks);
  }

  Future<void> _editPlayerName(String seatPos) async {
    final controller = TextEditingController(text: names[seatPos] ?? '');

    //
    final newName = await showCustomDialog<String>(
      context: context,
      insetPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.20,
        vertical: MediaQuery.of(context).size.height * 0.10,
      ), // same margins as scoring dialog
      child: SizedBox(
        width:
            MediaQuery.of(context).size.width * 0.60, // same width as scoring
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min, // height fits content
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${seatWind[seatPos] ?? ''} の名前を変更',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'プレイヤー名',
                  hintText: '名前を入力',
                ),
                onSubmitted: (v) => Navigator.pop(context, v.trim()),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル'),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, controller.text.trim()),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (newName == null) return; // cancelled
    if (newName.isEmpty) return; // ignore empty names

    setState(() {
      names[seatPos] = newName;
    });
    await _saveData(); // you already persist names seat-based
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final containerSize = screenSize.width;
    final baseCardWidth = containerSize * 0.8;
    final baseCardHeight = baseCardWidth / 4;

    return Scaffold(
      body: Stack(
        children: [
          // Main game area with square container centered vertically
          Positioned.fill(
            child: Center(
              child: Container(
                width: containerSize,
                height: containerSize,
                child: Stack(
                  children: [
                    // Player 1 (東) - Bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      width: baseCardWidth,
                      height: baseCardHeight,
                      child: PlayerCard(
                        seatPos: 'bottom',
                        isDealer: seatWind['bottom'] == '東',
                        contentRotation: 0,
                        scores: scores,
                        names: names,
                        riichiStatus: riichiStatus,
                        seatWind: seatWind,
                        onTapCard: _enterScoringMode,
                        onTapName: _editPlayerName,
                        onToggleRiichi: _toggleRiichi,
                      ), // No rotation
                    ),
                    // Player 2 (南) - Right side, accounting for rotation
                    Positioned(
                      right: -1.5 * baseCardHeight,
                      bottom: 0.375 * baseCardWidth,
                      // Adjust for rotation: move up by card width
                      width: baseCardWidth,
                      height: baseCardHeight,
                      child: PlayerCard(
                        seatPos: 'right',
                        isDealer: seatWind['right'] == '東',
                        contentRotation: -pi / 2,
                        scores: scores,
                        names: names,
                        riichiStatus: riichiStatus,
                        seatWind: seatWind,
                        onTapCard: _enterScoringMode,
                        onTapName: _editPlayerName,
                        onToggleRiichi: _toggleRiichi,
                      ), // 90 degrees counter-clockwise
                    ),
                    // Player 3 (西) - Top
                    Positioned(
                      top: 0,
                      right: 0,
                      width: baseCardWidth,
                      height: baseCardHeight,
                      child: PlayerCard(
                        seatPos: 'top',
                        isDealer: seatWind['top'] == '東',
                        contentRotation: pi,
                        scores: scores,
                        names: names,
                        riichiStatus: riichiStatus,
                        seatWind: seatWind,
                        onTapCard: _enterScoringMode,
                        onTapName: _editPlayerName,
                        onToggleRiichi: _toggleRiichi,
                      ), // 180 degrees
                    ),
                    // Player 4 (北) - Left side, accounting for rotation
                    Positioned(
                      left: -1.5 * baseCardHeight,
                      top: 0.375 * baseCardWidth,
                      // Adjust for rotation: move down by card width
                      width: baseCardWidth,
                      height: baseCardHeight,
                      child: PlayerCard(
                        seatPos: 'left',
                        isDealer: seatWind['left'] == '東',
                        contentRotation: pi / 2,
                        scores: scores,
                        names: names,
                        riichiStatus: riichiStatus,
                        seatWind: seatWind,
                        onTapCard: _enterScoringMode,
                        onTapName: _editPlayerName,
                        onToggleRiichi: _toggleRiichi,
                      ), // 90 degrees clockwise
                    ),
                    // Center pad
                    CenterPad(
                      currentRound: currentRound,
                      honba: honba,
                      riichiSticks: riichiSticks,
                      containerSize: containerSize,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom right settings button
          SettingsMenu(onNewGame: _resetGame),
        ],
      ),
    );
  }

  Future<void> _enterScoringMode(String winnerSeat) async {
    String _nextWind(String wind) {
      switch (wind) {
        case '東':
          return '南';
        case '南':
          return '西';
        case '西':
          return '北';
        default:
          return '東';
      }
    }

    final pointsCtrl = TextEditingController();
    final tsumoDealerCtrl =
        TextEditingController(); // shown only when winner NOT dealer
    String? selected; // radio selection
    final isWinnerDealer = (seatWind[winnerSeat] == '東');

    // final controller = TextEditingController();

    // final winnerWind = seatWind[winnerSeat];

    final winnerName = names[winnerSeat] ?? seatWind[winnerSeat] ?? '';

    final result = await showCustomDialog<Map<String, dynamic>>(
      context: context,
      insetPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.20,
        vertical: MediaQuery.of(context).size.height * 0.10,
      ),
      child: StatefulBuilder(
        builder: (context, setState) {
          return SizedBox(
            width: MediaQuery.of(context).size.width * 0.60,
            height: MediaQuery.of(context).size.height * 0.80,
            child: Column(
              children: [
                // Title (we’ll switch to player name in section B)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    '得点入力', // we’ll append “<player name> 勝ち” below
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      // color: Colors.black,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    winnerName,
                    style: TextStyle(
                      fontFamily: 'NotoSansJP',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      // color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Base points (always visible)
                        TextField(
                          controller: pointsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '点数（基本）',
                            hintText: 'ロン / 親ツモ',
                          ),
                        ),

                        // Extra field appears ONLY when ツモ selected AND winner is NOT dealer
                        if (selected == 'tsumo' && !isWinnerDealer) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: tsumoDealerCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: '点数',
                              hintText: '親が支払う点数',
                            ),
                          ),
                        ],

                        const SizedBox(height: 48),
                        // Radios: other seats + ツモ
                        const Text(
                          '支払い元',
                          // style: TextStyle(color: Colors.black),
                        ),
                        ...seatWind.entries
                            .where((e) => e.key != winnerSeat) // exclude winner
                            .map(
                              (e) => RadioListTile<String>(
                                title: Text(e.value), // wind (東南西北)
                                value: e.key, // seatPos
                                groupValue: selected,
                                onChanged: (v) => setState(() => selected = v),
                              ),
                            ),
                        RadioListTile<String>(
                          title: const Text('ツモ'),
                          value: 'tsumo',
                          groupValue: selected,
                          onChanged: (v) => setState(() => selected = v),
                        ),
                      ],
                    ),
                  ),
                ),

                // Buttons pinned at bottom
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('キャンセル'),
                      ),
                      TextButton(
                        onPressed: () {
                          final base = int.tryParse(pointsCtrl.text);
                          if (selected == null || base == null) return;

                          if (selected == 'tsumo') {
                            // ツモ
                            final payload = <String, dynamic>{
                              'mode': 'tsumo',
                              'base': base,
                            };
                            if (!isWinnerDealer) {
                              // needs dealer amount
                              final dealerAmt = int.tryParse(
                                tsumoDealerCtrl.text ?? '',
                              );
                              if (dealerAmt == null)
                                return; // invalid; do nothing
                              payload['dealer'] = dealerAmt;
                            }
                            Navigator.pop(context, payload);
                          } else {
                            // RON vs selected loser seat
                            Navigator.pop(context, {
                              'mode': 'ron',
                              'base': base,
                              'loser': selected, // seatPos
                            });
                          }
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    void _advanceRound() {
      final m = RegExp(r'([東南西北])(\d)局').firstMatch(currentRound);
      String wind = m?.group(1) ?? '東';
      int num = int.tryParse(m?.group(2) ?? '1') ?? 1;

      if (num < 4) {
        num += 1;
      } else {
        wind = _nextWind(wind);
        num = 1;
      }
      currentRound = '$wind${num}局';
    }

    void _processScoringRon({
      required String winnerSeat, // 'bottom'|'right'|'top'|'left'
      required int points,
      required String loserSeat, // seatPos
    }) {
      final dealer = dealerSeat;
      final dealerWon = (winnerSeat == dealer);

      setState(() {
        // Winner gets points + all riichi sticks
        final bonus = riichiSticks * 1000;
        scores[winnerSeat] = (scores[winnerSeat] ?? 0) + points + bonus;

        // Loser pays points
        scores[loserSeat] = (scores[loserSeat] ?? 0) - points;

        // Reset riichi
        riichiSticks = 0;
        riichiStatus.updateAll((k, v) => false);

        // Round/dealer rules
        if (dealerWon) {
          honba += 1; // same 局, dealer stays
        } else {
          honba = 0;
          _advanceRound();
          _rotateWindsClockwise(); // dealer passes clockwise
        }
      });

      _saveData();
    }

    void _processScoringTsumo({
      required String winnerSeat,
      required int baseForNonDealerOrAll,
      int? dealerAmountIfNonDealerWins, // null when winner is dealer
    }) {
      final dealer = dealerSeat;
      final winnerIsDealer = (winnerSeat == dealer);

      // Build payer sets
      final others = [
        'bottom',
        'right',
        'top',
        'left',
      ].where((s) => s != winnerSeat).toList();

      setState(() {
        int totalTaken = 0;

        if (winnerIsDealer) {
          // All three others pay the same "base"
          for (final seat in others) {
            scores[seat] = (scores[seat] ?? 0) - baseForNonDealerOrAll;
            totalTaken += baseForNonDealerOrAll;
          }
        } else {
          // Winner is NOT dealer:
          // Two non-dealers (excluding dealer and winner) pay "base"
          final nonDealerLosers = others.where((s) => s != dealer).toList();
          for (final seat in nonDealerLosers) {
            scores[seat] = (scores[seat] ?? 0) - baseForNonDealerOrAll;
            totalTaken += baseForNonDealerOrAll;
          }
          // Dealer pays "dealerAmount"
          final dealerPay = dealerAmountIfNonDealerWins ?? 0;
          scores[dealer] = (scores[dealer] ?? 0) - dealerPay;
          totalTaken += dealerPay;
        }

        // Winner collects everything + riichi bonus
        final bonus = riichiSticks * 1000;
        scores[winnerSeat] = (scores[winnerSeat] ?? 0) + totalTaken + bonus;

        // Reset riichi
        riichiSticks = 0;
        riichiStatus.updateAll((k, v) => false);

        // Round/dealer rules:
        if (winnerIsDealer) {
          honba += 1; // dealer win → same 局
        } else {
          honba = 0;
          _advanceRound();
          _rotateWindsClockwise();
        }
      });

      _saveData();
    }

    if (result == null) return;

    // Route to handler
    final mode = result['mode'] as String;
    if (mode == 'ron') {
      _processScoringRon(
        winnerSeat: winnerSeat,
        points: result['base'] as int,
        loserSeat: result['loser'] as String,
      );
    } else {
      // tsumo
      final base = result['base'] as int;
      final dealerAmt = result.containsKey('dealer')
          ? result['dealer'] as int
          : null;
      _processScoringTsumo(
        winnerSeat: winnerSeat,
        baseForNonDealerOrAll: base,
        dealerAmountIfNonDealerWins: dealerAmt, // null when winner is dealer
      );
    }
  }
}
