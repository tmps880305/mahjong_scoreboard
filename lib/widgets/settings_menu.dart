import 'package:flutter/material.dart';

class SettingsMenu extends StatelessWidget {
  final VoidCallback onNewGame;

  const SettingsMenu({super.key, required this.onNewGame});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Builder(
        builder: (buttonContext) {
          return IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 32),
            onPressed: () async {
              // Find the button’s position on screen
              final RenderBox button =
                  buttonContext.findRenderObject() as RenderBox;
              final RenderBox overlay =
                  Overlay.of(context).context.findRenderObject() as RenderBox;
              final RelativeRect position = RelativeRect.fromRect(
                Rect.fromPoints(
                  button.localToGlobal(Offset.zero, ancestor: overlay),
                  button.localToGlobal(
                    button.size.bottomRight(Offset.zero),
                    ancestor: overlay,
                  ),
                ),
                Offset.zero & overlay.size,
              );

              final value = await showMenu<String>(
                context: context,
                position: position,
                items: [
                  const PopupMenuItem(
                    value: 'new_game',
                    child: Text('New Game', style: TextStyle(fontSize: 24)),
                  ),
                  const PopupMenuItem(
                    value: 'default_player',
                    child: Text('Default Player', style: TextStyle(fontSize: 24)),
                  ),
                  const PopupMenuItem(
                    value: 'game_setting',
                    child: Text('Game Setting', style: TextStyle(fontSize: 24)),
                  ),
                ],
                elevation: 8,
              );

              if (value == 'new_game') {
                onNewGame();
              } else if (value == 'default_player') {
                // TODO: Implement reset to default players
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Default Player selected')),
                );
              } else if (value == 'game_setting') {
                // TODO: Implement game settings dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Game Setting selected')),
                );
              }
            },
          );
        },
      ),
    );
  }
}
