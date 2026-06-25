import 'package:flutter/material.dart';

import 'package:appflowy/plugins/terminal/application/terminal_cli_config.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_dropdown.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_input_field.dart';

/// Pagina Impostazioni → "Agent CLI": sceglie quale agente CLI (Claude Code,
/// Codex, opencode, o un comando custom) il terminale osn auto-lancia, e
/// personalizza comando, flag salta-permessi e argomenti di resume. Stato in
/// [terminalCliConfig] (persistito). osn / solo desktop.
class SettingsAgentCliView extends StatefulWidget {
  const SettingsAgentCliView({super.key});

  @override
  State<SettingsAgentCliView> createState() => _SettingsAgentCliViewState();
}

class _SettingsAgentCliViewState extends State<SettingsAgentCliView> {
  @override
  void initState() {
    super.initState();
    terminalCliConfig.loadPrefs();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: terminalCliConfig,
      builder: (context, _) {
        final cfg = terminalCliConfig;
        return SettingsBody(
          title: 'Agent CLI',
          description:
              'Scegli quale agente CLI il terminale osn avvia automaticamente '
              'in ogni nuova sessione, e personalizza comando e flag. Le '
              'sessioni partono in ~/osn (con .mcp.json + CLAUDE.md).',
          children: [
            SettingsCategory(
              title: 'Harness',
              description:
                  'Seleziona un preset: comando e flag qui sotto vengono '
                  'precompilati e restano modificabili.',
              children: [
                SettingsDropdown<String>(
                  key: ValueKey('harness-${cfg.harnessId}'),
                  selectedOption: cfg.harnessId,
                  options: kCliHarnessPresets
                      .map(
                        (h) => DropdownMenuEntry<String>(
                          value: h.id,
                          label: h.label,
                        ),
                      )
                      .toList(),
                  onChanged: cfg.selectHarness,
                ),
              ],
            ),
            SettingsCategory(
              title: 'Comando',
              description: 'Eseguito all\'avvio di ogni nuova sessione.',
              children: [
                SettingsInputField(
                  key: ValueKey('cmd-${cfg.harnessId}'),
                  value: cfg.command,
                  placeholder: 'claude',
                  onSave: cfg.setCommand,
                ),
              ],
            ),
            SettingsCategory(
              title: 'Flag "salta permessi"',
              description:
                  'Aggiunto al comando quando attivi ⚡ nell\'header delle '
                  'sessioni (preferenza persistita).',
              children: [
                SettingsInputField(
                  key: ValueKey('skip-${cfg.harnessId}'),
                  value: cfg.skipPermissionsFlag,
                  placeholder: '--dangerously-skip-permissions',
                  onSave: cfg.setSkipPermissionsFlag,
                ),
              ],
            ),
            SettingsCategory(
              title: 'Argomenti di resume',
              description:
                  'Usati per riprendere la conversazione precedente quando le '
                  'sessioni vengono ripristinate (persistenza).',
              children: [
                SettingsInputField(
                  key: ValueKey('resume-${cfg.harnessId}'),
                  value: cfg.resumeArgs,
                  placeholder: '--continue',
                  onSave: cfg.setResumeArgs,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
