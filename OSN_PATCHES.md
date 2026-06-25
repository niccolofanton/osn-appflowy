# OSN — mappa delle patch sul fork

Questo fork (`niccolofanton/osn-appflowy`, branch `osn`) è pensato come una **patch
non distruttiva da applicare on-top** di AppFlowy upstream, per minimizzare i conflitti
nei rebase sui tag upstream futuri. Base corrente: tag **`0.12.5`** (`4af02cdc8`).

Linee guida di manutenzione:
- Ogni edit a un file upstream è marcato con un commento `// OSN:` per il triage dei conflitti.
- I **lock file** (`pubspec.lock`, `macos/Podfile.lock`) NON si mergiano a mano: in caso di
  conflitto prendere la versione upstream e rigenerare con `flutter pub get` + `pod install`.
- `xterm` in pub-cache deve restare **vanilla** (eventuali patch di debug vanno rimosse;
  la logica osn vive solo in `lib/plugins/terminal/**`).
- Tutto il backend (`rust-lib`, `appflowy_web`) è **intatto**: nessuna modifica.

## File upstream MODIFICATI (rischio rebase)

Tutti i path sono relativi a `frontend/appflowy_flutter/`.

### Tema Notion / chrome monocromatica
| File | Modifica | Rischio |
|---|---|---|
| `lib/startup/tasks/app_widget.dart` | hook tema: `AppFlowyDefaultTheme()` → `OsnAppFlowyTheme()` (1 riga + 1 import) | BASSO |
| `lib/workspace/application/settings/appearance/base_appearance.dart` | font default `Geist`/`Geist Mono` | MEDIO |
| `lib/plugins/shared/share/_shared.dart` | pulsante Share come sola icona | **ALTO** |
| `lib/workspace/presentation/home/menu/sidebar/footer/sidebar_footer.dart` | rimozione divider + resize icone | **ALTO** |
| `lib/workspace/presentation/home/menu/sidebar/sidebar.dart` | colore sidebar → `surface`; rimozione divider footer | MEDIO |
| `lib/workspace/presentation/home/home_stack.dart` | `surfaceContainerHighest` → `surface` (top bar) | BASSO |
| `lib/shared/window_title_bar.dart` | `surfaceContainerHighest` → `surface` | BASSO |
| `lib/workspace/presentation/home/tabs/flowy_tab.dart` | tab non attivo → `surface` | BASSO |
| `lib/workspace/presentation/home/tabs/tabs_manager.dart` | `surfaceContainerHighest` → `surface` | BASSO |
| `lib/workspace/presentation/home/menu/sidebar/shared/sidebar_new_page_button.dart` | icona `add_m` + size 20 | BASSO |
| `lib/user/presentation/screens/sign_in_screen/widgets/logo/logo.dart` | logo monocromo (`onSurface`) | BASSO |
| `lib/plugins/document/presentation/document_collaborators.dart` | avatar size `s` | BASSO |

### Terminale embeddato + Impostazioni Agent CLI
| File | Modifica | Rischio |
|---|---|---|
| `lib/plugins/document/document.dart` | header: `ViewFavoriteButton` → `TerminalHeaderButton` (preferito spostato nel ⋯) | MEDIO (sostitutivo) |
| `lib/plugins/database/tab_bar/tab_bar_view.dart` | idem | MEDIO (sostitutivo) |
| `lib/workspace/presentation/home/desktop_home_screen.dart` | wrap body in `_wrapWithTerminalPanel` (⌥⌘T + pannello) | MEDIO (additivo) |
| `lib/workspace/presentation/widgets/more_view_actions/more_view_actions.dart` | aggiunge `FavoriteAction` nel menu ⋯ | BASSO |
| `lib/workspace/application/settings/settings_dialog_bloc.dart` | enum `SettingsPage.agentCli` | BASSO |
| `lib/workspace/presentation/settings/settings_dialog.dart` | dispatch case `agentCli` → `SettingsAgentCliView` | BASSO |
| `lib/workspace/presentation/settings/widgets/settings_menu.dart` | voce di menu "Agent CLI" (macOS) | BASSO |

### Auto-update (pipeline fork)
| File | Modifica | Rischio |
|---|---|---|
| `lib/startup/tasks/auto_update_task.dart` | feed Sparkle → `niccolofanton/osn-appflowy` | BASSO |
| `lib/shared/version_checker/version_checker.dart` | pagina download Linux → repo fork | BASSO |
| `macos/Runner/Info.plist` | `SUPublicEDKey` del fork | BASSO |
| `dsa_pub.pem` | chiave DSA legacy del fork (sostituzione intero file) | BASSO |

### Build / config
| File | Modifica | Rischio |
|---|---|---|
| `pubspec.yaml` | +`flutter_pty ^0.4.2`, +`xterm ^4.0.0`; font Geist/Geist Mono; `version` bump | MEDIO |
| `pubspec.lock`, `macos/Podfile.lock` | conseguenza deps (rigenerare, non mergiare) | MEDIO |
| `macos/Runner/Assets.xcassets/AppIcon.appiconset/*.png` | icona app monocroma | BASSO (binari) |

## File NUOVI (basso rischio rebase — solo aggiunte)
- `lib/osn/theme/osn_appflowy_theme.dart` — **tema Notion** come `AppFlowyThemeBuilder` che
  **delega** ad `AppFlowyDefaultTheme` e sovrascrive solo i token osn (i non-osn sono ereditati dal
  default → upstream-proof). Sostituisce l'ex patch da ~105 righe dentro `appflowy_ui/.../semantic.dart`
  (ora **vanilla**). Test di non-regressione in `test/osn/osn_theme_test.dart`.
- `lib/plugins/terminal/**` — feature terminale embeddato (self-contained).
- `lib/plugins/terminal/application/terminal_cli_config.dart` — preset/config harness CLI.
- `lib/plugins/terminal/presentation/settings_agent_cli_view.dart` — pagina Impostazioni "Agent CLI".
- `lib/workspace/presentation/widgets/more_view_actions/widgets/favorite_action.dart` — voce preferiti per il menu ⋯.
- `test/terminal/terminal_bootstrap_test.dart` — test bootstrap.
- `assets/google_fonts/Geist*/**` — font bundlati.

## Punti di attrito noti (da review multi-agente, 2026-06-25)
1. ~~`semantic.dart`~~ — **RISOLTO 2026-06-25**: estratto in `lib/osn/theme/osn_appflowy_theme.dart`
   (delega + override). Il file upstream è tornato **vanilla**: zero conflitto sul tema.
2. Header preferiti (`document.dart`/`tab_bar_view.dart`) — **sostitutivo** (`ViewFavoriteButton` →
   `TerminalHeaderButton`). Tenuto così di proposito: la versione "additiva" reintrodurrebbe la stella
   nell'header (l'utente vuole il solo ✨). Attrito accettato: MEDIO ma piccolo (≈14 righe, marcate `// OSN:`).
   `chat.dart` non è uniformato.
3. `pubspec.yaml` `version` bump — confligge a ogni release upstream (cosmetico).

## Procedura di rebase su un nuovo tag upstream

Il branch `osn` è una **serie di patch** sopra un tag upstream. Per allinearsi a `X.Y.Z`:

```sh
cd ~/work/AppFlowy
git fetch upstream --tags
OLD=0.12.5            # tag su cui osn è attualmente basato (vedi sopra: "Base corrente")
NEW=X.Y.Z            # nuovo tag upstream

git switch osn && git branch osn-backup-$OLD     # rete di sicurezza
git rebase --onto "$NEW" "$OLD" osn              # riapplica SOLO i commit osn sul nuovo tag
```

Durante il rebase, ad ogni conflitto:
- **lock file** (`pubspec.lock`, `macos/Podfile.lock`): `git checkout --theirs <file>` poi rigenera a
  fine rebase con `flutter pub get` + `cd macos && pod install`. **Mai** risolverli a mano.
- **file con marcatori `// OSN:`**: tieni la riga osn accanto a quella upstream nuova (triage rapido).
- **tema**: non dovrebbe più confliggere (è in `lib/osn/theme/**`); se cambia l'**interfaccia**
  `AppFlowyThemeBuilder` o un costruttore di scheme, `OsnAppFlowyTheme` non compila → adegua lì.

Dopo il rebase, **verifica di non-regressione** (in `frontend/appflowy_flutter/`):
```sh
flutter pub get && dart analyze lib/osn lib/plugins/terminal lib/startup/tasks/app_widget.dart
flutter test test/osn test/terminal           # tema + bootstrap terminale
flutter build macos --debug                    # compilazione end-to-end
```
Infine aggiorna `OLD` → `$NEW` nella riga "Base corrente" in cima a questo file e il `version` in `pubspec.yaml`.
