class AppSpace {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 36;

  static double horizontalPaddingForWidth(double width) {
    if (width >= 1200) return 32;
    if (width >= 900) return 28;
    if (width >= 600) return 20;
    return 16;
  }
}
