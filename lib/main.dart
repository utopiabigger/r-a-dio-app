import 'package:flutter/material.dart';
import 'package:radio_app/screens/player_screen.dart';
import 'package:radio_app/config/theme.dart';

void main() {
  runApp(MyMusicPlayerApp());
}

class MyMusicPlayerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Music Player',
      theme: appTheme, // This comes from config/theme.dart
      home: PlayerScreen(),
    );
  }
}