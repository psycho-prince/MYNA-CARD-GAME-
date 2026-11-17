import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:websocket/websocket.dart';
import 'models.dart';
import 'lobby_page.dart';
import 'game_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: MaterialApp(
        title: 'MYNA Card Game',
        theme: ThemeData.dark(),
        initialRoute: '/',
        routes: {
          '/': (_) => const LobbyPage(),
          '/game': (_) => const GamePage(),
        },
      ),
    );
  }
}
