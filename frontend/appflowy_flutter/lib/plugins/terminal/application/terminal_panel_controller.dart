import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import 'package:appflowy/plugins/terminal/application/terminal_session_manager.dart';
import 'package:appflowy/plugins/terminal/bootstrap/terminal_bootstrap.dart';

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

  bool _isOpen = false;
  double _width = defaultWidth;
  bool _booting = false;
  TerminalSessionManager? _manager;

  bool get isOpen => _isOpen;
  double get width => _width;

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
      final dir = await TerminalBootstrap.ensureWorkspace();
      _manager ??= TerminalSessionManager(workingDir: dir);
      if (_manager!.sessions.isEmpty) {
        _manager!.newSession();
      }
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
