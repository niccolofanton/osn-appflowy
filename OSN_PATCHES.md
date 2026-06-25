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
| `packages/appflowy_ui/lib/src/theme/data/appflowy_default/semantic.dart` | token palette → monocromo Notion (hardcoded, soprattutto `dark()`) | **ALTO** |
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
- `lib/plugins/terminal/**` — feature terminale embeddato (self-contained).
- `lib/plugins/terminal/application/terminal_cli_config.dart` — preset/config harness CLI.
- `lib/plugins/terminal/presentation/settings_agent_cli_view.dart` — pagina Impostazioni "Agent CLI".
- `lib/workspace/presentation/widgets/more_view_actions/widgets/favorite_action.dart` — voce preferiti per il menu ⋯.
- `test/terminal/terminal_bootstrap_test.dart` — test bootstrap.
- `assets/google_fonts/Geist*/**` — font bundlati.

## Punti di attrito noti (da review multi-agente, 2026-06-25)
1. `semantic.dart` — candidato a refactor in un `ThemeExtension`/builder separato per non toccare il file upstream.
2. Header preferiti (`document.dart`/`tab_bar_view.dart`) — sostitutivo; valutare versione additiva (affiancare invece di rimpiazzare). `chat.dart` non è uniformato.
3. `pubspec.yaml` `version` bump — confligge a ogni release upstream (cosmetico).
