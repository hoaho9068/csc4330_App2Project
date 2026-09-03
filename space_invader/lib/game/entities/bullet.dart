import 'dart:ui';

import '../game_config.dart';

enum BulletOwner { player, invader }

class Bullet {
  Bullet({required this.x, required this.y, required this.owner});

  double x;
  double y;
  final BulletOwner owner;
  final double width = GameConfig.bulletWidth;
  final double height = GameConfig.bulletHeight;

  Rect get rect => Rect.fromLTWH(x, y, width, height);

  void update(double dt) {
    final speed = owner == BulletOwner.player
        ? -GameConfig.playerBulletSpeed
        : GameConfig.invaderBulletSpeed;
    y += speed * dt;
  }
}
