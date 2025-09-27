import 'package:flutter/material.dart';

class CenterPad extends StatelessWidget {
  final String currentRound;
  final int honba;
  final int riichiSticks;
  final double containerSize; // container size

  const CenterPad({
    super.key,
    required this.currentRound,
    required this.honba,
    required this.riichiSticks,
    required this.containerSize,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}
