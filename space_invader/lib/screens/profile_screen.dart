import 'package:flutter/material.dart';

import '../services/game_data_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _dataService = GameDataService();
  final _nameController = TextEditingController();
  PlayerStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _dataService.loadStats();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _nameController.text = stats.name;
    });
  }

  Future<void> _saveName() async {
    final stats = _stats;
    if (stats == null) return;
    final trimmed = _nameController.text.trim();
    final updated = stats.copyWith(name: trimmed.isEmpty ? 'Player' : trimmed);
    await _dataService.saveStats(updated);
    if (!mounted) return;
    setState(() => _stats = updated);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name saved')));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return Scaffold(
      appBar: AppBar(),
      body: stats == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Name', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          onSubmitted: (_) => _saveName(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(onPressed: _saveName, child: const Text('Save')),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _StatRow(label: 'Games Played', value: '${stats.gamesPlayed}'),
                  _StatRow(label: 'High Score', value: '${stats.highScore}'),
                  _StatRow(label: 'Best Wave', value: '${stats.bestWave}'),
                ],
              ),
            ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
