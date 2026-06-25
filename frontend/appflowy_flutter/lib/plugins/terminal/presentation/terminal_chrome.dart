import 'dart:io' show Platform;

import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/plugins/terminal/application/terminal_panel_controller.dart';
import 'package:appflowy/plugins/terminal/presentation/terminal_panel.dart';

/// Pulsante nell'header del documento/database che apre/chiude il pannello
/// terminale osn (toggle). Icona ✨ monocroma. Solo macOS.
class TerminalHeaderButton extends StatelessWidget {
  const TerminalHeaderButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Platform.isMacOS) return const SizedBox.shrink();
    return FlowyIconButton(
      tooltipText: 'Apri/chiudi terminale (⌥⌘T)',
      hoverColor: Theme.of(context).colorScheme.secondary,
      icon: Icon(
        Icons.auto_awesome_outlined,
        size: 16,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: () => terminalPanelController.toggle(),
    );
  }
}

/// Ospita il pannello terminale a destra del contenuto e ne anima
/// l'apertura/chiusura (slide+width). Ascolta [terminalPanelController].
class TerminalPanelHost extends StatefulWidget {
  const TerminalPanelHost({super.key});

  @override
  State<TerminalPanelHost> createState() => _TerminalPanelHostState();
}

class _TerminalPanelHostState extends State<TerminalPanelHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: terminalPanelController.isOpen ? 1.0 : 0.0,
  );

  @override
  void initState() {
    super.initState();
    terminalPanelController.addListener(_sync);
    // Ripristina collasso colonna sessioni / larghezza / salta-permessi.
    terminalPanelController.loadPrefs();
  }

  void _sync() {
    if (terminalPanelController.isOpen) {
      _ac.forward();
    } else {
      _ac.reverse();
    }
  }

  @override
  void dispose() {
    terminalPanelController.removeListener(_sync);
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([_ac, terminalPanelController]),
      builder: (context, _) {
        final controller = terminalPanelController;
        final t = Curves.easeOutCubic.transform(_ac.value);
        final width = controller.width * t;
        if (width < 0.5) return const SizedBox.shrink();

        final manager = controller.managerOrNull;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.isOpen && t > 0.99)
              TerminalPanelResizer(controller: controller),
            ClipRect(
              child: SizedBox(
                width: width,
                child: OverflowBox(
                  alignment: Alignment.centerRight,
                  minWidth: controller.width,
                  maxWidth: controller.width,
                  child: SizedBox(
                    width: controller.width,
                    child: manager == null
                        ? ColoredBox(color: theme.colorScheme.surface)
                        : TerminalPanel(manager: manager),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Maniglia verticale di resize del pannello (a destra: trascina a sinistra
/// per allargare). Colori dal tema dell'app.
class TerminalPanelResizer extends StatefulWidget {
  const TerminalPanelResizer({super.key, required this.controller});

  final TerminalPanelController controller;

  @override
  State<TerminalPanelResizer> createState() => _TerminalPanelResizerState();
}

class _TerminalPanelResizerState extends State<TerminalPanelResizer> {
  bool _hovering = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = _hovering || _dragging;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragEnd: (_) {
          setState(() => _dragging = false);
          widget.controller.commitWidth();
        },
        onHorizontalDragUpdate: (details) {
          widget.controller
              .setWidth(widget.controller.width - details.delta.dx);
        },
        child: SizedBox(
          width: 6,
          child: Center(
            child: Container(
              width: active ? 2 : 1,
              color: active
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
        ),
      ),
    );
  }
}
