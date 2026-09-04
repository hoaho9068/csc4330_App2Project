import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../game/game_painter.dart';
import '../game/game_state.dart';
import '../services/game_data_service.dart';
import 'leaderboard_screen.dart';

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
              'Wave: ${gameState.wave}',
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

class _GameOverlay extends StatefulWidget {
  const _GameOverlay({required this.gameState});

  final GameState gameState;

  @override
  State<_GameOverlay> createState() => _GameOverlayState();
}

class _GameOverlayState extends State<_GameOverlay> {
  final GameDataService _dataService = GameDataService();
  final TextEditingController _nameController = TextEditingController();
  bool _nameLoadStarted = false;
  bool _submitted = false;

  Future<void> _loadCurrentName() async {
    final stats = await _dataService.loadStats();
    if (!mounted) return;
    setState(() => _nameController.text = stats.name);
  }

  // Saves this run to the leaderboard/profile under whatever name is
  // currently in the field (called from the Save button, or automatically
  // if the player heads to Restart/Menu without pressing it first, so a
  // score is never silently dropped). Safe to call more than once — only
  // the first call per game-over actually records anything.
  //
  // The `_submitted` flag flips synchronously inside setState; the actual
  // persistence is fire-and-forget below it. Passing an async function
  // straight to setState (as this used to) makes Flutter's setState
  // assertion abort before scheduling a rebuild, so the flag change and the
  // save would silently never reach the screen.
  void _submitResult() {
    if (_submitted) return;
    setState(() => _submitted = true);
    final name = _nameController.text.trim();
    _dataService.recordGameResult(
      name: name.isEmpty ? 'Player' : name,
      score: widget.gameState.score,
      wave: widget.gameState.wave,
    );
  }

  // Explicit submission (the Save Score button, or pressing enter/done in
  // the name field): save the run, then take the player straight to the
  // leaderboard to see where it landed. Replaces this screen in the nav
  // stack so backing out of the leaderboard returns to the menu, not to a
  // finished game-over screen.
  void _submitAndShowLeaderboard(BuildContext context) {
    _submitResult();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.gameState,
      builder: (context, _) {
        if (widget.gameState.status == GameStatus.playing) {
          // Re-arm for the next game-over/win this same GameState produces
          // (e.g. after Restart).
          _nameLoadStarted = false;
          _submitted = false;
          return const Positioned.fill(child: SizedBox.shrink());
        }
        if (!_nameLoadStarted) {
          _nameLoadStarted = true;
          _loadCurrentName();
        }
        final won = widget.gameState.status == GameStatus.won;
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
                    'Score: ${widget.gameState.score}',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _nameController,
                      enabled: !_submitted,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _submitAndShowLeaderboard(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed:
                        _submitted ? null : () => _submitAndShowLeaderboard(context),
                    child: Text(_submitted ? 'Saved' : 'Save Score'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _submitResult();
                          widget.gameState.restart();
                        },
                        child: const Text('Restart'),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: () {
                          _submitResult();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Menu'),
                      ),
                    ],
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
