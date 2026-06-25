import 'package:flutter/foundation.dart';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/startup/startup.dart';

/// Un harness/agente CLI lanciabile nel terminale osn.
@immutable
class CliHarness {
  const CliHarness({
    required this.id,
    required this.label,
    required this.command,
    required this.skipPermissionsFlag,
    required this.resumeArgs,
  });

  final String id;
  final String label;

  /// Comando base (es. `claude`).
  final String command;

  /// Flag per saltare i permessi (es. `--dangerously-skip-permissions`).
  final String skipPermissionsFlag;

  /// Argomenti per riprendere l'ultima conversazione (es. `--continue`).
  final String resumeArgs;
}

/// Preset comuni (sintassi verificate online — vedi tabella nella PR osn).
const List<CliHarness> kCliHarnessPresets = [
  CliHarness(
    id: 'claude',
    label: 'Claude Code',
    command: 'claude',
    skipPermissionsFlag: '--dangerously-skip-permissions',
    resumeArgs: '--continue',
  ),
  CliHarness(
    id: 'codex',
    label: 'Codex (OpenAI)',
    command: 'codex',
    // alias di --dangerously-bypass-approvals-and-sandbox
    skipPermissionsFlag: '--yolo',
    resumeArgs: 'resume --last',
  ),
  CliHarness(
    id: 'opencode',
    label: 'opencode',
    command: 'opencode',
    skipPermissionsFlag: '--dangerously-skip-permissions',
    resumeArgs: '--continue',
  ),
];

/// Configurazione (persistita) dell'harness CLI usato dal terminale osn.
///
/// Singleton di modulo come [terminalPanelController]; la pagina Impostazioni →
/// "Agent CLI" la edita, il manager la legge per costruire il comando di
/// auto-launch. Selezionando un harness dal dropdown i campi vengono
/// ripopolati col preset (e restano editabili).
class TerminalCliConfig extends ChangeNotifier {
  static const String _kId = 'osn_terminal_cli_harness';
  static const String _kCommand = 'osn_terminal_cli_command';
  static const String _kSkip = 'osn_terminal_cli_skip_flag';
  static const String _kResume = 'osn_terminal_cli_resume_args';

  String _harnessId = kCliHarnessPresets.first.id;
  String _command = kCliHarnessPresets.first.command;
  String _skipFlag = kCliHarnessPresets.first.skipPermissionsFlag;
  String _resumeArgs = kCliHarnessPresets.first.resumeArgs;
  bool _loaded = false;

  String get harnessId => _harnessId;
  String get command => _command;
  String get skipPermissionsFlag => _skipFlag;
  String get resumeArgs => _resumeArgs;

  Future<void> loadPrefs() async {
    if (_loaded) return;
    _loaded = true;
    final kv = getIt<KeyValueStorage>();
    _harnessId = await kv.get(_kId) ?? _harnessId;
    _command = await kv.get(_kCommand) ?? _command;
    _skipFlag = await kv.get(_kSkip) ?? _skipFlag;
    _resumeArgs = await kv.get(_kResume) ?? _resumeArgs;
    notifyListeners();
  }

  /// Seleziona un harness preset: ripopola comando/flag/resume e persiste.
  void selectHarness(String id) {
    final preset = kCliHarnessPresets.firstWhere(
      (h) => h.id == id,
      orElse: () => kCliHarnessPresets.first,
    );
    _harnessId = preset.id;
    _command = preset.command;
    _skipFlag = preset.skipPermissionsFlag;
    _resumeArgs = preset.resumeArgs;
    notifyListeners();
    final kv = getIt<KeyValueStorage>();
    kv.set(_kId, _harnessId);
    kv.set(_kCommand, _command);
    kv.set(_kSkip, _skipFlag);
    kv.set(_kResume, _resumeArgs);
  }

  void setCommand(String v) {
    _command = v;
    notifyListeners();
    getIt<KeyValueStorage>().set(_kCommand, v);
  }

  void setSkipPermissionsFlag(String v) {
    _skipFlag = v;
    notifyListeners();
    getIt<KeyValueStorage>().set(_kSkip, v);
  }

  void setResumeArgs(String v) {
    _resumeArgs = v;
    notifyListeners();
    getIt<KeyValueStorage>().set(_kResume, v);
  }

  /// Comando di auto-launch (senza newline). [skip] aggiunge il flag
  /// salta-permessi; [resume] antepone gli argomenti di resume.
  String buildLaunchCommand({required bool skip, bool resume = false}) {
    final parts = <String>[_command.trim()];
    if (resume && _resumeArgs.trim().isNotEmpty) parts.add(_resumeArgs.trim());
    if (skip && _skipFlag.trim().isNotEmpty) parts.add(_skipFlag.trim());
    return parts.where((p) => p.isNotEmpty).join(' ');
  }
}

/// Singleton di modulo condiviso tra la pagina Impostazioni e il manager.
final TerminalCliConfig terminalCliConfig = TerminalCliConfig();
