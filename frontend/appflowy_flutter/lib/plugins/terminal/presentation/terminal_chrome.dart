import 'package:flutter/material.dart';

import 'package:appflowy/plugins/terminal/application/terminal_panel_controller.dart';
import 'package:appflowy/plugins/terminal/presentation/terminal_theme.dart';

/// Pulsante flottante per aprire/chiudere il pannello terminale osn.
class TerminalToggleButton extends StatelessWidget {
  const TerminalToggleButton({super.key, required this.controller});

  final TerminalPanelController controller;

  @override
  Widget build(BuildContext context) {
    final open = controller.isOpen;
    return Material(
      color: open ? kOsnAccent : kOsnPanelLayer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: kOsnPanelBorder),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: controller.toggle,
        child: Tooltip(
          message: open ? 'Chiudi terminale (⌥⌘T)' : 'Apri terminale (⌥⌘T)',
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              Icons.terminal_rounded,
              size: 18,
              color: open ? Colors.white : kOsnTextPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Maniglia verticale di resize del pannello (il pannello è a destra: trascinare
/// a sinistra allarga). Imita il comportamento di [SidebarResizer].
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
    final active = _hovering || _dragging;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragEnd: (_) => setState(() => _dragging = false),
        onHorizontalDragUpdate: (details) {
          // pannello a destra: dx negativo (verso sinistra) => più largo
          widget.controller.setWidth(widget.controller.width - details.delta.dx);
        },
        child: SizedBox(
          width: 6,
          child: Center(
            child: Container(
              width: active ? 2 : 1,
              color: active ? kOsnAccent : kOsnPanelBorder,
            ),
          ),
        ),
      ),
    );
  }
}
