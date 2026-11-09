import 'package:flutter/material.dart';

import 'archivos_page.dart';
import 'base_datos_page.dart';
import 'nodos_page.dart';

/// Navegación principal entre los tres módulos de la práctica.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // Cada página se vuelve a crear al cambiar de pestaña, así siempre
    // muestra los datos más recientes de la base de datos.
    final pages = [const NodosPage(), const ArchivosPage(), const BaseDatosPage()];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.sensors_outlined), selectedIcon: Icon(Icons.sensors), label: 'Nodos'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'Archivos'),
          NavigationDestination(icon: Icon(Icons.storage_outlined), selectedIcon: Icon(Icons.storage), label: 'Base de datos'),
        ],
      ),
    );
  }
}
