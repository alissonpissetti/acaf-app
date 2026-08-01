import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/associates_repository.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../screens/member_check_in_screen.dart';

/// Barra inferior: Guia · Check-in (centro, se assinatura) · Minha conta.
class ConnectBottomNav extends StatelessWidget {
  const ConnectBottomNav({super.key});

  static final _repository = AssociatesRepository();

  static const _barHeight = 64.0;
  static const _fabLift = 26.0;
  static const _fabSize = 56.0;
  static const _centerLabelGap = 6.0;
  /// Desloca ícones e rótulos para baixo dentro da barra.
  static const _navContentDrop = 8.0;
  /// Mesma altura da coluna central (FAB + gap + rótulo) para alinhar textos.
  static const _navColumnHeight = _fabSize + _centerLabelGap + 14;

  void _openCheckIn(BuildContext context) {
    final appState = context.read<AppState>();
    final primaryId = appState.primaryGymId;
    if (primaryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escolha sua academia principal em uma unidade do Guia.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final gym = _repository.gymById(primaryId);
    if (gym == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unidade principal não encontrada.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final planName = appState.activeConnectSubscription?.planName;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemberCheckInScreen(gym: gym, planName: planName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = context.select<AppState, int>((s) => s.homeTabIndex);
    final hasUnitPlan = context.select<AppState, bool>((s) => s.canUseMemberCheckIn);

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    if (!hasUnitPlan) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: ColoredBox(
          color: AppColors.orange,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Theme(
                data: Theme.of(context).copyWith(
                  navigationBarTheme: NavigationBarThemeData(
                    backgroundColor: AppColors.orange,
                    indicatorColor: Colors.white.withValues(alpha: 0.22),
                    elevation: 0,
                    height: 56,
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      final selected = states.contains(WidgetState.selected);
                      return TextStyle(
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        height: 1.1,
                        color: Colors.white.withValues(alpha: selected ? 1 : 0.88),
                      );
                    }),
                    iconTheme: WidgetStateProperty.resolveWith((states) {
                      final selected = states.contains(WidgetState.selected);
                      return IconThemeData(
                        size: 22,
                        color: Colors.white.withValues(alpha: selected ? 1 : 0.88),
                      );
                    }),
                  ),
                ),
                child: NavigationBar(
                  elevation: 0,
                  backgroundColor: AppColors.orange,
                  surfaceTintColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  selectedIndex: index,
                  onDestinationSelected: (i) {
                    final state = context.read<AppState>();
                    if (i == 0) {
                      state.openGuideTab();
                    } else {
                      state.openPlanTab();
                    }
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.explore_outlined),
                      selectedIcon: Icon(Icons.explore_rounded),
                      label: 'Guia',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.wallet_outlined),
                      selectedIcon: Icon(Icons.wallet_rounded),
                      label: 'Minha conta',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: _fabLift + _barHeight + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _barHeight + bottomInset,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              child: ColoredBox(
                color: AppColors.orange,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: bottomInset,
                    left: 4,
                    right: 4,
                  ),
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Positioned(
            left: 4,
            right: 4,
            top: _navContentDrop,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _SideNavItem(
                    label: 'Guia',
                    icon: Icons.explore_outlined,
                    selectedIcon: Icons.explore_rounded,
                    selected: index == 0,
                    alignWithCenterCheckIn: true,
                    onTap: () => context.read<AppState>().openGuideTab(),
                  ),
                ),
                const SizedBox(width: _fabSize + 12),
                Expanded(
                  child: _SideNavItem(
                    label: 'Minha conta',
                    icon: Icons.wallet_outlined,
                    selectedIcon: Icons.wallet_rounded,
                    selected: index == 1,
                    alignWithCenterCheckIn: true,
                    onTap: () => context.read<AppState>().openPlanTab(),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: _navContentDrop,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CenterCheckInButton(onTap: () => _openCheckIn(context)),
                const SizedBox(height: ConnectBottomNav._centerLabelGap),
                Text(
                  'Check-in',
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Barra compacta (sem check-in central).
  static const compactShellHeight = 64.0;

  /// Espaço no fim do scroll para não ficar sob a barra laranja ([HomeShell]).
  /// Não inclui [_fabLift]: o botão flutuante fica acima da faixa laranja.
  static double scrollBottomPadding(BuildContext context, {double extra = 8}) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final hasCheckIn = context.select<AppState, bool>((s) => s.activeGymSubscription != null);
    final bar = hasCheckIn ? _barHeight : compactShellHeight;
    return bar + bottomSafe + extra;
  }

  static EdgeInsets listPadding(
    BuildContext context, {
    double horizontal = AppSpacing.pageX,
    double top = 0,
    double extraBottom = 8,
  }) {
    return EdgeInsets.fromLTRB(
      horizontal,
      top,
      horizontal,
      scrollBottomPadding(context, extra: extraBottom),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  const _SideNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
    this.alignWithCenterCheckIn = false,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;
  final bool alignWithCenterCheckIn;

  @override
  Widget build(BuildContext context) {
    final labelGap = alignWithCenterCheckIn ? 2.0 : 4.0;
    final verticalPadding = alignWithCenterCheckIn ? 0.0 : 6.0;

    final iconBlock = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? Colors.white.withValues(alpha: 0.22) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        selected ? selectedIcon : icon,
        size: 22,
        color: Colors.white.withValues(alpha: selected ? 1 : 0.88),
      ),
    );

    final labelWidget = Text(
      label,
      style: AppTypography.caption.copyWith(
        fontSize: 11,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: Colors.white.withValues(alpha: selected ? 1 : 0.88),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          child: alignWithCenterCheckIn
              ? SizedBox(
                  height: ConnectBottomNav._navColumnHeight,
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      iconBlock,
                      SizedBox(height: labelGap),
                      labelWidget,
                    ],
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    iconBlock,
                    SizedBox(height: labelGap),
                    labelWidget,
                  ],
                ),
        ),
      ),
    );
  }
}

class _CenterCheckInButton extends StatelessWidget {
  const _CenterCheckInButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black26,
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.orange, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(
          side: BorderSide(color: AppColors.orange, width: 2),
        ),
        child: const SizedBox(
          width: ConnectBottomNav._fabSize,
          height: ConnectBottomNav._fabSize,
          child: Center(
            child: Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.orange,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
