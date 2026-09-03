import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../game/game_painter.dart';
import '../game/game_state.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  final GameState _gameState = GameState();
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    _gameState.update(dt);
  }

  void _handleDrag(double dx) {
    if (!_started) {
      setState(() => _started = true);
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
    _gameState.movePlayer(dx);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _gameState.initArena(Size(constraints.maxWidth, constraints.maxHeight));
            return Stack(
              children: [
                Positioned.fill(
                  child: ListenableBuilder(
                    listenable: _gameState,
                    builder: (context, child) {
                      return IgnorePointer(
                        ignoring: _gameState.status != GameStatus.playing,
                        child: child,
                      );
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) => _handleDrag(details.delta.dx),
                      child: CustomPaint(painter: GamePainter(_gameState)),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 16,
                  right: 16,
                  child: _Hud(gameState: _gameState),
                ),
                if (!_started)
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 80,
                    child: Center(
                      child: Text(
                        'Drag to start',
                        style: TextStyle(color: Colors.white70, fontSize: 20),
                      ),
                    ),
                  ),
                _GameOverlay(gameState: _gameState),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.gameState});

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameState,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Score: ${gameState.score}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              'Lives: ${gameState.lives}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        );
      },
    );
  }
}

class _GameOverlay extends StatelessWidget {
  const _GameOverlay({required this.gameState});

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameState,
      builder: (context, _) {
        if (gameState.status == GameStatus.playing) {
          return const Positioned.fill(child: SizedBox.shrink());
        }
        final won = gameState.status == GameStatus.won;
        return Positioned.fill(
          child: Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    won ? 'You Win!' : 'Game Over',
                    style: const TextStyle(color: Colors.white, fontSize: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Score: ${gameState.score}',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: gameState.restart,
                    child: const Text('Restart'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
