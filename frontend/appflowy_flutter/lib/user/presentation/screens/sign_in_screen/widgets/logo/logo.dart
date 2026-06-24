import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flutter/material.dart';

class AFLogo extends StatelessWidget {
  const AFLogo({
    super.key,
    this.size = const Size.square(36),
  });

  final Size size;

  @override
  Widget build(BuildContext context) {
    // OSN: logo monocromo che segue il tema (bianco su dark, nero su light),
    // coerente con l'icona app B/N. Niente blendMode:null = applica il tint.
    return FlowySvg(
      FlowySvgs.app_logo_xl,
      color: Theme.of(context).colorScheme.onSurface,
      size: size,
    );
  }
}
