import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ─────────────────────────────────────────────
  // Brand Colors — unchanged from original
  // ─────────────────────────────────────────────
  static const Color primary      = Color(0xFF2A9D8F);
  static const Color primaryDark  = Color(0xFF1F7A6E);
  static const Color primaryLight = Color(0xFFE8F5F2);
  static const Color primarySoft  = Color(0x182A9D8F);

  // ─────────────────────────────────────────────
  // Backgrounds — unchanged
  // ─────────────────────────────────────────────
  static const Color bg      = Color(0xFFF7F8FA);
  static const Color white   = Color(0xFFFFFFFF);
  static const Color card    = Color(0xFFFFFFFF);
  static const Color inputBg = Color(0xFFF2F4F7);

  // ─────────────────────────────────────────────
  // Text — unchanged
  // ─────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint      = Color(0xFF9CA3AF);
  static const Color textWhite     = Color(0xFFFFFFFF);

  // ─────────────────────────────────────────────
  // Semantic accent colors
  //
  // The original 0x18 transparent *Soft variants are kept UNCHANGED
  // so every existing screen that references them continues to compile.
  //
  // NEW: opaque equivalents (*SoftO) added alongside.
  // Use these inside const BoxDecoration — transparent colors cannot
  // appear in compile-time constants.
  // ─────────────────────────────────────────────
  static const Color success      = Color(0xFF22C55E);
  static const Color successSoft  = Color(0x1822C55E); // original — kept
  static const Color successSoftO = Color(0xFFE8F8EE); // opaque — use in const

  static const Color error        = Color(0xFFEF4444);
  static const Color errorSoft    = Color(0x18EF4444); // original — kept
  static const Color errorSoftO   = Color(0xFFFEE8E8); // opaque — use in const

  static const Color warning      = Color(0xFFF59E0B);
  static const Color warningSoft  = Color(0x18F59E0B); // original — kept
  static const Color warningSoftO = Color(0xFFFFF7E6); // opaque — use in const

  static const Color info         = Color(0xFF3B82F6);
  static const Color infoSoft     = Color(0x183B82F6); // original — kept
  static const Color infoSoftO    = Color(0xFFEBF2FF); // opaque — use in const

  // purple already existed but its soft was transparent — same treatment
  static const Color purple       = Color(0xFF8B5CF6);
  static const Color purpleSoft   = Color(0x188B5CF6); // original — kept
  static const Color purpleSoftO  = Color(0xFFF0EBFF); // opaque — use in const

  // ─────────────────────────────────────────────
  // Borders & Shadows
  // ─────────────────────────────────────────────
  static const Color border      = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF0F1F3);
  static const Color shadow      = Color(0x0A000000);

  // ─────────────────────────────────────────────
  // Backward-compatible aliases — unchanged
  // ─────────────────────────────────────────────
  static const Color blue      = primary;
  static const Color blueSoft  = primarySoft;
  static const Color teal      = Color(0xFF22C55E);
  static const Color tealSoft  = successSoft;
  static const Color red       = error;
  static const Color redSoft   = errorSoft;
  static const Color amber     = warning;
  static const Color amberSoft = warningSoft;
  static const Color bgCard    = card;
  static const Color bgInput   = inputBg;
  static const Color textDim   = textSecondary;
  static const Color textFaint = textHint;

  // ─────────────────────────────────────────────
  // Gradients
  // ─────────────────────────────────────────────

  /// Original — unchanged.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, Color(0xFF3DB8A9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// NEW — used on the home screen hero / banner card.
  static const LinearGradient bannerGradient = LinearGradient(
    colors: [Color(0xFF2A9D8F), Color(0xFF45B7A8)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  // ─────────────────────────────────────────────
  // NEW — Shadow lists
  //
  // const lists — never allocated per-build.
  // Use these instead of writing BoxShadow inline
  // inside widget build() methods.
  // ─────────────────────────────────────────────

  /// Large card shadow — matches the original cardDecoration getter.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, 4)),
  ];

  /// Tighter shadow for list items and smaller cards.
  static const List<BoxShadow> cardShadowSm = [
    BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 2)),
  ];

  /// Shadow for menu / profile item rows.
  static const List<BoxShadow> menuShadow = [
    BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// Shadow for incoming chat bubbles.
  static const List<BoxShadow> chatOtherShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// Upward shadow for the chat input bar container.
  static const List<BoxShadow> inputBarShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, -2)),
  ];

  /// Colored glow for the home screen banner card.
  static const List<BoxShadow> bannerShadow = [
    BoxShadow(color: Color(0x402A9D8F), blurRadius: 20, offset: Offset(0, 8)),
  ];

  // ─────────────────────────────────────────────
  // NEW — BorderRadius constants
  //
  // BorderRadius.circular(n) allocates a new Radius
  // object on every build(). These are evaluated once
  // at compile time.
  // ─────────────────────────────────────────────
  static const BorderRadius radius8    = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radius10   = BorderRadius.all(Radius.circular(10));
  static const BorderRadius radius11   = BorderRadius.all(Radius.circular(11));
  static const BorderRadius radius12   = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radius14   = BorderRadius.all(Radius.circular(14));
  static const BorderRadius radius16   = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radius18   = BorderRadius.all(Radius.circular(18));
  static const BorderRadius radius20   = BorderRadius.all(Radius.circular(20));
  static const BorderRadius radius24   = BorderRadius.all(Radius.circular(24));

  /// Rounded top corners only — used by BottomSheet.
  static const BorderRadius radiusTop20 = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
  );

  // ─────────────────────────────────────────────
  // NEW — Shared BoxDecorations (const)
  //
  // The original cardDecoration / cardDecorationBordered
  // getters are kept unchanged below for backward
  // compatibility. These const versions are for new
  // widgets that can use compile-time constants.
  // ─────────────────────────────────────────────

  /// Standard card, large shadow, radius 16.
  /// const equivalent of the original cardDecoration getter.
  static const BoxDecoration cardDecorationConst = BoxDecoration(
    color: card,
    borderRadius: radius16,
    boxShadow: cardShadow,
  );

  /// Card with small shadow — list items, home cards.
  static const BoxDecoration cardDecorationSm = BoxDecoration(
    color: card,
    borderRadius: radius16,
    boxShadow: cardShadowSm,
  );

  /// Card radius-14 — appointment and stat cards.
  static const BoxDecoration card14Decoration = BoxDecoration(
    color: card,
    borderRadius: radius14,
    boxShadow: cardShadowSm,
  );

  /// Bordered card, no shadow.
  /// const equivalent of the original cardDecorationBordered getter.
  static const BoxDecoration cardDecorationBorderedConst = BoxDecoration(
    color: card,
    borderRadius: radius16,
    border: Border.fromBorderSide(BorderSide(color: border)),
  );

  /// Menu / profile item rows.
  static const BoxDecoration menuDecoration = BoxDecoration(
    color: card,
    borderRadius: radius14,
    boxShadow: menuShadow,
  );

  /// Chat input bar bottom container.
  static const BoxDecoration inputBarDecoration = BoxDecoration(
    color: white,
    boxShadow: inputBarShadow,
  );

  // ── Original getters — preserved for backward compatibility ──────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(color: shadow, blurRadius: 20, offset: Offset(0, 4)),
    ],
  );

  static BoxDecoration get cardDecorationBordered => BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: border, width: 1),
  );

  // ─────────────────────────────────────────────
  // NEW — BorderSide constants
  // ─────────────────────────────────────────────
  static const BorderSide primaryBorder = BorderSide(color: primary, width: 1.5);
  static const BorderSide neutralBorder = BorderSide(color: border,  width: 1.5);
  static const BorderSide errorBorderSm = BorderSide(color: error,   width: 1.0);
  static const BorderSide errorBorderLg = BorderSide(color: error,   width: 1.5);

  // ─────────────────────────────────────────────
  // NEW — Shared TextStyles (const)
  //
  // Use these instead of writing inline TextStyle
  // for these common patterns.
  // ─────────────────────────────────────────────
  static const TextStyle heading1 = TextStyle(
    fontFamily: 'Cairo', fontSize: 22,
    fontWeight: FontWeight.w800, color: textPrimary,
  );
  static const TextStyle heading2 = TextStyle(
    fontFamily: 'Cairo', fontSize: 18,
    fontWeight: FontWeight.w700, color: textPrimary,
  );
  static const TextStyle heading3 = TextStyle(
    fontFamily: 'Cairo', fontSize: 17,
    fontWeight: FontWeight.w700, color: textPrimary,
  );
  static const TextStyle heading4 = TextStyle(
    fontFamily: 'Cairo', fontSize: 15,
    fontWeight: FontWeight.w700, color: textPrimary,
  );
  static const TextStyle bodyMd = TextStyle(
    fontFamily: 'Cairo', fontSize: 14,
    color: textPrimary, height: 1.5,
  );
  static const TextStyle bodySm = TextStyle(
    fontFamily: 'Cairo', fontSize: 13,
    color: textSecondary,
  );
  static const TextStyle labelStyle = TextStyle(
    fontFamily: 'Cairo', fontSize: 12.5,
    fontWeight: FontWeight.w500, color: textSecondary,
  );
  static const TextStyle captionStyle = TextStyle(
    fontFamily: 'Cairo', fontSize: 12,
    color: textHint,
  );

  // ─────────────────────────────────────────────
  // ThemeData
  // ─────────────────────────────────────────────
  static ThemeData get lightTheme {
    // Input borders built once — referenced by inputDecorationTheme.
    final _base = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );
    final _focused = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: primary, width: 1.5),
    );
    final _error = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: error, width: 1),
    );
    final _errorFocused = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: error, width: 1.5),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      primaryColor: primary,
      fontFamily: 'Cairo',

      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primaryDark,
        surface: card,
        error: error,
        onPrimary: textWhite,
        onSecondary: textWhite,
        onSurface: textPrimary,
        onError: textWhite,
      ),

      // ── AppBar ─────────────────────────────────────────────────────────
      // CHANGED: scrolledUnderElevation 0.5 → 0
      // The default 0.5 triggers a full repaint of the AppBar background
      // on every scroll frame in Material 3. Zero eliminates it entirely.
      // surfaceTintColor kept transparent — same as original.
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
        actionsIconTheme: IconThemeData(color: textPrimary),
      ),

      // ── Input Decoration ───────────────────────────────────────────────
      // Every TextField / TextFormField inherits these automatically.
      // Identical to original plus errorStyle fontFamily and iconColors.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        hintStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: textHint,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: _base,
        enabledBorder: _base,
        focusedBorder: _focused,
        errorBorder: _error,
        focusedErrorBorder: _errorFocused,
        errorStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: error,
          fontSize: 12,
        ),
        prefixIconColor: textHint,
        suffixIconColor: textHint,
      ),

      // ── ElevatedButton — identical to original ─────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textWhite,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: const RoundedRectangleBorder(borderRadius: radius14),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ── OutlinedButton — identical to original ─────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border, width: 1.5),
          minimumSize: const Size(double.infinity, 54),
          shape: const RoundedRectangleBorder(borderRadius: radius14),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── TextButton — identical to original ────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── NEW: FloatingActionButton ──────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: textWhite,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // ── SnackBar — identical to original + elevation ───────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: textWhite,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // ── BottomNavigationBar — identical to original ────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primary,
        unselectedItemColor: textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
        ),
      ),

      // ── Divider — identical to original ───────────────────────────────
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 0,
      ),

      // ── Chip — identical to original ──────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: inputBg,
        selectedColor: primaryLight,
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: const RoundedRectangleBorder(borderRadius: radius10),
        side: const BorderSide(color: Colors.transparent),
      ),

      // ── NEW: Card ──────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: radius16),
        margin: EdgeInsets.zero,
      ),

      // ── NEW: BottomSheet ───────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radiusTop20),
        elevation: 0,
      ),

      // ── NEW: Dialog ────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: radius20),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 24,
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),

      // ── NEW: ListTile ──────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          color: textSecondary,
        ),
        iconColor: textSecondary,
      ),

      // ── NEW: Switch ────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? primary : textHint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? primaryLight : borderLight,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ── NEW: ProgressIndicator ─────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
      ),
    );
  }
}