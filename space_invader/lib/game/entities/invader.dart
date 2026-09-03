import 'dart:ui';

import '../game_config.dart';

enum InvaderType { squid, crab, octopus }

class Invader {
  Invader({
    required this.col,
    required this.row,
    required this.x,
    required this.y,
    this.type = InvaderType.crab,
  });

  final int col;
  final int row;
  double x;
  double y;
  bool alive = true;
  final InvaderType type;
  final double width = GameConfig.invaderWidth;
  final double height = GameConfig.invaderHeight;

  Rect get rect => Rect.fromLTWH(x, y, width, height);

  int get points => row == 0 ? 30 : (row <= 2 ? 20 : 10);
}
