/// Design tokens — the only place colors, spacing, radii and shadows live.
/// Screens never hard-code visual values.
library;

import 'package:flutter/material.dart';

/// The Global Academy of Technology palette, measured from the official logo
/// artwork and from gat.ac.in.
///
/// Two rules this palette must be read with:
///  * [accent] is the globe gold. At roughly 1.9:1 on white it is a fill, a
///    stroke or a highlight — never a text colour, and never a surface that
///    carries white text.
///  * The emblem's navy ocean sits very close to [primary], so the globe is
///    only ever placed on a light chip, never straight onto a primary fill.
abstract final class BrandColors {
  // Primary — GAT's deep indigo-violet, taken from the jubilee mark.
  static const primary = Color(0xFF2E2C71);
  static const primaryDark = Color(0xFF1F1D4F);
  static const primaryLight = Color(0xFF8F8CD6);
  static const primaryContainer = Color(0xFFE5E4F4);
  static const primaryContainerDark = Color(0xFF2A2763);

  // Accent — the gold of the globe.
  static const accent = Color(0xFFD8C925);
  static const accentContainer = Color(0xFFF7F3D2);

  /// Readable ink for text sitting on [accent] or [accentContainer].
  static const onAccent = Color(0xFF3B3506);

  // Neutrals — warmed a few degrees towards violet so the primary reads as
  // part of the palette rather than a colour dropped onto a blue-grey app.
  static const ink = Color(0xFF14132A);
  static const inkSoft = Color(0xFF4B4866);
  static const inkFaint = Color(0xFF918EA8);
  static const surfaceLight = Color(0xFFF8F7FC);
  static const cardLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE5E3EF);

  static const surfaceDark = Color(0xFF0D0B1C);
  static const cardDark = Color(0xFF191733);
  static const borderDark = Color(0xFF2C2A4A);
  static const textDark = Color(0xFFE6E4F2);
  static const textSoftDark = Color(0xFF9A97B5);

  static const success = Color(0xFF16A34A);
  static const successDark = Color(0xFF4ADE80);
  static const danger = Color(0xFFDC2626);
  static const dangerDark = Color(0xFFF87171);
  static const warning = Color(0xFFD97706);
  static const info = Color(0xFF0284C7);
}

/// Semantic colors for the four priorities.
abstract final class PriorityColors {
  static const low = Color(0xFF64748B);
  static const medium = Color(0xFF0284C7);
  static const high = Color(0xFFD97706);
  static const critical = Color(0xFFDC2626);

  static Color of(String priority) => switch (priority) {
        'Low' => low,
        'Medium' => medium,
        'High' => high,
        'Critical' => critical,
        _ => low,
      };
}

/// Semantic colors for complaint statuses.
abstract final class StatusColors {
  static const submitted = Color(0xFF5D5AB8);
  static const assigned = Color(0xFF0891B2);
  static const inProgress = Color(0xFFD97706);
  static const resolved = Color(0xFF16A34A);
  static const rejected = Color(0xFF9F1239);
  static const cancelled = Color(0xFF64748B);

  static Color of(String status) => switch (status) {
        'submitted' => submitted,
        'assigned' => assigned,
        'in_progress' => inProgress,
        'resolved' => resolved,
        'rejected' => rejected,
        'cancelled' => cancelled,
        _ => submitted,
      };
}

abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class Corners {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;
}

abstract final class Elevations {
  static List<BoxShadow> card(Brightness b) => b == Brightness.light
      ? [
          BoxShadow(
              color: BrandColors.ink.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ]
      : [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ];

  static List<BoxShadow> floating(Brightness b) => [
        BoxShadow(
            color: (b == Brightness.light
                    ? BrandColors.primary
                    : Colors.black)
                .withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 8)),
      ];
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 350);
  static const curve = Curves.easeOutCubic;
}
