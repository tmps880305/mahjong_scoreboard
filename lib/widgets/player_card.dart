import 'package:flutter/material.dart';

class PlayerCard extends StatelessWidget {
  final String seatPos;
  final bool isDealer;
  final double contentRotation;

  final Map<String, int> scores;
  final Map<String, String> names;
  final Map<String, bool> riichiStatus;
  final Map<String, String> seatWind;

  final void Function(String) onTapCard; // will call parent _enterScoringMode
  final void Function(String) onTapName; // will call parent _editPlayerName
  final void Function(String) onToggleRiichi; // will call parent _toggleRiichi

  const PlayerCard({
    super.key,
    required this.seatPos,
    required this.isDealer,
    required this.contentRotation,
    required this.scores,
    required this.names,
    required this.riichiStatus,
    required this.seatWind,
    required this.onTapCard,
    required this.onTapName,
    required this.onToggleRiichi,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: contentRotation,
      child: GestureDetector(
        onTap: () => onTapCard(seatPos),
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
              final scoreFont = cardH * 0.4;
              final barW = innerW * 0.6;
              final barH = barW / 20;

              final windLabel = seatWind[seatPos] ?? '東';

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
                        windLabel,
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
                            // Player name
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              // ensure this area captures the tap
                              onTap: () => onTapName(seatPos),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  names[seatPos] ?? '',
                                  style: TextStyle(
                                    fontFamily: 'NotoSansJP',
                                    fontSize: scoreFont * 0.25,
                                    // slightly smaller than score
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            // Score
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${scores[seatPos] ?? 0}',
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
                              onTap: () => onToggleRiichi(seatPos),
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 150),
                                opacity: (riichiStatus[seatPos] ?? false)
                                    ? 1.0
                                    : 0.3,
                                child: Container(
                                  width: barW,
                                  height: barH,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFFFF),
                                    borderRadius: BorderRadius.circular(4),
                                    border: (riichiStatus[seatPos] ?? false)
                                        ? Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          )
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
      ),
    );
  }
}
