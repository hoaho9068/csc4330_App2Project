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

  // Each invader in the main formation bounces off the arena margins on its
  // own (see GameState._updateInvaders), independently of the rest of the
  // scattered formation, so a spread-out swarm doesn't destabilize a
  // shared bounding-box check. Unused by diving invaders.
  int direction = 1;
  final double width = GameConfig.invaderWidth;
  final double height = GameConfig.invaderHeight;

  Rect get rect => Rect.fromLTWH(x, y, width, height);

  int get points => row == 0 ? 30 : (row <= 2 ? 20 : 10);
}
