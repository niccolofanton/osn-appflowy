import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/startup/startup.dart';

import 'terminal_cli_config.dart';
import 'terminal_session.dart';

/// Manages the lifecycle of embedded [TerminalSession]s.
///
/// **Persistenza:** ogni sessione ha una *chiave* stabile (contatore persistito,
/// mai `Random`/`DateTime`) e gira in una sottocartella dedicata
/// `<workingDir>/.sessions/<key>` (con symlink a `.mcp.json`/`CLAUDE.md`). Le
/// sessioni aperte sono salvate via [KeyValueStorage]; chiuderne una con la "x"
/// la elimina anche dalla persistenza. All'avvio [restoreOrCreate] ricrea le
/// sessioni salvate avviando l'harness col flag di **resume** (es.
/// `claude --continue`, che riprende la conversazione di quella cartella).
class TerminalSessionManager extends ChangeNotifier {
  TerminalSessionManager({
    required this.workingDir,
    this.skipPermissionsByDefault = false,
  });

  /// Cartella radice osn (es. `~/osn`). Ogni sessione gira in una sua
  /// sottocartella `<workingDir>/.sessions/<key>`.
  final String workingDir;

  /// Preferenza: nuove sessioni con `--dangerously-skip-permissions` quando
  /// [newSession] non specifica esplicitamente il flag.
  bool skipPermissionsByDefault;

  static const String _kSessions = 'osn_terminal_sessions';
  static const String _kNextKey = 'osn_terminal_next_key';

  final List<TerminalSession> _sessions = <TerminalSession>[];
  int _nextKey = 1;
  String? _activeId;
  bool _restored = false;

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

  /// Ripristina le sessioni persistite (avviando l'harness in resume) oppure,
  /// se non ce ne sono, ne crea una nuova. Idempotente.
  Future<void> restoreOrCreate() async {
    if (_restored) return;
    _restored = true;
    final kv = getIt<KeyValueStorage>();
    _nextKey = int.tryParse(await kv.get(_kNextKey) ?? '') ?? 1;
    final persisted = _decodeSessions(await kv.get(_kSessions));
    if (persisted.isEmpty) {
      await _spawn(
        key: _allocKey(),
        title: null,
        resume: false,
        skip: skipPermissionsByDefault,
      );
      _persist();
    } else {
      for (final s in persisted) {
        if (s.key >= _nextKey) _nextKey = s.key + 1;
        await _spawn(
          key: s.key,
          title: s.title,
          resume: true,
          skip: skipPermissionsByDefault,
        );
      }
    }
    notifyListeners();
  }

  /// Crea una nuova sessione (runtime), in una sottocartella dedicata, e la
  /// rende attiva. La persiste. [dangerouslySkipPermissions] forza il flag.
  Future<void> newSession({bool? dangerouslySkipPermissions}) async {
    final skip = dangerouslySkipPermissions ?? skipPermissionsByDefault;
    await _spawn(key: _allocKey(), title: null, resume: false, skip: skip);
    _persist();
    notifyListeners();
  }

  int _allocKey() {
    final key = _nextKey;
    _nextKey++;
    getIt<KeyValueStorage>().set(_kNextKey, _nextKey.toString());
    return key;
  }

  Future<void> _spawn({
    required int key,
    required String? title,
    required bool resume,
    required bool skip,
  }) async {
    final dir = await _ensureSessionDir(key);
    // Riprendi SOLO se c'è davvero una conversazione salvata per questa cwd:
    // `claude --continue` a vuoto esce 0 stampando "No conversation found" e
    // lascerebbe la shell. Così invece parte una sessione pulita.
    final wantResume = resume && _canResume(dir);
    final session = TerminalSession.spawn(
      id: 's$key',
      title: title ?? 'Session $key',
      workingDir: dir,
      launchCommand:
          terminalCliConfig.buildLaunchCommand(skip: skip, resume: wantResume),
    );
    _sessions.add(session);
    _activeId = session.id;
  }

  /// Per Claude: esiste una conversazione salvata per [cwd]? Claude memorizza le
  /// sessioni in `~/.claude/projects/<cwd con non-alfanumerici → '-'>/<id>.jsonl`.
  /// Per altri harness assume di sì (best-effort: usa gli args di resume).
  bool _canResume(String cwd) {
    if (terminalCliConfig.harnessId != 'claude') return true;
    final home = Platform.environment['HOME'] ?? '';
    if (home.isEmpty) return false;
    final encoded = cwd.replaceAll(RegExp(r'[^A-Za-z0-9]'), '-');
    final dir = Directory('$home/.claude/projects/$encoded');
    if (!dir.existsSync()) return false;
    try {
      return dir.listSync().any((e) => e.path.endsWith('.jsonl'));
    } catch (_) {
      return false;
    }
  }

  /// Crea `<workingDir>/.sessions/<key>` con symlink relativi a `.mcp.json` e
  /// `CLAUDE.md` (così l'MCP e le istruzioni valgono anche nella sottocartella,
  /// e `--continue` riprende la conversazione di quella cwd). Best-effort.
  Future<String> _ensureSessionDir(int key) async {
    final dir = Directory('$workingDir/.sessions/$key');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    for (final name in const ['.mcp.json', 'CLAUDE.md']) {
      final linkPath = '${dir.path}/$name';
      final present = FileSystemEntity.typeSync(linkPath, followLinks: false) !=
          FileSystemEntityType.notFound;
      if (!present && File('$workingDir/$name').existsSync()) {
        try {
          Link(linkPath).createSync('../../$name');
        } catch (_) {/* best-effort */}
      }
    }
    return dir.path;
  }

  /// Marks the session with [id] as active and notifies listeners.
  void activate(String id) {
    if (_activeId == id) return;
    _activeId = id;
    notifyListeners();
  }

  /// Kills and removes the session with [id] (la elimina anche dalla
  /// persistenza → non verrà ripristinata). Notifies listeners.
  void closeSession(String id) {
    final index = _sessions.indexWhere((s) => s.id == id);
    if (index == -1) return;

    final session = _sessions.removeAt(index);
    session.kill();

    if (_activeId == id) {
      _activeId = _sessions.isEmpty ? null : _sessions.last.id;
    }
    _persist();
    notifyListeners();
  }

  /// Renames the session with [id] (persistito) e notifies listeners.
  void rename(String id, String title) {
    for (final session in _sessions) {
      if (session.id == id) {
        session.title = title;
        _persist();
        notifyListeners();
        return;
      }
    }
  }

  void _persist() {
    final list = _sessions
        .map((s) => {'key': _keyOf(s.id), 'title': s.title})
        .toList();
    getIt<KeyValueStorage>().set(_kSessions, jsonEncode(list));
  }

  static int _keyOf(String id) => int.tryParse(id.substring(1)) ?? 0;

  List<_PersistedSession> _decodeSessions(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final arr = jsonDecode(raw) as List<dynamic>;
      return arr
          .map(
            (e) => _PersistedSession(
              key: (e['key'] as num).toInt(),
              title: e['title'] as String? ?? 'Session',
            ),
          )
          .where((s) => s.key > 0)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Kills every session and clears the list (NON tocca la persistenza: le
  /// sessioni devono sopravvivere alla chiusura dell'app). Notifies listeners.
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

class _PersistedSession {
  const _PersistedSession({required this.key, required this.title});
  final int key;
  final String title;
}
