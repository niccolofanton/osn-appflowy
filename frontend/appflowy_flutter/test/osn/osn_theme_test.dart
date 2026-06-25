import 'package:appflowy/osn/theme/osn_appflowy_theme.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifica di NON-regressione per l'estrazione del tema osn da `semantic.dart`
/// a [OsnAppFlowyTheme]. Garantisce che:
///  (a) gli override osn abbiano ESATTAMENTE i valori che erano hard-coded nel
///      `semantic.dart` modificato (snapshot dal diff);
///  (b) ogni campo NON toccato da osn sia identico al tema di default upstream
///      (cioè la delega al base non altera nulla di troppo).
void main() {
  const osnLight = OsnAppFlowyTheme();
  final defaultTheme = AppFlowyDefaultTheme();

  group('OsnAppFlowyTheme.dark — override osn (snapshot palette Notion)', () {
    final t = osnLight.dark();

    test('superfici / sfondo', () {
      expect(t.surfaceColorScheme.primary, const Color(0xFF191919));
      expect(t.surfaceColorScheme.primaryHover, const Color(0xFF252525));
      expect(t.surfaceColorScheme.layer01, const Color(0xFF202020));
      expect(t.surfaceColorScheme.layer04Hover, const Color(0xFF3D3D3D));
      expect(t.surfaceColorScheme.overlay, const Color(0x99000000));
      expect(t.surfaceContainerColorScheme.layer01, const Color(0xFF202020));
      expect(t.surfaceContainerColorScheme.layer03, const Color(0xFF2F2F2F));
      expect(t.backgroundColorScheme.primary, const Color(0xFF191919));
    });

    test('testo / icone (bianco translucido) + accent', () {
      expect(t.textColorScheme.primary, const Color(0xCFFFFFFF));
      expect(t.textColorScheme.quaternary, const Color(0x30FFFFFF));
      expect(t.textColorScheme.action, const Color(0xFF2383E2));
      expect(t.textColorScheme.actionHover, const Color(0xFF529AE8));
      expect(t.iconColorScheme.primary, const Color(0xCFFFFFFF));
      expect(t.iconColorScheme.infoThick, const Color(0xFF2383E2));
    });

    test('bordi + fill + selezione', () {
      expect(t.borderColorScheme.primary, const Color(0x18FFFFFF));
      expect(t.borderColorScheme.primaryHover, const Color(0x24FFFFFF));
      expect(t.borderColorScheme.themeThick, const Color(0xFF2383E2));
      expect(t.fillColorScheme.primary, const Color(0xFF202020));
      expect(t.fillColorScheme.primaryHover, const Color(0xFF252525));
      expect(t.fillColorScheme.themeThick, const Color(0xFF2383E2));
      expect(t.fillColorScheme.themeSelect, const Color(0x472383E2));
      expect(t.fillColorScheme.textSelect, const Color(0x472383E2));
    });
  });

  group('OsnAppFlowyTheme.dark — campi NON-osn ereditati dal default', () {
    final osn = osnLight.dark();
    final def = defaultTheme.dark();

    test('text: success/onFill/error invariati', () {
      expect(osn.textColorScheme.onFill, def.textColorScheme.onFill);
      expect(osn.textColorScheme.success, def.textColorScheme.success);
      expect(osn.textColorScheme.error, def.textColorScheme.error);
      expect(osn.textColorScheme.featured, def.textColorScheme.featured);
    });

    test('icon: featured/success/error invariati', () {
      expect(osn.iconColorScheme.onFill, def.iconColorScheme.onFill);
      expect(osn.iconColorScheme.featuredThick, def.iconColorScheme.featuredThick);
      expect(osn.iconColorScheme.errorThick, def.iconColorScheme.errorThick);
    });

    test('border/fill: secondary/tertiary/error/featured invariati', () {
      expect(osn.borderColorScheme.secondary, def.borderColorScheme.secondary);
      expect(osn.borderColorScheme.errorThick, def.borderColorScheme.errorThick);
      expect(osn.fillColorScheme.content, def.fillColorScheme.content);
      expect(osn.fillColorScheme.errorThick, def.fillColorScheme.errorThick);
      expect(osn.fillColorScheme.featuredThick, def.fillColorScheme.featuredThick);
    });
  });

  group('OsnAppFlowyTheme.light — solo accent fill, resto = default', () {
    final osn = osnLight.light();
    final def = defaultTheme.light();

    test('override accent applicati', () {
      expect(osn.fillColorScheme.themeThick, const Color(0xFF2383E2));
      expect(osn.fillColorScheme.themeThickHover, const Color(0xFF1A6CC2));
      expect(osn.fillColorScheme.themeSelect, const Color(0x472383E2));
      expect(osn.fillColorScheme.textSelect, const Color(0x472383E2));
    });

    test('testo/superfici/sfondo NON toccati in light', () {
      expect(osn.textColorScheme.primary, def.textColorScheme.primary);
      expect(osn.surfaceColorScheme.primary, def.surfaceColorScheme.primary);
      expect(osn.backgroundColorScheme.primary, def.backgroundColorScheme.primary);
      expect(osn.fillColorScheme.primary, def.fillColorScheme.primary);
    });
  });
}
