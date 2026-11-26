import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The official GAT logo, in the three shapes the app actually needs.
///
/// The supplied artwork sets the wordmark in black, so a dark-theme twin with
/// white type ships alongside each lock-up and is chosen from the ambient
/// [Brightness]. The emblem is a single circular mark that reads on anything
/// light, so it has no twin.
enum GatLogoStyle {
  /// Globe only. For tight spots and for sitting on a white chip.
  emblem,

  /// Globe + wordmark side by side. The default for headers.
  horizontal,

  /// Globe above the wordmark. For tall, centred layouts.
  stacked,
}

class GatLogo extends StatelessWidget {
  const GatLogo(
      {super.key,
      this.style = GatLogoStyle.horizontal,
      this.height,
      this.onLight});

  final GatLogoStyle style;
  final double? height;

  /// Forces the light-surface (black type) artwork. Leave null to follow the
  /// theme. Set it true when the logo sits on a white chip inside an otherwise
  /// dark screen, which the theme cannot infer.
  final bool? onLight;

  @override
  Widget build(BuildContext context) {
    final light =
        onLight ?? Theme.of(context).brightness == Brightness.light;
    final asset = switch (style) {
      GatLogoStyle.emblem => 'assets/brand/gat_emblem.png',
      GatLogoStyle.horizontal => light
          ? 'assets/brand/gat_logo_horizontal.png'
          : 'assets/brand/gat_logo_horizontal_light.png',
      GatLogoStyle.stacked => light
          ? 'assets/brand/gat_logo_stacked.png'
          : 'assets/brand/gat_logo_stacked_light.png',
    };
    return Image.asset(
      asset,
      height: height,
      fit: BoxFit.contain,
      // The logo is decorative wherever it appears; every screen that uses it
      // also names the institution or the app in adjacent text.
      excludeFromSemantics: true,
    );
  }
}

/// The emblem on a white disc — the only safe way to put the globe on a
/// primary-coloured surface, where its navy ocean would otherwise blend into
/// the brand indigo and leave the gold continents floating.
class GatEmblemChip extends StatelessWidget {
  const GatEmblemChip({super.key, this.size = 104});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.5),
        boxShadow: Elevations.floating(Brightness.light),
      ),
      child: const GatLogo(style: GatLogoStyle.emblem, onLight: true),
    );
  }
}
