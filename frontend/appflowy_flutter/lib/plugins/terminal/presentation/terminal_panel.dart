import 'dart:io';

import 'package:flutter/material.dart';

import 'package:appflowy/plugins/terminal/application/terminal_session_manager.dart';
import 'package:appflowy/plugins/terminal/presentation/terminal_session_list.dart';
import 'package:appflowy/plugins/terminal/presentation/terminal_theme.dart';
import 'package:appflowy/plugins/terminal/presentation/terminal_view.dart';

/// Pannello terminale completo: lista sessioni a sinistra, terminale attivo a
/// destra. Disponibile solo su macOS (gate runtime).
class TerminalPanel extends StatelessWidget {
  const TerminalPanel({
    super.key,
    required this.manager,
  });

  final TerminalSessionManager manager;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isMacOS) {
      return const ColoredBox(
        color: kOsnPanelBg,
        child: Center(
          child: Text(
            'Terminale disponibile solo su macOS',
            style: TextStyle(color: kOsnTextSecondary),
          ),
        ),
      );
    }

    return ColoredBox(
      color: kOsnPanelBg,
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: TerminalSessionList(manager: manager),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: manager,
              builder: (context, _) {
                final active = manager.active;
                if (active == null) {
                  return const Center(
                    child: Text(
                      'Premi + per una nuova sessione',
                      style: TextStyle(color: kOsnTextSecondary),
                    ),
                  );
                }
                return ActiveTerminalView(
                  key: ValueKey(active.id),
                  session: active,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
