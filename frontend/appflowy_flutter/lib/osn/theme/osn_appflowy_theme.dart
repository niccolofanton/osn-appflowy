import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

/// Tema **osn**: palette monocromatica "Notion" applicata SOPRA il tema di
/// default di AppFlowy, **senza toccare** i file (auto-generati) del package
/// `appflowy_ui`.
///
/// Implementa [AppFlowyThemeBuilder] e **delega** a [AppFlowyDefaultTheme] per
/// ottenere il tema base, poi sovrascrive solo i token osn. I campi non toccati
/// vengono letti dal base: così ogni futuro aggiornamento upstream ai token
/// neutri/di sistema viene **ereditato automaticamente** (rebase-friendly).
///
/// Hook unico nell'app: `app_widget.dart` istanzia [OsnAppFlowyTheme] invece di
/// [AppFlowyDefaultTheme]. Prima questa palette era hard-coded dentro
/// `appflowy_ui/.../appflowy_default/semantic.dart` (≈105 righe di conflitto a
/// ogni release upstream); ora vive qui, in un file nuovo a conflitto-zero.
/// Vedi `OSN_PATCHES.md`.
///
/// NB: i `_*With` qui sotto sono dei `copyWith` locali (gli scheme upstream non
/// ne hanno). Elencano TUTTI i campi dello scheme una volta sola ed espongono
/// come parametri solo quelli che osn tocca. Se upstream **aggiunge** un campo a
/// uno scheme, questi costruttori non compilano più: è il segnale (a
/// compile-time) che il rebase ha bisogno di attenzione qui.
class OsnAppFlowyTheme implements AppFlowyThemeBuilder {
  const OsnAppFlowyTheme();

  static final AppFlowyDefaultTheme _base = AppFlowyDefaultTheme();

  @override
  AppFlowyThemeData light({String? fontFamily}) {
    final base = _base.light(fontFamily: fontFamily);
    // Light: l'unico ritocco osn è l'accent (Notion blue) sulla selezione/fill.
    return _withSchemes(
      base,
      fillColorScheme: _fillWith(
        base.fillColorScheme,
        themeThick: const Color(0xFF2383E2),
        themeThickHover: const Color(0xFF1A6CC2),
        themeSelect: const Color(0x472383E2),
        textSelect: const Color(0x472383E2),
      ),
    );
  }

  @override
  AppFlowyThemeData dark({String? fontFamily}) {
    final base = _base.dark(fontFamily: fontFamily);
    return _withSchemes(
      base,
      // Testo Notion (bianco translucido) + accent #2383e2.
      textColorScheme: _textWith(
        base.textColorScheme,
        primary: const Color(0xCFFFFFFF),
        secondary: const Color(0x75FFFFFF),
        tertiary: const Color(0x48FFFFFF),
        quaternary: const Color(0x30FFFFFF),
        action: const Color(0xFF2383E2),
        actionHover: const Color(0xFF529AE8),
        info: const Color(0xFF2383E2),
        infoHover: const Color(0xFF529AE8),
      ),
      // Icone Notion (bianco translucido) + accent.
      iconColorScheme: _iconWith(
        base.iconColorScheme,
        primary: const Color(0xCFFFFFFF),
        secondary: const Color(0x75FFFFFF),
        tertiary: const Color(0x48FFFFFF),
        quaternary: const Color(0x30FFFFFF),
        infoThick: const Color(0xFF2383E2),
        infoThickHover: const Color(0xFF529AE8),
      ),
      // Bordi Notion sottili (bianco translucido) + accent.
      borderColorScheme: _borderWith(
        base.borderColorScheme,
        primary: const Color(0x18FFFFFF),
        primaryHover: const Color(0x24FFFFFF),
        themeThick: const Color(0xFF2383E2),
        themeThickHover: const Color(0xFF1A6CC2),
        infoThick: const Color(0xFF2383E2),
        infoThickHover: const Color(0xFF529AE8),
      ),
      // Fill Notion (hover item/menu) + accent + selezione.
      fillColorScheme: _fillWith(
        base.fillColorScheme,
        primary: const Color(0xFF202020),
        primaryHover: const Color(0xFF252525),
        themeThick: const Color(0xFF2383E2),
        themeThickHover: const Color(0xFF1A6CC2),
        themeSelect: const Color(0x472383E2),
        textSelect: const Color(0x472383E2),
      ),
      // Superfici Notion (popover, dialog, card, menu, impostazioni). Riscritte
      // per intero, quindi costruite direttamente (niente delega al base).
      surfaceColorScheme: const AppFlowySurfaceColorScheme(
        primary: Color(0xFF191919),
        primaryHover: Color(0xFF252525),
        layer01: Color(0xFF202020),
        layer01Hover: Color(0xFF252525),
        layer02: Color(0xFF252525),
        layer02Hover: Color(0xFF2F2F2F),
        layer03: Color(0xFF2F2F2F),
        layer03Hover: Color(0xFF373737),
        layer04: Color(0xFF373737),
        layer04Hover: Color(0xFF3D3D3D),
        inverse: Color(0xFF373737),
        secondary: Color(0xFF202020),
        overlay: Color(0x99000000),
      ),
      // Container Notion.
      surfaceContainerColorScheme: const AppFlowySurfaceContainerColorScheme(
        layer01: Color(0xFF202020),
        layer02: Color(0xFF252525),
        layer03: Color(0xFF2F2F2F),
      ),
      // Sfondo app Notion.
      backgroundColorScheme: const AppFlowyBackgroundColorScheme(
        primary: Color(0xFF191919),
      ),
    );
  }

  /// Ricostruisce [base] sostituendo solo gli scheme passati (gli altri restano
  /// quelli del default upstream → ereditati). [AppFlowyThemeData] non ha un
  /// `copyWith`, quindi va rifatto a mano elencando i 14 campi una volta.
  static AppFlowyThemeData _withSchemes(
    AppFlowyThemeData base, {
    AppFlowyTextColorScheme? textColorScheme,
    AppFlowyIconColorScheme? iconColorScheme,
    AppFlowyBorderColorScheme? borderColorScheme,
    AppFlowyBackgroundColorScheme? backgroundColorScheme,
    AppFlowyFillColorScheme? fillColorScheme,
    AppFlowySurfaceColorScheme? surfaceColorScheme,
    AppFlowySurfaceContainerColorScheme? surfaceContainerColorScheme,
  }) {
    return AppFlowyThemeData(
      textColorScheme: textColorScheme ?? base.textColorScheme,
      textStyle: base.textStyle,
      iconColorScheme: iconColorScheme ?? base.iconColorScheme,
      borderColorScheme: borderColorScheme ?? base.borderColorScheme,
      backgroundColorScheme:
          backgroundColorScheme ?? base.backgroundColorScheme,
      fillColorScheme: fillColorScheme ?? base.fillColorScheme,
      surfaceColorScheme: surfaceColorScheme ?? base.surfaceColorScheme,
      borderRadius: base.borderRadius,
      spacing: base.spacing,
      shadow: base.shadow,
      brandColorScheme: base.brandColorScheme,
      surfaceContainerColorScheme:
          surfaceContainerColorScheme ?? base.surfaceContainerColorScheme,
      badgeColorScheme: base.badgeColorScheme,
      otherColorsColorScheme: base.otherColorsColorScheme,
    );
  }

  static AppFlowyTextColorScheme _textWith(
    AppFlowyTextColorScheme b, {
    Color? primary,
    Color? secondary,
    Color? tertiary,
    Color? quaternary,
    Color? action,
    Color? actionHover,
    Color? info,
    Color? infoHover,
  }) {
    return AppFlowyTextColorScheme(
      primary: primary ?? b.primary,
      secondary: secondary ?? b.secondary,
      tertiary: tertiary ?? b.tertiary,
      quaternary: quaternary ?? b.quaternary,
      onFill: b.onFill,
      action: action ?? b.action,
      actionHover: actionHover ?? b.actionHover,
      info: info ?? b.info,
      infoHover: infoHover ?? b.infoHover,
      success: b.success,
      successHover: b.successHover,
      warning: b.warning,
      warningHover: b.warningHover,
      error: b.error,
      errorHover: b.errorHover,
      featured: b.featured,
      featuredHover: b.featuredHover,
    );
  }

  static AppFlowyIconColorScheme _iconWith(
    AppFlowyIconColorScheme b, {
    Color? primary,
    Color? secondary,
    Color? tertiary,
    Color? quaternary,
    Color? infoThick,
    Color? infoThickHover,
  }) {
    return AppFlowyIconColorScheme(
      primary: primary ?? b.primary,
      secondary: secondary ?? b.secondary,
      tertiary: tertiary ?? b.tertiary,
      quaternary: quaternary ?? b.quaternary,
      onFill: b.onFill,
      featuredThick: b.featuredThick,
      featuredThickHover: b.featuredThickHover,
      infoThick: infoThick ?? b.infoThick,
      infoThickHover: infoThickHover ?? b.infoThickHover,
      successThick: b.successThick,
      successThickHover: b.successThickHover,
      warningThick: b.warningThick,
      warningThickHover: b.warningThickHover,
      errorThick: b.errorThick,
      errorThickHover: b.errorThickHover,
    );
  }

  static AppFlowyBorderColorScheme _borderWith(
    AppFlowyBorderColorScheme b, {
    Color? primary,
    Color? primaryHover,
    Color? themeThick,
    Color? themeThickHover,
    Color? infoThick,
    Color? infoThickHover,
  }) {
    return AppFlowyBorderColorScheme(
      primary: primary ?? b.primary,
      primaryHover: primaryHover ?? b.primaryHover,
      secondary: b.secondary,
      secondaryHover: b.secondaryHover,
      tertiary: b.tertiary,
      tertiaryHover: b.tertiaryHover,
      themeThick: themeThick ?? b.themeThick,
      themeThickHover: themeThickHover ?? b.themeThickHover,
      infoThick: infoThick ?? b.infoThick,
      infoThickHover: infoThickHover ?? b.infoThickHover,
      successThick: b.successThick,
      successThickHover: b.successThickHover,
      warningThick: b.warningThick,
      warningThickHover: b.warningThickHover,
      errorThick: b.errorThick,
      errorThickHover: b.errorThickHover,
      featuredThick: b.featuredThick,
      featuredThickHover: b.featuredThickHover,
    );
  }

  static AppFlowyFillColorScheme _fillWith(
    AppFlowyFillColorScheme b, {
    Color? primary,
    Color? primaryHover,
    Color? themeThick,
    Color? themeThickHover,
    Color? themeSelect,
    Color? textSelect,
  }) {
    return AppFlowyFillColorScheme(
      primary: primary ?? b.primary,
      primaryHover: primaryHover ?? b.primaryHover,
      secondary: b.secondary,
      secondaryHover: b.secondaryHover,
      tertiary: b.tertiary,
      tertiaryHover: b.tertiaryHover,
      quaternary: b.quaternary,
      quaternaryHover: b.quaternaryHover,
      content: b.content,
      contentHover: b.contentHover,
      contentVisible: b.contentVisible,
      contentVisibleHover: b.contentVisibleHover,
      themeThick: themeThick ?? b.themeThick,
      themeThickHover: themeThickHover ?? b.themeThickHover,
      themeSelect: themeSelect ?? b.themeSelect,
      textSelect: textSelect ?? b.textSelect,
      infoLight: b.infoLight,
      infoLightHover: b.infoLightHover,
      infoThick: b.infoThick,
      infoThickHover: b.infoThickHover,
      successLight: b.successLight,
      successLightHover: b.successLightHover,
      warningLight: b.warningLight,
      warningLightHover: b.warningLightHover,
      errorLight: b.errorLight,
      errorLightHover: b.errorLightHover,
      errorThick: b.errorThick,
      errorThickHover: b.errorThickHover,
      errorSelect: b.errorSelect,
      featuredLight: b.featuredLight,
      featuredLightHover: b.featuredLightHover,
      featuredThick: b.featuredThick,
      featuredThickHover: b.featuredThickHover,
    );
  }
}
