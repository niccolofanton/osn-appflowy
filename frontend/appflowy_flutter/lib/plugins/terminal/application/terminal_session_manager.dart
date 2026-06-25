import 'package:flutter/foundation.dart';

import 'terminal_cli_config.dart';
import 'terminal_session.dart';

/// Manages the lifecycle of embedded [TerminalSession]s.
///
/// Uses a simple incremental integer counter for session ids (never
/// `Random`/`DateTime`). Does not create any session automatically; callers
/// must invoke [newSession]. Notifies listeners on every mutation.
class TerminalSessionManager extends ChangeNotifier {
  TerminalSessionManager({
    required this.workingDir,
    this.skipPermissionsByDefault = false,
  });

  /// Working directory used as the root for every spawned session.
  final String workingDir;

  /// Preferenza: le nuove sessioni partono con `--dangerously-skip-permissions`
  /// quando [newSession] non specifica esplicitamente il flag. Sincronizzata dal
  /// [TerminalPanelController].
  bool skipPermissionsByDefault;

  final List<TerminalSession> _sessions = <TerminalSession>[];
  int _counter = 0;
  String? _activeId;

  /// All sessions, in creation order. Read-only.
  List<TerminalSession> get sessions => List.unmodifiable(_sessions);

  /// The currently active session, or null if none is active.
  TerminalSession? get active {
    final id = _activeId;
    if (id == null) return null;
    for (final session in _sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  /// Spawns a new session, makes it active, and notifies listeners.
  ///
  /// [dangerouslySkipPermissions] forza il flag; se null usa la preferenza
  /// [skipPermissionsByDefault]. Quando true la sessione auto-lancia
  /// `claude --dangerously-skip-permissions`.
  void newSession({bool? dangerouslySkipPermissions}) {
    _counter++;
    final id = 's$_counter';
    final title = 'Session $_counter';
    final skip = dangerouslySkipPermissions ?? skipPermissionsByDefault;
    final session = TerminalSession.spawn(
      id: id,
      title: title,
      workingDir: workingDir,
      launchCommand: terminalCliConfig.buildLaunchCommand(skip: skip),
    );
    _sessions.add(session);
    _activeId = id;
    notifyListeners();
  }

  /// Marks the session with [id] as active and notifies listeners.
  void activate(String id) {
    if (_activeId == id) return;
    _activeId = id;
    notifyListeners();
  }

  /// Kills and removes the session with [id]. If it was active, falls back to
  /// the last remaining session (or null). Notifies listeners.
  void closeSession(String id) {
    final index = _sessions.indexWhere((s) => s.id == id);
    if (index == -1) return;

    final session = _sessions.removeAt(index);
    session.kill();

    if (_activeId == id) {
      _activeId = _sessions.isEmpty ? null : _sessions.last.id;
    }
    notifyListeners();
  }

  /// Renames the session with [id] and notifies listeners.
  void rename(String id, String title) {
    for (final session in _sessions) {
      if (session.id == id) {
        session.title = title;
        notifyListeners();
        return;
      }
    }
  }

  /// Kills every session and clears the list. Notifies listeners.
  void disposeAll() {
    for (final session in _sessions) {
      session.kill();
    }
    _sessions.clear();
    _activeId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeAll();
    super.dispose();
  }
}
