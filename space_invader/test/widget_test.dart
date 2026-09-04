import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:space_invader/main.dart';
import 'package:space_invader/screens/game_screen.dart';

void main() {
  testWidgets('Menu shows Play, Leaderboard, and Profile', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Game waits for player input before advancing', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: GameScreen()));
    await tester.pump();

    expect(find.text('Drag to start'), findsOneWidget);
    expect(find.textContaining('Score'), findsOneWidget);
    expect(find.text('Wave: 1'), findsOneWidget);
    expect(find.textContaining('Lives'), findsOneWidget);

    // Without any input, the game must stay paused indefinitely rather than
    // silently playing itself out (this is what let it reach Game Over
    // before anyone had a chance to see or play it).
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Drag to start'), findsOneWidget);
    expect(find.text('Score: 0'), findsOneWidget);
  });
}
