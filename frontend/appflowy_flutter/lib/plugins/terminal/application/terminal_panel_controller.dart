import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/plugins/terminal/application/terminal_cli_config.dart';
import 'package:appflowy/plugins/terminal/application/terminal_session_manager.dart';
import 'package:appflowy/plugins/terminal/bootstrap/terminal_bootstrap.dart';
import 'package:appflowy/startup/startup.dart';

/// Stato globale del pannello terminale osn (apertura + larghezza) e accesso
/// lazy al [TerminalSessionManager]. Singleton di modulo ([terminalPanelController])
/// per non dover toccare il container DI (riduce i conflitti nei rebase del fork).
///
/// OSN: feature self-contained, gated `Platform.isMacOS` a livello di UI.
class TerminalPanelController extends ChangeNotifier {
  TerminalPanelController();

  static const double minWidth = 360;
  static const double maxWidth = 1000;
  static const double defaultWidth = 540;

  // Chiavi di persistenza (KeyValueStorage → SharedPreferences).
  static const String _kSessionsCollapsed = 'osn_terminal_sessions_collapsed';
  static const String _kWidth = 'osn_terminal_width';
  static const String _kSkipPermissions = 'osn_terminal_skip_permissions';

  bool _isOpen = false;
  double _width = defaultWidth;
  bool _booting = false;
  bool _sessionsCollapsed = false;
  bool _skipPermissionsByDefault = false;
  bool _prefsLoaded = false;
  TerminalSessionManager? _manager;

  bool get isOpen => _isOpen;
  double get width => _width;

  /// Se la colonna "Sessioni" (a destra del terminale) è collassata.
  bool get sessionsCollapsed => _sessionsCollapsed;

  /// Se le nuove sessioni (incluso l'auto-launch) partono con
  /// `claude --dangerously-skip-permissions`. Preferenza persistita.
  bool get skipPermissionsByDefault => _skipPermissionsByDefault;

  /// Carica le preferenze persistite (collasso colonna sessioni, larghezza,
  /// salta-permessi). Idempotente; va chiamata una volta all'avvio della home.
  Future<void> loadPrefs() async {
    if (_prefsLoaded) return;
    _prefsLoaded = true;
    final kv = getIt<KeyValueStorage>();
    final collapsed = await kv.get(_kSessionsCollapsed);
    final width = await kv.get(_kWidth);
    final skip = await kv.get(_kSkipPermissions);
    if (collapsed != null) _sessionsCollapsed = collapsed == 'true';
    if (width != null) {
      final w = double.tryParse(width);
      if (w != null) _width = w.clamp(minWidth, maxWidth).toDouble();
    }
    if (skip != null) _skipPermissionsByDefault = skip == 'true';
    notifyListeners();
  }

  void _persist(String key, String value) {
    // fire-and-forget: la persistenza non deve bloccare la UI.
    getIt<KeyValueStorage>().set(key, value);
  }

  void toggleSessions() {
    _sessionsCollapsed = !_sessionsCollapsed;
    notifyListeners();
    _persist(_kSessionsCollapsed, _sessionsCollapsed.toString());
  }

  /// Imposta (e persiste) la preferenza salta-permessi. Aggiorna anche il
  /// manager corrente, così le prossime sessioni la rispettano.
  void setSkipPermissionsByDefault(bool value) {
    if (_skipPermissionsByDefault == value) return;
    _skipPermissionsByDefault = value;
    _manager?.skipPermissionsByDefault = value;
    notifyListeners();
    _persist(_kSkipPermissions, value.toString());
  }

  /// Null finché il pannello non viene aperto la prima volta (dopo il bootstrap
  /// della cartella `~/osn`). La UI del pannello va costruita solo quando != null.
  TerminalSessionManager? get managerOrNull => _manager;

  /// Apre/chiude il pannello. All'apertura: assicura la cartella `~/osn`
  /// (+ `.mcp.json`/`CLAUDE.md`), crea il manager se serve e — se non ci sono
  /// sessioni — ne avvia una (che auto-lancia `claude`).
  Future<void> toggle() async {
    _isOpen = !_isOpen;
    notifyListeners();
    if (_isOpen) {
      await _ensureReady();
    }
  }

  Future<void> open() async {
    if (_isOpen) return;
    _isOpen = true;
    notifyListeners();
    await _ensureReady();
  }

  void close() {
    if (!_isOpen) return;
    _isOpen = false;
    notifyListeners();
  }

  Future<void> _ensureReady() async {
    if (!Platform.isMacOS) return;
    if (_booting) return;
    if (_manager != null && _manager!.sessions.isNotEmpty) return;
    _booting = true;
    try {
      await terminalCliConfig.loadPrefs();
      final dir = await TerminalBootstrap.ensureWorkspace();
      _manager ??= TerminalSessionManager(
        workingDir: dir,
        skipPermissionsByDefault: _skipPermissionsByDefault,
      );
      // Ripristina le sessioni persistite (con resume) o ne crea una nuova.
      await _manager!.restoreOrCreate();
      notifyListeners();
    } catch (e) {
      debugPrint('TerminalPanelController: bootstrap fallito: $e');
    } finally {
      _booting = false;
    }
  }

  void setWidth(double w) {
    final clamped = w.clamp(minWidth, maxWidth);
    if (clamped == _width) return;
    _width = clamped.toDouble();
    notifyListeners();
  }

  /// Persiste la larghezza corrente. Da chiamare a fine drag del resizer (non a
  /// ogni delta, per non scommerciare scritture inutili).
  void commitWidth() => _persist(_kWidth, _width.toString());

  /// Killa tutte le sessioni (processi PTY). Best-effort a chiusura app.
  void shutdown() {
    _manager?.disposeAll();
  }

  @override
  void dispose() {
    _manager?.disposeAll();
    super.dispose();
  }
}

/// Singleton di modulo condiviso tra il toggle (header) e il pannello.
final TerminalPanelController terminalPanelController = TerminalPanelController();
