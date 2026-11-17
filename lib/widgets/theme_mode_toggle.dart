import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ThemeModeToggle extends StatelessWidget {
  const ThemeModeToggle({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: plotPostThemeMode,
      builder: (context, mode, _) {
        final icon = switch (mode) {
          ThemeMode.light => Icons.light_mode_rounded,
          ThemeMode.dark => Icons.dark_mode_rounded,
          ThemeMode.system => Icons.brightness_auto_rounded,
        };

        return PopupMenuButton<ThemeMode>(
          tooltip: 'Choose app appearance',
          initialValue: mode,
          onSelected: (selectedMode) {
            setPlotPostThemeMode(selectedMode);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: ThemeMode.system,
              child: _ThemeMenuItem(
                icon: Icons.brightness_auto_rounded,
                label: 'System default',
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.light,
              child: _ThemeMenuItem(
                icon: Icons.light_mode_rounded,
                label: 'Light mode',
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.dark,
              child: _ThemeMenuItem(
                icon: Icons.dark_mode_rounded,
                label: 'Dark mode',
              ),
            ),
          ],
          child: Padding(
            padding: EdgeInsets.all(compact ? 5 : 9),
            child: Icon(
              icon,
              size: compact ? 21 : 24,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        );
      },
    );
  }
}

class _ThemeMenuItem extends StatelessWidget {
  const _ThemeMenuItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}
