import 'package:flutter/widgets.dart';
import 'package:xterm/xterm.dart';

/// Tema del terminale embeddato osn — palette "Notion dark".
///
/// Pannello custom: NON dipende dal Theme di AppFlowy, usa solo queste
/// costanti e questo [TerminalTheme].
const TerminalTheme osnTerminalTheme = TerminalTheme(
  cursor: Color(0xFF2383E2),
  selection: Color(0x402383E2),
  foreground: Color(0xFFD4D4D4),
  background: Color(0xFF191919),
  black: Color(0xFF191919),
  red: Color(0xFFEB5757),
  green: Color(0xFF27AE60),
  yellow: Color(0xFFE2B93B),
  blue: Color(0xFF2383E2),
  magenta: Color(0xFF9B51E0),
  cyan: Color(0xFF2D9CDB),
  white: Color(0xFFD4D4D4),
  brightBlack: Color(0xFF5A5A5A),
  brightRed: Color(0xFFFF6B6B),
  brightGreen: Color(0xFF6FCF97),
  brightYellow: Color(0xFFF2C94C),
  brightBlue: Color(0xFF529AE8),
  brightMagenta: Color(0xFFBB6BD9),
  brightCyan: Color(0xFF56CCF2),
  brightWhite: Color(0xFFFFFFFF),
  searchHitBackground: Color(0xFF2383E2),
  searchHitBackgroundCurrent: Color(0xFF529AE8),
  searchHitForeground: Color(0xFF191919),
);

/// Sfondo principale del pannello terminale.
const Color kOsnPanelBg = Color(0xFF191919);

/// Strato leggermente sollevato (colonna sessioni).
const Color kOsnPanelLayer = Color(0xFF202020);

/// Bordo sottile tra i pannelli.
const Color kOsnPanelBorder = Color(0x18FFFFFF);

/// Testo primario.
const Color kOsnTextPrimary = Color(0xCFFFFFFF);

/// Testo secondario / placeholder.
const Color kOsnTextSecondary = Color(0x75FFFFFF);

/// Accent (Notion blue).
const Color kOsnAccent = Color(0xFF2383E2);

/// Sfondo della riga sessione attiva.
const Color kOsnActiveBg = Color(0xFF2F2F2F);
