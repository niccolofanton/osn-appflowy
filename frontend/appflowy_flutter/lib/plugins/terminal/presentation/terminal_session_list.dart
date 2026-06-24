import 'package:flutter/material.dart';

import 'package:appflowy/plugins/terminal/application/terminal_session.dart';
import 'package:appflowy/plugins/terminal/application/terminal_session_manager.dart';
import 'package:appflowy/plugins/terminal/presentation/terminal_theme.dart';

/// Colonna a sinistra (~180px) con l'elenco delle sessioni terminale.
///
/// Header "Sessioni" + "+", lista reattiva delle sessioni: tap = activate,
/// "x" = close, doppio-tap = rinomina inline.
class TerminalSessionList extends StatelessWidget {
  const TerminalSessionList({
    super.key,
    required this.manager,
  });

  final TerminalSessionManager manager;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: kOsnPanelLayer,
        border: Border(
          right: BorderSide(color: kOsnPanelBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const Divider(height: 1, thickness: 1, color: kOsnPanelBorder),
          Expanded(
            child: ListenableBuilder(
              listenable: manager,
              builder: (context, _) {
                final sessions = manager.sessions;
                if (sessions.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Nessuna sessione.\nPremi + per iniziare.',
                      style: TextStyle(
                        color: kOsnTextSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  );
                }
                final activeId = manager.active?.id;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 4, top: 6, bottom: 6),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Sessioni',
              style: TextStyle(
                color: kOsnTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Nuova sessione',
            icon: const Icon(Icons.add, size: 18, color: kOsnTextPrimary),
            splashRadius: 16,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: manager.newSession,
          ),
        ],
      ),
    );
  }
}

/// Singola riga sessione: gestisce hover (per la "x") e la rinomina inline.
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
  bool _hovered = false;
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
    final showClose = _hovered || widget.isActive;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: _startEditing,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          height: 30,
          decoration: BoxDecoration(
            color: widget.isActive
                ? kOsnActiveBg
                : (_hovered ? const Color(0x14FFFFFF) : null),
            borderRadius: BorderRadius.circular(4),
            border: Border(
              left: BorderSide(
                color: widget.isActive ? kOsnAccent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: _editing
                    ? _buildEditor()
                    : Text(
                        widget.session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.isActive
                              ? kOsnTextPrimary
                              : const Color(0xB0FFFFFF),
                          fontSize: 13,
                        ),
                      ),
              ),
              if (showClose && !_editing)
                _CloseButton(onClose: widget.onClose)
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: true,
      cursorColor: kOsnAccent,
      style: const TextStyle(color: kOsnTextPrimary, fontSize: 13),
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
  const _CloseButton({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: IconButton(
        tooltip: 'Chiudi sessione',
        icon: const Icon(Icons.close, size: 14, color: kOsnTextSecondary),
        splashRadius: 12,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        onPressed: onClose,
      ),
    );
  }
}
