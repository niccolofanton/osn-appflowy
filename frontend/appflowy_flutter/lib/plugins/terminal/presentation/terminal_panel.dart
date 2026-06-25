import 'dart:io';

import 'package:flutter/material.dart';

import 'package:appflowy/plugins/terminal/application/terminal_panel_controller.dart';
import 'package:appflowy/plugins/terminal/application/terminal_session_manager.dart';
import 'package:appflowy/plugins/terminal/presentation/terminal_session_list.dart';
import 'package:appflowy/plugins/terminal/presentation/terminal_view.dart';

/// Pannello terminale: terminale a SINISTRA, colonna "Sessioni" a DESTRA
/// (collassabile, animata). Colori dal tema dell'app. Solo macOS.
class TerminalPanel extends StatelessWidget {
  const TerminalPanel({
    super.key,
    required this.manager,
  });

  final TerminalSessionManager manager;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!Platform.isMacOS) {
      return ColoredBox(
        color: theme.colorScheme.surface,
        child: Center(
          child: Text(
            'Terminale disponibile solo su macOS',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    final collapsed = terminalPanelController.sessionsCollapsed;

    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: manager,
              builder: (context, _) {
                final active = manager.active;
                if (active == null) {
                  return Center(
                    child: Text(
                      'Premi + per una nuova sessione',
                      style: TextStyle(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
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
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.centerLeft,
            child: collapsed
                ? _CollapsedSessionsBar(
                    onExpand: terminalPanelController.toggleSessions,
                    onNew: () => manager.newSession(),
                    onClose: terminalPanelController.close,
                  )
                : SizedBox(
                    width: 200,
                    child: TerminalSessionList(
                      manager: manager,
                      onCollapse: terminalPanelController.toggleSessions,
                      onClosePanel: terminalPanelController.close,
                      skipPermissionsOn:
                          terminalPanelController.skipPermissionsByDefault,
                      onToggleSkipPermissions: () =>
                          terminalPanelController.setSkipPermissionsByDefault(
                        !terminalPanelController.skipPermissionsByDefault,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Striscia compatta mostrata quando la colonna sessioni è collassata.
class _CollapsedSessionsBar extends StatelessWidget {
  const _CollapsedSessionsBar({
    required this.onExpand,
    required this.onNew,
    required this.onClose,
  });

  final VoidCallback onExpand;
  final VoidCallback onNew;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface.withValues(alpha: 0.8);
    return Container(
      width: 36,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 6),
          IconButton(
            tooltip: 'Chiudi terminale (⌥⌘T)',
            icon: Icon(Icons.close, size: 18, color: color),
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
          ),
          IconButton(
            tooltip: 'Mostra sessioni',
            icon: Icon(Icons.chevron_left, size: 18, color: color),
            visualDensity: VisualDensity.compact,
            onPressed: onExpand,
          ),
          IconButton(
            tooltip: 'Nuova sessione',
            icon: Icon(Icons.add, size: 18, color: color),
            visualDensity: VisualDensity.compact,
            onPressed: onNew,
          ),
        ],
      ),
    );
  }
}
