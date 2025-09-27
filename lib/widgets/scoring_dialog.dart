import 'package:flutter/material.dart';

class ScoringDialog extends StatefulWidget {
  final String winnerSeat;
  final String winnerName;
  final bool isWinnerDealer;
  final Map<String, String> seatWind;

  const ScoringDialog({
    super.key,
    required this.winnerSeat,
    required this.winnerName,
    required this.isWinnerDealer,
    required this.seatWind,
  });

  @override
  State<ScoringDialog> createState() => _ScoringDialogState();
}

class _ScoringDialogState extends State<ScoringDialog> {
  // these lived in _enterScoringMode before; they belong to the dialog UI
  final pointsCtrl = TextEditingController();
  final tsumoDealerCtrl = TextEditingController();
  String? selected;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
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
                  widget.winnerName,
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
                      if (selected == 'tsumo' && !widget.isWinnerDealer) ...[
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
                      ...widget.seatWind.entries
                          .where(
                            (e) => e.key != widget.winnerSeat,
                          ) // exclude winner
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
                          if (!widget.isWinnerDealer) {
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
    );
  }
}
