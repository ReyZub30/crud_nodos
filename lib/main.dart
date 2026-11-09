import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() => runApp(const CrudNodosApp());

class CrudNodosApp extends StatelessWidget {
  const CrudNodosApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1565C0);
    return MaterialApp(
      title: 'CRUD Nodos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: seed),
      darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: seed, brightness: Brightness.dark),
      home: const HomeScreen(),
    );
  }
}
