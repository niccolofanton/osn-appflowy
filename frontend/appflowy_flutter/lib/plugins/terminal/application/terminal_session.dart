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
  /// shell. When [autoLaunchClaude] is true, `claude` is typed into the shell
  /// shortly after startup.
  static TerminalSession spawn({
    required String id,
    required String title,
    required String workingDir,
    bool autoLaunchClaude = true,
  }) {
    final terminal = Terminal(maxLines: 10000);

    final shell = Platform.environment['SHELL'] ?? '/bin/zsh';

    final pty = Pty.start(
      shell,
      arguments: ['-l'],
      workingDirectory: workingDir,
      rows: 24,
    );

    // Shell -> terminal: render decoded output.
    pty.output.listen(
      (data) => terminal.write(utf8.decode(data, allowMalformed: true)),
    );

    // Terminal -> shell: forward user input.
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

    if (autoLaunchClaude) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (session.isRunning) {
          pty.write(Uint8List.fromList(utf8.encode('claude\r')));
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
