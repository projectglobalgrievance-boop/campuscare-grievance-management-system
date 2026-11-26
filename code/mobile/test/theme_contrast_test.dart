import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grievance_app/theme/app_theme.dart';
import 'package:grievance_app/theme/tokens.dart';

/// WCAG 2.1 relative luminance.
double _luminance(Color c) {
  double channel(double v) {
    v = v / 255.0;
    return v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel((c.r * 255).roundToDouble()) +
      0.7152 * channel((c.g * 255).roundToDouble()) +
      0.0722 * channel((c.b * 255).roundToDouble());
}

double contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  // AppTheme pulls Manrope through google_fonts, which needs the binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  // The GAT palette is dominated by a very dark violet and a very light gold.
  // Those two are only safe in specific pairings, so the pairings are pinned
  // here: change a token and this fails before anyone ships it.
  group('brand palette contrast', () {
    test('body text is readable on both surfaces', () {
      expect(contrast(BrandColors.ink, BrandColors.surfaceLight),
          greaterThanOrEqualTo(4.5));
      expect(contrast(BrandColors.inkSoft, BrandColors.surfaceLight),
          greaterThanOrEqualTo(4.5));
      expect(contrast(BrandColors.textDark, BrandColors.surfaceDark),
          greaterThanOrEqualTo(4.5));
      expect(contrast(BrandColors.textSoftDark, BrandColors.surfaceDark),
          greaterThanOrEqualTo(4.5));
    });

    test('white type on the primary fill stays legible', () {
      expect(contrast(Colors.white, BrandColors.primary),
          greaterThanOrEqualTo(4.5));
      expect(contrast(Colors.white, BrandColors.primaryDark),
          greaterThanOrEqualTo(4.5));
    });

    test('gold never carries white type', () {
      // The whole reason BrandColors.onAccent exists. White on gold is about
      // 1.9:1 — if someone "simplifies" onAccent back to white, this fails.
      expect(contrast(Colors.white, BrandColors.accent), lessThan(3.0));
      expect(contrast(BrandColors.onAccent, BrandColors.accent),
          greaterThanOrEqualTo(4.5));
      expect(contrast(BrandColors.onAccent, BrandColors.accentContainer),
          greaterThanOrEqualTo(4.5));
    });

    test('containers carry their on-colour', () {
      expect(contrast(BrandColors.primaryDark, BrandColors.primaryContainer),
          greaterThanOrEqualTo(4.5));
      expect(
          contrast(
              BrandColors.primaryContainer, BrandColors.primaryContainerDark),
          greaterThanOrEqualTo(4.5));
    });

    test('dark-theme primary works as both fill and ink', () {
      // Used as the dark scheme's primary, so it must read on the dark
      // surface; and onPrimary is dark ink, which must read on top of it.
      expect(contrast(BrandColors.primaryLight, BrandColors.surfaceDark),
          greaterThanOrEqualTo(4.5));
      expect(contrast(BrandColors.ink, BrandColors.primaryLight),
          greaterThanOrEqualTo(4.5));
    });

    test('the escalation flame meets non-text contrast on both cards', () {
      // 3:1 is the WCAG floor for meaningful icons.
      expect(contrast(BrandColors.warning, BrandColors.cardLight),
          greaterThanOrEqualTo(3.0));
      expect(contrast(BrandColors.warning, BrandColors.cardDark),
          greaterThanOrEqualTo(3.0));
    });
  });

  group('built themes agree with the tokens', () {
    test('scheme on-colours are readable against their fills', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final s = theme.colorScheme;
        expect(contrast(s.onPrimary, s.primary), greaterThanOrEqualTo(4.5),
            reason: 'onPrimary on primary (${theme.brightness})');
        expect(contrast(s.onSecondary, s.secondary), greaterThanOrEqualTo(4.5),
            reason: 'onSecondary on secondary (${theme.brightness})');
        expect(contrast(s.onSurface, s.surface), greaterThanOrEqualTo(4.5),
            reason: 'onSurface on surface (${theme.brightness})');
        expect(contrast(s.onPrimaryContainer, s.primaryContainer),
            greaterThanOrEqualTo(4.5),
            reason: 'onPrimaryContainer (${theme.brightness})');
        expect(contrast(s.onSecondaryContainer, s.secondaryContainer),
            greaterThanOrEqualTo(4.5),
            reason: 'onSecondaryContainer (${theme.brightness})');
        expect(contrast(s.onError, s.error), greaterThanOrEqualTo(4.5),
            reason: 'onError on error (${theme.brightness})');
      }
    });
  });
}
