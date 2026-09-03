import 'package:flutter/material.dart';

import 'entities/bullet.dart';
import 'game_state.dart';

class GamePainter extends CustomPainter {
  GamePainter(this.gameState) : super(repaint: gameState);

  final GameState gameState;

  @override
  void paint(Canvas canvas, Size size) {
    final invaderPaint = Paint()..color = Colors.greenAccent;
    final divingInvaderPaint = Paint()..color = Colors.orangeAccent;
    final playerPaint = Paint()..color = Colors.lightBlueAccent;
    final playerBulletPaint = Paint()..color = Colors.white;
    final invaderBulletPaint = Paint()..color = Colors.redAccent;

    for (final invader in gameState.invaders) {
      if (invader.alive) {
        canvas.drawRect(invader.rect, invaderPaint);
      }
    }

    // Bonus invaders that fall from the top of the screen and disappear
    // once they pass the bottom edge. Drawn in a distinct color so they
    // read as a different, "diving" enemy type.
    for (final diver in gameState.divingInvaders) {
      canvas.drawRect(diver.rect, divingInvaderPaint);
    }

    canvas.drawRect(gameState.player.rect, playerPaint);

    for (final bullet in gameState.bullets) {
      canvas.drawRect(
        bullet.rect,
        bullet.owner == BulletOwner.player ? playerBulletPaint : invaderBulletPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => false;
}
