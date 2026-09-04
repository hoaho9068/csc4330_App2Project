import 'package:flutter/material.dart';

import 'game_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SPACE INVADERS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 56),
            _MenuButton(
              label: 'Play',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GameScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _MenuButton(
              label: 'Leaderboard',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _MenuButton(
              label: 'Profile',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        child: Text(label, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
