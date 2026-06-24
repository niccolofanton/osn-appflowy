import 'dart:async';
import 'dart:io';

/// Prepara la workspace locale usata dal terminale embeddato osn.
///
/// Si occupa di creare la directory di lavoro (default `~/osn`) e di
/// inizializzare i file di contesto (`.mcp.json` e `CLAUDE.md`) usati
/// dall'agente Claude lanciato nel terminale. I file esistenti non vengono
/// mai sovrascritti, così le personalizzazioni dell'utente sono preservate.
class TerminalBootstrap {
  const TerminalBootstrap._();

  /// Template del file `.mcp.json` (server MCP stdio weironz/appflowy-mcp via
  /// `uvx`). I valori in `env` sono placeholder `CHANGE_ME...` da compilare.
  static String mcpJsonTemplate() {
    return '''
{
  "mcpServers": {
    "appflowy": {
      "command": "uvx",
      "args": [
        "appflowy-mcp"
      ],
      "env": {
        "APPFLOWY_BASE_URL": "https://CHANGE_ME.appflowy.tld",
        "APPFLOWY_EMAIL": "CHANGE_ME@example.com",
        "APPFLOWY_PASSWORD": "CHANGE_ME"
      }
    }
  }
}
''';
  }

  /// Template del file `CLAUDE.md` con il contesto della workspace osn.
  static String claudeMdTemplate() {
    return '''
# osn workspace

Questo workspace è collegato alle note **osn** (AppFlowy self-hosted) tramite il server MCP `appflowy`.

Usa i tool `appflowy_*` (o equivalenti del server) per elencare workspace, leggere ed editare le pagine.

Prerequisiti: `uv` installato (`brew install uv`) e i valori in `.mcp.json` compilati (URL/credenziali del tuo AppFlowy Cloud).

Alternativa con scoping a token: server `m2n2/appflowy-mcp` in HTTP (`type:"http"`, bearer token) — vedi note del progetto.
''';
  }

  /// Garantisce che la workspace osn esista e contenga i file di contesto.
  ///
  /// [customDir] permette di indirizzare una directory specifica (usata nei
  /// test); in assenza viene usata `~/osn`. La directory viene creata se manca.
  /// `.mcp.json` e `CLAUDE.md` vengono scritti SOLO se non esistono già, così
  /// le modifiche dell'utente non vengono mai sovrascritte.
  ///
  /// Ritorna il path della directory della workspace.
  static Future<String> ensureWorkspace({String? customDir}) async {
    final dir = customDir ?? '${Platform.environment['HOME']}/osn';

    final directory = Directory(dir);
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }

    final mcpFile = File('$dir/.mcp.json');
    if (!mcpFile.existsSync()) {
      await mcpFile.writeAsString(mcpJsonTemplate());
    }

    final claudeMdFile = File('$dir/CLAUDE.md');
    if (!claudeMdFile.existsSync()) {
      await claudeMdFile.writeAsString(claudeMdTemplate());
    }

    return dir;
  }
}
