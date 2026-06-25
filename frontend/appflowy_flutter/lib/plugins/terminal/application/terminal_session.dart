import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:xterm/xterm.dart';

/// A single embedded terminal session: a [Terminal] (xterm) wired to a [Pty]
/// (flutter_pty) running a login shell. Optionally auto-launches `claude` on
/// startup.
class TerminalSession {
  TerminalSession._({
    required this.id,
    required this.title,
    required this.terminal,
    required this.pty,
  });

  final String id;
  String title;
  final Terminal terminal;
  final Pty pty;
  bool isRunning = true;

  /// Spawns a new terminal session.
  ///
  /// Creates a [Terminal] with a 10k-line scrollback, starts a login shell in a
  /// pseudo-terminal rooted at [workingDir], and wires the two together so that
  /// shell output is rendered in the terminal and user input is forwarded to the
  /// shell. When [launchCommand] is non-empty it is typed into the shell shortly
  /// after startup (es. `claude --dangerously-skip-permissions`).
  static TerminalSession spawn({
    required String id,
    required String title,
    required String workingDir,
    String? launchCommand,
  }) {
    // mouseHandler custom: xterm.dart 4.0.0 codifica la rotella con button-id
    // errati (wheelUp=68, wheelDown=69 invece dello standard xterm 64/65). Le
    // TUI come Claude Code — che prendono l'alt-screen + mouse tracking — non
    // riconoscono quelle sequenze e NON scrollano. [_OsnMouseHandler] le
    // riemette con gli id corretti; tutto il resto va al default.
    final terminal = Terminal(
      maxLines: 10000,
      mouseHandler: const _OsnMouseHandler(),
    );

    final shell = Platform.environment['SHELL'] ?? '/bin/zsh';

    final pty = Pty.start(
      shell,
      arguments: ['-l'],
      workingDirectory: workingDir,
      rows: 24,
    );

    // Shell -> terminal. xterm.dart interpreta erroneamente le sequenze XTerm
    // modifyOtherKeys `\e[>4;2m` / `\e[>4m` (prefisso `>`) come SGR 4 = underline
    // e non le resetta mai → tutto il testo appare sottolineato. Le filtriamo
    // dallo stream (xterm non implementa modifyOtherKeys). Un piccolo buffer
    // trattiene una CSI eventualmente spezzata a metà tra due chunk.
    var carry = '';
    pty.output.listen((data) {
      var text = carry + utf8.decode(data, allowMalformed: true);
      carry = '';
      final cut = _incompleteEscapeIndex(text);
      if (cut != -1) {
        carry = text.substring(cut);
        text = text.substring(0, cut);
      }
      text = text.replaceAll(_modifyOtherKeysRe, '');
      terminal.write(text);
    });

    // Terminal -> shell: forward user input. (Shift+Invio è gestito a monte in
    // ActiveTerminalView, che invia direttamente la sequenza kitty al PTY.)
    terminal.onOutput =
        (data) => pty.write(Uint8List.fromList(utf8.encode(data)));

    // Terminal resize -> shell resize. xterm passes (width, height, ...);
    // pty.resize expects (rows, cols) == (height, width).
    terminal.onResize = (w, h, pw, ph) => pty.resize(h, w);

    final session = TerminalSession._(
      id: id,
      title: title,
      terminal: terminal,
      pty: pty,
    );

    final launch = launchCommand?.trim() ?? '';
    if (launch.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (session.isRunning) {
          pty.write(Uint8List.fromList(utf8.encode('$launch\r')));
        }
      });
    }

    pty.exitCode.then((_) {
      session.isRunning = false;
    });

    return session;
  }

  /// Terminates the underlying shell process and marks the session as stopped.
  void kill() {
    try {
      pty.kill();
    } catch (e) {
      debugPrint('TerminalSession($id) kill failed: $e');
    }
    isRunning = false;
  }
}

/// Sequenze XTerm `modifyOtherKeys` (prefisso CSI `>`, terminate da `m`) che
/// xterm.dart confonde con SGR underline. Le rimuoviamo dallo stream.
final RegExp _modifyOtherKeysRe = RegExp(r'\x1b\[>[0-9;]*m');

/// Mouse handler che corregge la codifica della rotella di xterm.dart 4.0.0.
///
/// Bug upstream: [TerminalMouseButton.wheelUp]/`wheelDown` hanno id `64+4=68` /
/// `64+5=69`, mentre lo standard xterm vuole `64` (su) / `65` (giù) — il bit 6
/// (64) marca la rotella e i 2 bit bassi sono `button-4`. Con 68/69 le app in
/// mouse-tracking (Claude Code) interpretano un bit Shift spurio e ignorano la
/// rotella → niente scroll. Qui riemettiamo gli eventi rotella con l'id giusto
/// e deleghiamo tutto il resto a [defaultMouseHandler].
class _OsnMouseHandler implements TerminalMouseHandler {
  const _OsnMouseHandler();

  @override
  String? call(TerminalMouseEvent event) {
    final mode = event.state.mouseMode;
    final reportsScroll = mode == MouseMode.upDownScroll ||
        mode == MouseMode.upDownScrollDrag ||
        mode == MouseMode.upDownScrollMove;
    if (reportsScroll && event.button.isWheel) {
      // Per la rotella si riportano solo gli eventi "down".
      if (event.buttonState == TerminalMouseButtonState.up) return null;
      final id = _correctedWheelId(event.button);
      if (id != null) {
        return _reportWheel(id, event.position, event.state.mouseReportMode);
      }
    }
    return defaultMouseHandler(event);
  }
}

/// Id button corretto (standard xterm) per i pulsanti rotella. null altrimenti.
int? _correctedWheelId(TerminalMouseButton button) {
  if (button == TerminalMouseButton.wheelUp) return 64;
  if (button == TerminalMouseButton.wheelDown) return 65;
  if (button == TerminalMouseButton.wheelLeft) return 66;
  if (button == TerminalMouseButton.wheelRight) return 67;
  return null;
}

/// Codifica un evento rotella (stato "down") nel report mode corrente, con l'id
/// corretto. Rispecchia `MouseReporter.report` (non esportato) di xterm.dart.
String _reportWheel(int id, CellOffset position, MouseReportMode reportMode) {
  final x = position.x + 1;
  final y = position.y + 1;
  switch (reportMode) {
    case MouseReportMode.sgr:
      return '\x1b[<$id;$x;${y}M';
    case MouseReportMode.urxvt:
      return '\x1b[${32 + id};$x;${y}M';
    case MouseReportMode.normal:
    case MouseReportMode.utf:
      final btn = String.fromCharCode(32 + id);
      final col = (reportMode == MouseReportMode.normal && x > 223) ||
              (reportMode == MouseReportMode.utf && x > 2015)
          ? '\x00'
          : String.fromCharCode(32 + x);
      final row = (reportMode == MouseReportMode.normal && y > 223) ||
              (reportMode == MouseReportMode.utf && y > 2015)
          ? '\x00'
          : String.fromCharCode(32 + y + 1);
      return '\x1b[M$btn$col$row';
  }
}

/// Indice da cui trattenere una sequenza CSI incompleta in coda alla stringa
/// (così non viene spezzata tra due chunk prima del filtro). -1 se l'ultima
/// escape è completa o assente.
int _incompleteEscapeIndex(String s) {
  final i = s.lastIndexOf('\x1b');
  if (i == -1) return -1;
  final rest = s.substring(i);
  if (rest == '\x1b') return i;
  if (rest.startsWith('\x1b[')) {
    for (int k = 2; k < rest.length; k++) {
      final c = rest.codeUnitAt(k);
      if (c >= 0x40 && c <= 0x7e) return -1; // CSI completa (final byte)
    }
    return i; // CSI ancora incompleta
  }
  return -1;
}
