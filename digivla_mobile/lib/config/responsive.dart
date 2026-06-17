import 'package:flutter/material.dart';

/// Shared layout helpers for phone / small-screen tuning.
class AppResponsive {
  static double screenWidth(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) => screenWidth(context) < 360;

  static bool isNarrow(BuildContext context) => screenWidth(context) < 400;

  static double pagePadding(BuildContext context) {
    final w = screenWidth(context);
    if (w < 360) return 12;
    if (w < 600) return 16;
    return 20;
  }

  static int quickActionColumns(BuildContext context) => isCompact(context) ? 1 : 2;

  static double quickActionAspectRatio(BuildContext context) => isCompact(context) ? 2.4 : 1.15;
}
