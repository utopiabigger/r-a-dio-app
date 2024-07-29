// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radio_app/main.dart';


void main() {
  testWidgets('Radio player app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyMusicPlayerApp());

    // Verify that the app title is present
    expect(find.text('r/a/dio'), findsOneWidget);

    // Check for the presence of a play/pause button
    expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);

    // Check for the "You're listening to:" text
    expect(find.text("You're listening to:"), findsOneWidget);

    // Check for the DJ name
    expect(find.text('Hanyuu-Sama'), findsOneWidget);
  });
}