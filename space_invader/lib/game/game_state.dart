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
  int wave = 1;

  double _invaderSpeed = GameConfig.baseInvaderSpeed;
  double _playerFireCooldown = GameConfig.playerFireInterval;
  double _invaderFireCooldown = 1.0;
  double _divingSpawnCooldown = GameConfig.divingInvaderMinInterval;
  final Random _random = Random();

  // Difficulty values for the current wave, recomputed once per wave (see
  // _applyWaveDifficulty) rather than every frame.
  double _waveBaseInvaderSpeed = GameConfig.baseInvaderSpeed;
  double _waveMaxInvaderSpeed = GameConfig.maxInvaderSpeed;
  double _waveInvaderFireMinInterval = GameConfig.invaderFireMinInterval;
  double _waveInvaderFireMaxInterval = GameConfig.invaderFireMaxInterval;
  double _waveDivingMinInterval = GameConfig.divingInvaderMinInterval;
  double _waveDivingMaxInterval = GameConfig.divingInvaderMaxInterval;
  double _waveDivingSpeed = GameConfig.divingInvaderSpeed;

  // The main invader formation trickles in over time instead of appearing
  // all at once. `_spawnedCount`/`_killedCount` track progress against the
  // eventual total (rows * cols) independently of `invaders.length`, since
  // dead invaders stay in the list.
  int _spawnedCount = 0;
  int _killedCount = 0;
  double _gridSpawnCooldown = 0;

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
    wave = 1;
    _playerFireCooldown = GameConfig.playerFireInterval;
    _divingSpawnCooldown = GameConfig.divingInvaderMinInterval;
    bullets.clear();
    divingInvaders.clear();
    _buildLevel();
    notifyListeners();
  }

  void _buildLevel() {
    invaders.clear();
    _spawnedCount = 0;
    _killedCount = 0;
    _gridSpawnCooldown = GameConfig.gridSpawnMinInterval;
    _applyWaveDifficulty();
    _invaderSpeed = _waveBaseInvaderSpeed;
    _invaderFireCooldown = 1.0;
    player = Player(
      x: (_arenaSize.width - GameConfig.playerWidth) / 2,
      y: _arenaSize.height - GameConfig.playerBottomMargin,
    );
  }

  // Recomputes this wave's difficulty knobs from GameConfig's base values and
  // the current wave number. Called once per wave (from _buildLevel), not
  // every frame.
  void _applyWaveDifficulty() {
    final n = wave - 1; // 0 at wave 1 => identical to GameConfig's defaults.
    _waveBaseInvaderSpeed = min(
      GameConfig.baseInvaderSpeed + GameConfig.waveSpeedIncrement * n,
      GameConfig.invaderSpeedCap,
    );
    _waveMaxInvaderSpeed = min(
      GameConfig.maxInvaderSpeed + GameConfig.waveSpeedIncrement * n,
      GameConfig.invaderSpeedCap,
    );

    final fireScale = pow(GameConfig.waveFireIntervalScale, n).toDouble();
    _waveInvaderFireMinInterval = max(
      GameConfig.invaderFireMinInterval * fireScale,
      GameConfig.minInvaderFireInterval,
    );
    _waveInvaderFireMaxInterval = max(
      GameConfig.invaderFireMaxInterval * fireScale,
      GameConfig.minInvaderFireInterval,
    );

    final divingScale = pow(GameConfig.waveDivingIntervalScale, n).toDouble();
    _waveDivingMinInterval = max(
      GameConfig.divingInvaderMinInterval * divingScale,
      GameConfig.minDivingInterval,
    );
    _waveDivingMaxInterval = max(
      GameConfig.divingInvaderMaxInterval * divingScale,
      GameConfig.minDivingInterval,
    );
    _waveDivingSpeed = min(
      GameConfig.divingInvaderSpeed + GameConfig.waveDivingSpeedIncrement * n,
      GameConfig.divingInvaderSpeedCap,
    );
  }

  // Trickles the main invader formation in over time instead of placing all
  // of them at once, so they appear scattered across the top at different
  // moments rather than all together at the start.
  void _updateGridSpawns(double dt) {
    final total = GameConfig.rows * GameConfig.cols;
    if (_spawnedCount >= total) return;

    _gridSpawnCooldown -= dt;
    if (_gridSpawnCooldown <= 0) {
      const topMargin = 40.0;
      // Kept well clear of the invasion line (player.y): spawning too deep
      // let some invaders start close enough that a handful of early bounces
      // (see below) could reach the player almost immediately.
      final bandHeight = _arenaSize.height * 0.35;
      // Keep spawns clear of the bounce margins so the formation doesn't
      // immediately hit an edge and start stepping down before play begins.
      final horizontalBuffer = _arenaSize.width * 0.12;
      final minX = GameConfig.arenaMargin + horizontalBuffer;
      final maxX =
          _arenaSize.width - GameConfig.arenaMargin - horizontalBuffer - GameConfig.invaderWidth;
      final placed = invaders.where((i) => i.alive).map((i) => i.rect).toList();
      final rect = _randomInvaderSpot(minX, maxX, topMargin, bandHeight, placed);

      invaders.add(Invader(
        col: _spawnedCount % GameConfig.cols,
        row: _spawnedCount ~/ GameConfig.cols,
        x: rect.left,
        y: rect.top,
      ));
      _spawnedCount++;
      _gridSpawnCooldown = GameConfig.gridSpawnMinInterval +
          _random.nextDouble() *
              (GameConfig.gridSpawnMaxInterval - GameConfig.gridSpawnMinInterval);
    }
  }

  // Picks a random spot within the given top band that doesn't overlap any
  // previously placed invader, so the formation scatters across the top of
  // the screen instead of sitting in a neat grid. Falls back to a fine-grid
  // scan if random sampling can't find a free spot, so spawning always
  // succeeds even when the band is nearly full.
  Rect _randomInvaderSpot(
    double minX,
    double maxX,
    double topMargin,
    double bandHeight,
    List<Rect> placed,
  ) {
    const maxAttempts = 200;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final x = minX + _random.nextDouble() * (maxX - minX);
      final y = topMargin + _random.nextDouble() * bandHeight;
      final candidate = Rect.fromLTWH(x, y, GameConfig.invaderWidth, GameConfig.invaderHeight);
      final padded = candidate.inflate(GameConfig.invaderSpacing / 2);
      if (!placed.any((r) => r.overlaps(padded))) return candidate;
    }
    for (var y = topMargin; y + GameConfig.invaderHeight <= topMargin + bandHeight; y += 4) {
      for (var x = minX; x + GameConfig.invaderWidth <= maxX; x += 4) {
        final candidate = Rect.fromLTWH(x, y, GameConfig.invaderWidth, GameConfig.invaderHeight);
        if (!placed.any((r) => r.overlaps(candidate))) return candidate;
      }
    }
    return Rect.fromLTWH(minX, topMargin, GameConfig.invaderWidth, GameConfig.invaderHeight);
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
    _updateGridSpawns(dt);
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

    // Scale the per-bounce drop inversely with how much the invaders have
    // sped up so the net descent RATE stays steady even as bounces get more
    // frequent (e.g. once only a few fast survivors are left), instead of
    // compounding into a sudden burst of drops.
    final speedRatio = _invaderSpeed / _waveBaseInvaderSpeed;
    final effectiveStepDown = GameConfig.stepDown / speedRatio;

    // Each invader bounces off the margins independently rather than as one
    // rigid block: since the formation is scattered across most of the
    // width (not a tight grid), a shared bounding-box check is almost
    // always touching one edge or the other, which either false-triggers
    // constantly or, once every invader is on screen, can hit both edges at
    // once and stack up many step-downs in a single frame.
    for (final inv in alive) {
      inv.x += inv.direction * _invaderSpeed * dt;
      // Clamp back to the boundary (not just flip direction) so a slow
      // invader that hasn't fully cleared the margin by the next frame
      // doesn't get re-triggered and flipped straight back — which left it
      // jittering in place right at the wall instead of moving away.
      if (inv.x <= GameConfig.arenaMargin) {
        inv.x = GameConfig.arenaMargin;
        inv.direction = 1;
        inv.y += effectiveStepDown;
      } else if (inv.x + inv.width >= _arenaSize.width - GameConfig.arenaMargin) {
        inv.x = _arenaSize.width - GameConfig.arenaMargin - inv.width;
        inv.direction = -1;
        inv.y += effectiveStepDown;
      }
    }

    final killedFraction = _killedCount / (GameConfig.rows * GameConfig.cols);
    _invaderSpeed = _waveBaseInvaderSpeed +
        (_waveMaxInvaderSpeed - _waveBaseInvaderSpeed) * killedFraction;
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
      _divingSpawnCooldown = _waveDivingMinInterval +
          _random.nextDouble() * (_waveDivingMaxInterval - _waveDivingMinInterval);
    }

    for (final diver in divingInvaders) {
      diver.y += _waveDivingSpeed * dt;
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
      _invaderFireCooldown = _waveInvaderFireMinInterval +
          _random.nextDouble() * (_waveInvaderFireMaxInterval - _waveInvaderFireMinInterval);
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
            _killedCount++;
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
    final fullySpawned = _spawnedCount >= GameConfig.rows * GameConfig.cols;
    if (fullySpawned && invaders.every((i) => !i.alive)) {
      if (wave < GameConfig.maxWave) {
        _startNextWave();
      } else {
        status = GameStatus.won;
      }
      return;
    }
    final invasionLine = player.y;
    if (invaders.any((i) => i.alive && i.y + i.height >= invasionLine)) {
      status = GameStatus.gameOver;
    }
  }

  // Advances to the next, harder wave: same formation size, but faster and
  // more aggressive per _applyWaveDifficulty. Score and lives are untouched.
  void _startNextWave() {
    wave++;
    bullets.clear();
    _buildLevel();
  }
}
