import 'dart:convert';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';

import 'package:appflowy/plugins/terminal/application/terminal_session.dart';
import 'package:appflowy/plugins/terminal/presentation/terminal_theme.dart';

/// Renderizza il terminale [xterm] della [session] attiva.
///
/// - font monospace **Geist Mono**, scroll della rotella (mouseHandler in
///   [TerminalSession]), **drag & drop** di file (path shell-quoted al cursore);
/// - **Shift+Invio** → a capo senza inviare. Nota: con l'IME attivo macOS NON
///   espone lo stato dei modificatori (`HardwareKeyboard.isShiftPressed` resta
///   false), quindi usiamo `hardwareKeyboardOnly: true` e tracciamo lo Shift a
///   mano dai key-event; all'Invio con Shift premuto inviamo la sequenza kitty
///   `CSI 13;2u` che Claude Code interpreta come newline.
class ActiveTerminalView extends StatefulWidget {
  const ActiveTerminalView({super.key, required this.session});

  final TerminalSession session;

  @override
  State<ActiveTerminalView> createState() => _ActiveTerminalViewState();
}

class _ActiveTerminalViewState extends State<ActiveTerminalView> {
  bool _dragging = false;

  /// Stato dello Shift tracciato a mano dai key-event (vedi nota di classe).
  bool _shiftDown = false;

  /// Single-quote un path per la shell (gestisce gli apici interni).
  static String _shellQuote(String p) => "'${p.replaceAll("'", r"'\''")}'";

  void _onDrop(DropDoneDetails detail) {
    final paths = detail.files.map((f) => _shellQuote(f.path)).join(' ');
    if (paths.isEmpty) return;
    widget.session.pty.write(Uint8List.fromList(utf8.encode('$paths ')));
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final lk = event.logicalKey;
    if (lk == LogicalKeyboardKey.shiftLeft ||
        lk == LogicalKeyboardKey.shiftRight) {
      if (event is KeyDownEvent) _shiftDown = true;
      if (event is KeyUpEvent) _shiftDown = false;
    }
    final isEnter =
        lk == LogicalKeyboardKey.enter || lk == LogicalKeyboardKey.numpadEnter;
    final isPress = event is KeyDownEvent || event is KeyRepeatEvent;
    final shift = _shiftDown || HardwareKeyboard.instance.isShiftPressed;
    if (isEnter && isPress && shift) {
      widget.session.pty.write(Uint8List.fromList(utf8.encode('\x1b[13;2u')));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (detail) {
        setState(() => _dragging = false);
        _onDrop(detail);
      },
      child: Container(
        color: theme.colorScheme.surface,
        foregroundDecoration: _dragging
            ? BoxDecoration(
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              )
            : null,
        child: TerminalView(
          widget.session.terminal,
          theme: osnTerminalTheme,
          textStyle: const TerminalStyle(
            fontFamily: 'Geist Mono',
            // Fallback con Nerd Font per i glyph powerline/icone del prompt zsh
            // (p10k nerdfont-complete): Geist Mono non li contiene → tofu/`?`.
            fontFamilyFallback: [
              'MesloLGS NF',
              'JetBrainsMono Nerd Font',
              'Menlo',
              'monospace',
            ],
            height: 1.3,
          ),
          padding: const EdgeInsets.all(8),
          autofocus: true,
          hardwareKeyboardOnly: true,
          onKeyEvent: _onKeyEvent,
        ),
      ),
    );
  }
}
