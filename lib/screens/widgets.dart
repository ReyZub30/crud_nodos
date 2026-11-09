import 'package:flutter/material.dart';

/// Card con título e icono para cada módulo.
class ModuleCard extends StatelessWidget {
  const ModuleCard({super.key, required this.icon, required this.title, required this.children});

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Mensaje de resultado: verde si fue correcto, rojo si hubo error.
class StatusBox extends StatelessWidget {
  const StatusBox({super.key, required this.message, required this.ok});

  final String message;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = ok ? Colors.green.withValues(alpha: 0.15) : scheme.errorContainer;
    final fg = ok ? (Theme.of(context).brightness == Brightness.dark ? Colors.green.shade200 : Colors.green.shade900) : scheme.onErrorContainer;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ok ? Icons.verified_outlined : Icons.gpp_bad_outlined, color: fg),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(color: fg))),
        ],
      ),
    );
  }
}

/// Texto en fuente monoespaciada para rutas, hashes y contenido de archivos.
class MonoBox extends StatelessWidget {
  const MonoBox(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(text, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
    );
  }
}
