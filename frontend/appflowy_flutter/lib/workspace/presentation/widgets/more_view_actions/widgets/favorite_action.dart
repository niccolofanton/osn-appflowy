import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Menu item ("⋯" > MoreViewActions) per aggiungere/rimuovere la pagina dai
/// preferiti. Replica la stessa logica di [ViewFavoriteButton]
/// ([FavoriteBloc] + [FavoriteEvent.toggle]); l'icona e la label dipendono da
/// `isFavorite`.
class FavoriteAction extends StatelessWidget {
  const FavoriteAction({
    super.key,
    required this.view,
    this.mutex,
  });

  final ViewPB view;
  final PopoverMutex? mutex;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoriteBloc, FavoriteState>(
      builder: (context, state) {
        final isFavorite = state.views.any((v) => v.item.id == view.id);
        return Container(
          height: 34,
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: FlowyButton(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            onTap: () {
              context.read<FavoriteBloc>().add(FavoriteEvent.toggle(view));
              mutex?.close();
            },
            leftIcon: FlowySvg(
              isFavorite ? FlowySvgs.favorited_s : FlowySvgs.favorite_s,
              size: const Size.square(16.0),
              blendMode: isFavorite ? null : BlendMode.srcIn,
            ),
            iconPadding: 10.0,
            text: FlowyText(
              isFavorite
                  ? LocaleKeys.button_removeFromFavorites.tr()
                  : LocaleKeys.button_addToFavorites.tr(),
              figmaLineHeight: 18.0,
            ),
          ),
        );
      },
    );
  }
}
