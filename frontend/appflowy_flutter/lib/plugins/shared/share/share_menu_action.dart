import 'package:appflowy/features/share_tab/data/models/share_popover_group_id.dart';
import 'package:appflowy/features/share_tab/data/repositories/rust_share_with_user_repository_impl.dart';
import 'package:appflowy/features/share_tab/logic/share_tab_bloc.dart';
import 'package:appflowy/features/workspace/logic/workspace_bloc.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/tab_bar_bloc.dart';
import 'package:appflowy/plugins/shared/share/share_bloc.dart';
import 'package:appflowy/plugins/shared/share/share_menu.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

/// OSN: voce "Condividi" da inserire nel menu "..." (MoreViewActions).
///
/// L'header originale aveva un pulsante Share dedicato; qui lo spostiamo nel
/// menu. Il menu è un overlay che non eredita i BLoC dell'header, perciò lo
/// ShareMenu viene aperto in un dialog con i BLoC forniti esplicitamente
/// (stessi di ShareButton/ShareMenuButton).
class ShareMenuAction extends StatelessWidget {
  const ShareMenuAction({super.key, required this.view});

  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      leftIcon: const FlowySvg(FlowySvgs.share_s),
      leftIconSize: const Size.square(18),
      text: FlowyText.regular(LocaleKeys.shareAction_buttonText.tr()),
      onTap: () => _openShareDialog(context),
    );
  }

  void _openShareDialog(BuildContext context) {
    final workspaceBloc = context.read<UserWorkspaceBloc>();
    final workspaceId = workspaceBloc.state.currentWorkspace?.workspaceId ?? '';
    final workspaceType = workspaceBloc.state.currentWorkspace?.workspaceType;

    showDialog(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                getIt<ShareBloc>(param1: view)..add(const ShareEvent.initial()),
          ),
          if (view.layout.isDatabaseView)
            BlocProvider(
              create: (_) => DatabaseTabBarBloc(
                view: view,
                compactModeId: view.id,
                enableCompactMode: false,
              )..add(const DatabaseTabBarEvent.initial()),
            ),
          BlocProvider(
            create: (_) {
              final bloc = ShareTabBloc(
                repository: RustShareWithUserRepositoryImpl(),
                pageId: view.id,
                workspaceId: workspaceId,
              );
              if (workspaceType != WorkspaceTypePB.LocalW) {
                bloc.add(ShareTabEvent.initialize());
              }
              return bloc;
            },
          ),
          BlocProvider.value(value: workspaceBloc),
        ],
        child: Provider.value(
          value: SharePopoverGroupId(),
          child: BlocBuilder<ShareBloc, ShareState>(
            builder: (context, state) {
              final tabs = [
                if (state.enablePublish) ...[
                  ShareMenuTab.share,
                  ShareMenuTab.publish,
                ],
                ShareMenuTab.exportAs,
              ];
              return Dialog(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: ShareMenu(
                    tabs: tabs,
                    viewName: state.viewName,
                    onClose: () => Navigator.of(context).pop(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
