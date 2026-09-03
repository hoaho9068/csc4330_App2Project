import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'entities/bullet.dart';
import 'entities/invader.dart';
import 'entities/player.dart';
import 'game_config.dart';

enum GameStatus { playing, gameOver, won }

class GameState extends ChangeNotifier {
  Size _arenaSize = Size.zero;
  late Player player;
  final List<Invader> invaders = [];
  final List<Bullet> bullets = [];

  // Bonus invaders that drop from the top of the arena straight down and
  // disappear once they pass the bottom edge. Kept separate from the main
  // `invaders` grid so they don't affect the win/game-over conditions.
  final List<Invader> divingInvaders = [];

  int score = 0;
  int lives = GameConfig.initialLives;
  GameStatus status = GameStatus.playing;

  int _direction = 1;
  double _invaderSpeed = GameConfig.baseInvaderSpeed;
  double _playerFireCooldown = GameConfig.playerFireInterval;
  double _invaderFireCooldown = 1.0;
  double _divingSpawnCooldown = GameConfig.divingInvaderMinInterval;
  final Random _random = Random();

  bool get _initialized => _arenaSize != Size.zero;

  void initArena(Size size) {
    if (_initialized) return;
    _arenaSize = size;
    _buildLevel();
  }

  void restart() {
    score = 0;
    lives = GameConfig.initialLives;
    status = GameStatus.playing;
    _direction = 1;
    _invaderSpeed = GameConfig.baseInvaderSpeed;
    _playerFireCooldown = GameConfig.playerFireInterval;
    _invaderFireCooldown = 1.0;
    _divingSpawnCooldown = GameConfig.divingInvaderMinInterval;
    bullets.clear();
    divingInvaders.clear();
    _buildLevel();
    notifyListeners();
  }

  void _buildLevel() {
    invaders.clear();
    final totalWidth =
        GameConfig.cols * (GameConfig.invaderWidth + GameConfig.invaderSpacing);
    final startX = (_arenaSize.width - totalWidth) / 2;
    const startY = 60.0;
    for (var row = 0; row < GameConfig.rows; row++) {
      for (var col = 0; col < GameConfig.cols; col++) {
        invaders.add(Invader(
          col: col,
          row: row,
          x: startX + col * (GameConfig.invaderWidth + GameConfig.invaderSpacing),
          y: startY + row * (GameConfig.invaderHeight + GameConfig.invaderSpacing),
        ));
      }
    }
    player = Player(
      x: (_arenaSize.width - GameConfig.playerWidth) / 2,
      y: _arenaSize.height - GameConfig.playerBottomMargin,
    );
  }

  void movePlayer(double dx) {
    if (status != GameStatus.playing || !_initialized) return;
    player.moveBy(dx, 0, _arenaSize.width - player.width);
    notifyListeners();
  }

  void update(double dt) {
    if (status != GameStatus.playing || !_initialized) return;
    dt = dt > GameConfig.maxDt ? GameConfig.maxDt : dt;

    _updatePlayerFire(dt);
    _updateInvaders(dt);
    _updateInvaderFire(dt);
    _updateDivingInvaders(dt);
    _updateBullets(dt);
    _handleCollisions();
    _checkEndConditions();

    notifyListeners();
  }

  void _updatePlayerFire(double dt) {
    _playerFireCooldown -= dt;
    if (_playerFireCooldown <= 0) {
      bullets.add(Bullet(
        x: player.rect.center.dx - GameConfig.bulletWidth / 2,
        y: player.rect.top - GameConfig.bulletHeight,
        owner: BulletOwner.player,
      ));
      _playerFireCooldown = GameConfig.playerFireInterval;
    }
  }

  void _updateInvaders(double dt) {
    final alive = invaders.where((i) => i.alive).toList();
    if (alive.isEmpty) return;

    for (final inv in alive) {
      inv.x += _direction * _invaderSpeed * dt;
    }

    final minX = alive.map((i) => i.x).reduce(min);
    final maxX = alive.map((i) => i.x + i.width).reduce(max);
    if (minX <= GameConfig.arenaMargin ||
        maxX >= _arenaSize.width - GameConfig.arenaMargin) {
      _direction *= -1;
      for (final inv in alive) {
        inv.y += GameConfig.stepDown;
      }
    }

    final killedFraction = 1 - alive.length / (GameConfig.rows * GameConfig.cols);
    _invaderSpeed = GameConfig.baseInvaderSpeed +
        (GameConfig.maxInvaderSpeed - GameConfig.baseInvaderSpeed) * killedFraction;
  }

  // Spawns bonus invaders at the top of the arena at random intervals and
  // advances any that are currently falling. Each one moves straight down
  // and is removed once it drops past the bottom edge of the screen.
  void _updateDivingInvaders(double dt) {
    _divingSpawnCooldown -= dt;
    if (_divingSpawnCooldown <= 0) {
      final spawnX = GameConfig.arenaMargin +
          _random.nextDouble() *
              (_arenaSize.width - GameConfig.arenaMargin * 2 - GameConfig.invaderWidth);
      divingInvaders.add(Invader(
        col: -1,
        row: -1,
        x: spawnX,
        y: -GameConfig.invaderHeight,
        type: InvaderType.octopus,
      ));
      _divingSpawnCooldown = GameConfig.divingInvaderMinInterval +
          _random.nextDouble() *
              (GameConfig.divingInvaderMaxInterval - GameConfig.divingInvaderMinInterval);
    }

    for (final diver in divingInvaders) {
      diver.y += GameConfig.divingInvaderSpeed * dt;
    }

    // Hide/disappear once fully past the bottom of the screen.
    divingInvaders.removeWhere((diver) => diver.y > _arenaSize.height);
  }

  void _updateInvaderFire(double dt) {
    _invaderFireCooldown -= dt;
    if (_invaderFireCooldown <= 0) {
      final alive = invaders.where((i) => i.alive).toList();
      if (alive.isNotEmpty) {
        final shooter = alive[_random.nextInt(alive.length)];
        bullets.add(Bullet(
          x: shooter.rect.center.dx - GameConfig.bulletWidth / 2,
          y: shooter.rect.bottom,
          owner: BulletOwner.invader,
        ));
      }
      _invaderFireCooldown = GameConfig.invaderFireMinInterval +
          _random.nextDouble() *
              (GameConfig.invaderFireMaxInterval - GameConfig.invaderFireMinInterval);
    }
  }

  void _updateBullets(double dt) {
    for (final b in bullets) {
      b.update(dt);
    }
    bullets.removeWhere((b) => b.y + b.height < 0 || b.y > _arenaSize.height);
  }

  void _handleCollisions() {
    bullets.removeWhere((bullet) {
      if (bullet.owner == BulletOwner.player) {
        for (final inv in invaders) {
          if (inv.alive && inv.rect.overlaps(bullet.rect)) {
            inv.alive = false;
            score += inv.points;
            return true;
          }
        }
        for (final diver in divingInvaders) {
          if (diver.rect.overlaps(bullet.rect)) {
            divingInvaders.remove(diver);
            score += GameConfig.divingInvaderPoints;
            return true;
          }
        }
      } else {
        if (bullet.rect.overlaps(player.rect)) {
          lives -= 1;
          if (lives <= 0) status = GameStatus.gameOver;
          return true;
        }
      }
      return false;
    });
  }

  void _checkEndConditions() {
    if (status != GameStatus.playing) return;
    if (invaders.every((i) => !i.alive)) {
      status = GameStatus.won;
      return;
    }
    final invasionLine = player.y;
    if (invaders.any((i) => i.alive && i.y + i.height >= invasionLine)) {
      status = GameStatus.gameOver;
    }
  }
}
