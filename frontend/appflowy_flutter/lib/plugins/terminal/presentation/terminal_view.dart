import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

import 'package:appflowy/plugins/terminal/application/terminal_session.dart';
import 'package:appflowy/plugins/terminal/presentation/terminal_theme.dart';

/// Renderizza il terminale [xterm] della [session] attiva con la palette osn.
class ActiveTerminalView extends StatelessWidget {
  const ActiveTerminalView({
    super.key,
    required this.session,
  });

  final TerminalSession session;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: kOsnPanelBg,
      child: TerminalView(
        session.terminal,
        theme: osnTerminalTheme,
        textStyle: const TerminalStyle(
          fontFamily: 'Geist Mono',
        ),
        padding: const EdgeInsets.all(8),
        autofocus: true,
      ),
    );
  }
}
