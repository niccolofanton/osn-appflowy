import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/plugins/terminal/application/terminal_session.dart';
import 'package:appflowy/plugins/terminal/application/terminal_session_manager.dart';

/// Colonna (~200px) con l'elenco delle sessioni terminale, a DESTRA del
/// terminale. Usa lo stesso sfondo/hover/selezione della sidebar dell'app
/// (`Theme.colorScheme` + `FlowyHover`).
///
/// Header "Sessioni" con: ⚡ nuova sessione skip-permissions, + nuova sessione.
/// Riga: tap = activate, doppio-tap = rinomina inline, "x" = chiudi.
class TerminalSessionList extends StatelessWidget {
  const TerminalSessionList({
    super.key,
    required this.manager,
    this.onCollapse,
    this.onClosePanel,
    this.skipPermissionsOn = false,
    this.onToggleSkipPermissions,
  });

  final TerminalSessionManager manager;

  /// Se non null, mostra un chevron per collassare la colonna sessioni.
  final VoidCallback? onCollapse;

  /// Se non null, mostra una X per chiudere l'intero pannello terminale.
  final VoidCallback? onClosePanel;

  /// Stato corrente della preferenza "salta permessi" (per il toggle ⚡).
  final bool skipPermissionsOn;

  /// Se non null, mostra il toggle ⚡ che attiva/disattiva [skipPermissionsOn].
  final VoidCallback? onToggleSkipPermissions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.onSurface.withValues(alpha: 0.08);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(left: BorderSide(color: border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Divider(height: 1, thickness: 1, color: border),
          Expanded(
            child: ListenableBuilder(
              listenable: manager,
              builder: (context, _) {
                final sessions = manager.sessions;
                if (sessions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Nessuna sessione.\nPremi + per iniziare.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  );
                }
                final activeId = manager.active?.id;
                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return _SessionTile(
                      key: ValueKey(session.id),
                      session: session,
                      isActive: session.id == activeId,
                      onTap: () => manager.activate(session.id),
                      onClose: () => manager.closeSession(session.id),
                      onRename: (title) => manager.rename(session.id, title),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurface.withValues(alpha: 0.8);
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 6, bottom: 6),
      child: Row(
        children: [
          if (onCollapse != null)
            _HeaderIconButton(
              icon: Icons.chevron_right,
              tooltip: 'Comprimi',
              color: iconColor,
              onPressed: onCollapse!,
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: onCollapse != null ? 0 : 8),
              child: Text(
                'Sessioni',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          if (onToggleSkipPermissions != null)
            _HeaderIconButton(
              icon: skipPermissionsOn ? Icons.flash_on : Icons.flash_off,
              tooltip: skipPermissionsOn
                  ? 'Salta permessi nelle nuove sessioni: ATTIVO — clic per disattivare'
                  : 'Salta permessi nelle nuove sessioni: off — clic per attivare',
              color: skipPermissionsOn ? theme.colorScheme.primary : iconColor,
              onPressed: onToggleSkipPermissions!,
            ),
          _HeaderIconButton(
            icon: Icons.add,
            tooltip: 'Nuova sessione',
            color: iconColor,
            onPressed: () => manager.newSession(),
          ),
          if (onClosePanel != null)
            _HeaderIconButton(
              icon: Icons.close,
              tooltip: 'Chiudi terminale (⌥⌘T)',
              color: iconColor,
              onPressed: onClosePanel!,
            ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 18, color: color),
      splashRadius: 16,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      onPressed: onPressed,
    );
  }
}

/// Riga sessione con hover identico alla sidebar (FlowyHover) e rinomina inline.
class _SessionTile extends StatefulWidget {
  const _SessionTile({
    super.key,
    required this.session,
    required this.isActive,
    required this.onTap,
    required this.onClose,
    required this.onRename,
  });

  final TerminalSession session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final ValueChanged<String> onRename;

  @override
  State<_SessionTile> createState() => _SessionTileState();
}

class _SessionTileState extends State<_SessionTile> {
  bool _editing = false;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.session.title);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    _controller.text = widget.session.title;
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  void _commit() {
    if (!_editing) return;
    final value = _controller.text.trim();
    if (value.isNotEmpty && value != widget.session.title) {
      widget.onRename(value);
    }
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FlowyHover(
      resetHoverOnRebuild: false,
      style: HoverStyle(
        hoverColor: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(6),
      ),
      isSelected: () => widget.isActive,
      builder: (context, onHover) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onDoubleTap: _startEditing,
        child: SizedBox(
          height: 30,
          child: Row(
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: _editing
                    ? _buildEditor(theme)
                    : Text(
                        widget.session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
              ),
              if ((onHover || widget.isActive) && !_editing)
                _CloseButton(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  onClose: widget.onClose,
                )
              else
                const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditor(ThemeData theme) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: true,
      cursorColor: theme.colorScheme.primary,
      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 4),
        border: InputBorder.none,
      ),
      onSubmitted: (_) => _commit(),
      onTapOutside: (_) => _commit(),
      onEditingComplete: _commit,
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.color, required this.onClose});

  final Color color;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: IconButton(
        tooltip: 'Chiudi sessione',
        icon: Icon(Icons.close, size: 14, color: color),
        splashRadius: 12,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        onPressed: onClose,
      ),
    );
  }
}
