import 'dart:convert';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';

import 'package:appflowy/plugins/terminal/application/terminal_session.dart';
import 'package:appflowy/plugins/terminal/presentation/terminal_theme.dart';

/// Renderizza il terminale [xterm] della [session] attiva.
///
/// IME ATTIVO (no `hardwareKeyboardOnly`): necessario per le **dead-key** (es.
/// US International `´`+`e` = `é`). Le scorciatoie con modificatori — che con
/// l'IME non sono distinguibili a livello di focus — sono intercettate da un
/// handler globale su [HardwareKeyboard] (eventi hardware grezzi, prima
/// dell'IME), solo quando il terminale ha il focus:
/// - **Shift+Invio** → `CSI 13;2u` (a capo, kitty).
/// - **Cmd+⌫** → `^U` (`\x15`) = elimina dall'inizio riga.
/// - **Option+⌫** / **Ctrl+⌫** → `^W` (`\x17`) = elimina la parola precedente.
class ActiveTerminalView extends StatefulWidget {
  const ActiveTerminalView({super.key, required this.session});

  final TerminalSession session;

  @override
  State<ActiveTerminalView> createState() => _ActiveTerminalViewState();
}

class _ActiveTerminalViewState extends State<ActiveTerminalView> {
  bool _dragging = false;
  bool _shiftDown = false;
  bool _altDown = false;
  bool _ctrlDown = false;
  bool _metaDown = false;
  final FocusNode _terminalFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_rawKeyHandler);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_rawKeyHandler);
    _terminalFocus.dispose();
    super.dispose();
  }

  void _write(String s) =>
      widget.session.pty.write(Uint8List.fromList(utf8.encode(s)));

  bool _rawKeyHandler(KeyEvent event) {
    final lk = event.logicalKey;
    final down = event is KeyDownEvent;
    final up = event is KeyUpEvent;

    // Stato modificatori tracciato a mano (con l'IME `isXPressed` non è
    // affidabile su macOS). Aggiornato anche quando il terminale non ha il focus.
    if (lk == LogicalKeyboardKey.shiftLeft ||
        lk == LogicalKeyboardKey.shiftRight) {
      if (down) _shiftDown = true;
      if (up) _shiftDown = false;
      return false;
    }
    if (lk == LogicalKeyboardKey.altLeft || lk == LogicalKeyboardKey.altRight) {
      if (down) _altDown = true;
      if (up) _altDown = false;
      return false;
    }
    if (lk == LogicalKeyboardKey.controlLeft ||
        lk == LogicalKeyboardKey.controlRight) {
      if (down) _ctrlDown = true;
      if (up) _ctrlDown = false;
      return false;
    }
    if (lk == LogicalKeyboardKey.metaLeft ||
        lk == LogicalKeyboardKey.metaRight) {
      if (down) _metaDown = true;
      if (up) _metaDown = false;
      return false;
    }

    if (!_terminalFocus.hasFocus) return false;
    final isPress = event is KeyDownEvent || event is KeyRepeatEvent;
    if (!isPress) return false;

    final hk = HardwareKeyboard.instance;
    final shift = _shiftDown || hk.isShiftPressed;
    final alt = _altDown || hk.isAltPressed;
    final ctrl = _ctrlDown || hk.isControlPressed;
    final meta = _metaDown || hk.isMetaPressed;

    final isEnter =
        lk == LogicalKeyboardKey.enter || lk == LogicalKeyboardKey.numpadEnter;
    if (isEnter && shift) {
      _write('\x1b[13;2u'); // a capo senza inviare
      return true;
    }

    if (lk == LogicalKeyboardKey.backspace) {
      if (meta) {
        _write('\x15'); // ^U: elimina dall'inizio riga
        return true;
      }
      if (alt || ctrl) {
        _write('\x17'); // ^W: elimina la parola precedente
        return true;
      }
    }

    return false;
  }

  /// Single-quote un path per la shell (gestisce gli apici interni).
  static String _shellQuote(String p) => "'${p.replaceAll("'", r"'\''")}'";

  void _onDrop(DropDoneDetails detail) {
    final paths = detail.files.map((f) => _shellQuote(f.path)).join(' ');
    if (paths.isEmpty) return;
    _write('$paths ');
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
          focusNode: _terminalFocus,
        ),
      ),
    );
  }
}
