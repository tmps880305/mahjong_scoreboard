import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' show pi;

void main() {
  runApp(const MahjongScoreboardApp());
}

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
  Map<String, int> scores = {'東': 25000, '南': 25000, '西': 25000, '北': 25000};
  Map<String, String> names = {
    '東': 'プレイヤー1',
    '南': 'プレイヤー2',
    '西': 'プレイヤー3',
    '北': 'プレイヤー4',
  };
  Map<String, bool> riichiStatus = {
    '東': false,
    '南': false,
    '西': false,
    '北': false,
  };
  int riichiSticks = 0;
  String currentRound = '東2局';
  int honba = 1;

  @override
  void initState() {
    super.initState();
    // Lock orientation to portrait
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      scores = {
        '東': prefs.getInt('score_東') ?? 25000,
        '南': prefs.getInt('score_南') ?? 25000,
        '西': prefs.getInt('score_西') ?? 25000,
        '北': prefs.getInt('score_北') ?? 25000,
      };
      names = {
        '東': prefs.getString('name_東') ?? 'プレイヤー1',
        '南': prefs.getString('name_南') ?? 'プレイヤー2',
        '西': prefs.getString('name_西') ?? 'プレイヤー3',
        '北': prefs.getString('name_北') ?? 'プレイヤー4',
      };
      riichiStatus = {
        '東': prefs.getBool('riichi_東') ?? false,
        '南': prefs.getBool('riichi_南') ?? false,
        '西': prefs.getBool('riichi_西') ?? false,
        '北': prefs.getBool('riichi_北') ?? false,
      };
      riichiSticks = prefs.getInt('riichiSticks') ?? 0;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    scores.forEach((seat, score) => prefs.setInt('score_$seat', score));
    names.forEach((seat, name) => prefs.setString('name_$seat', name));
    riichiStatus.forEach(
      (seat, status) => prefs.setBool('riichi_$seat', status),
    );
    prefs.setInt('riichiSticks', riichiSticks);
  }

  void _declareRiichi(String seat) {
    if (!riichiStatus[seat]!) {
      setState(() {
        scores[seat] = scores[seat]! - 1000;
        riichiStatus[seat] = true;
        riichiSticks += 1;
      });
      _saveData();
    }
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
                      child: _buildPlayerCard('東', true, 0), // No rotation
                    ),
                    // Player 2 (南) - Right side, accounting for rotation
                    Positioned(
                      right: -1.5 * baseCardHeight,
                      bottom: 0.375 * baseCardWidth,
                      // Adjust for rotation: move up by card width
                      width: baseCardWidth,
                      height: baseCardHeight,
                      child: _buildPlayerCard(
                        '南',
                        false,
                        -pi / 2,
                      ), // 90 degrees counter-clockwise
                    ),
                    // Player 3 (西) - Top
                    Positioned(
                      top: 0,
                      right: 0,
                      width: baseCardWidth,
                      height: baseCardHeight,
                      child: _buildPlayerCard('西', false, pi), // 180 degrees
                    ),
                    // Player 4 (北) - Left side, accounting for rotation
                    Positioned(
                      left: -1.5 * baseCardHeight,
                      top: 0.375 * baseCardWidth,
                      // Adjust for rotation: move down by card width
                      width: baseCardWidth,
                      height: baseCardHeight,
                      child: _buildPlayerCard(
                        '北',
                        false,
                        pi / 2,
                      ), // 90 degrees clockwise
                    ),
                    // Center pad
                    Center(
                      child: Container(
                        width: containerSize * 0.45,
                        height: containerSize * 0.45,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final fontSize = constraints.maxWidth * 0.3;
                                return Text(
                                  currentRound,
                                  style: TextStyle(
                                    fontFamily: 'NotoSansJP',
                                    fontSize: fontSize,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              },
                            ),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final fontSize = constraints.maxWidth * 0.2;
                                return Text(
                                  '$honba 本場',
                                  style: TextStyle(
                                    fontFamily: 'NotoSansJP',
                                    fontSize: fontSize * 0.5,
                                    color: const Color(0xFFFFD700),
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              },
                            ),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final fontSize = constraints.maxWidth * 0.2;
                                return Text(
                                  '托 $riichiSticks 本',
                                  style: TextStyle(
                                    fontFamily: 'NotoSansJP',
                                    fontSize: fontSize * 0.5,
                                    color: const Color(0xFFFFD700),
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom right settings button
          Positioned(
            bottom: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white, size: 32),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(String seat, bool isDealer, double contentRotation) {
    return Transform.rotate(
      angle: contentRotation,
      child: Container(
        decoration: BoxDecoration(
          gradient: isDealer
              ? const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isDealer ? null : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: isDealer
              ? Border.all(color: const Color(0xFFFFD700), width: 2)
              : null,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Use real constraints, not screen width, to size inner content
            final cardW = constraints.maxWidth;
            final cardH = constraints.maxHeight;

            // Your padding is 2% of card width on all sides
            final pad = cardW * 0.02;
            final innerH = (cardH - pad * 2).clamp(0.0, double.infinity);
            final innerW = (cardW - pad * 2).clamp(0.0, double.infinity);

            // Keep your visual scales based on height like before
            final seatFont = cardH * 0.7;
            final scoreFont = cardH * 0.5;
            final barW = innerW * 0.6;
            final barH = barW / 20;

            return Padding(
              padding: EdgeInsets.all(pad),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Seat label
                  Container(
                    width: seatFont * 1.4,
                    height: seatFont * 1.4,
                    // decoration: BoxDecoration(
                    //   border: Border.all(color: Colors.red, width: 2),
                    // ),
                    alignment: Alignment.center,
                    child: Text(
                      seat,
                      style: TextStyle(
                        fontFamily: 'NotoSansJP',
                        fontSize: seatFont,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                  SizedBox(width: cardW * 0.05),
                  // Right side content
                  Expanded(
                    child: SizedBox(
                      height: innerH,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Score
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${scores[seat]}',
                              style: TextStyle(
                                fontFamily: 'NotoSansJP',
                                fontSize: scoreFont,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          // Riichi bar
                          GestureDetector(
                            onTap: () => _declareRiichi(seat),
                            child: Container(
                              width: barW,
                              height: barH,
                              decoration: BoxDecoration(
                                color: riichiStatus[seat]!
                                    ? const Color(0xFFFFCA28)
                                    : const Color(0xFFFFFFFF),
                                borderRadius: BorderRadius.circular(4),
                                border: riichiStatus[seat]!
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                              ),
                              child: Center(
                                child: Container(
                                  width: barH * 0.7,
                                  height: barH * 0.7,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFFF0000),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
