import 'dart:ui';

import '../game_config.dart';

class Player {
  Player({required this.x, required this.y});

  double x;
  final double y;
  final double width = GameConfig.playerWidth;
  final double height = GameConfig.playerHeight;

  Rect get rect => Rect.fromLTWH(x, y, width, height);

  void moveBy(double dx, double minX, double maxX) {
    x = (x + dx).clamp(minX, maxX);
  }
}
