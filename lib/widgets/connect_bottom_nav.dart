import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/associates_repository.dart';
import '../state/catalog_state.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../screens/member_check_in_screen.dart';

/// Barra inferior — superfície neutra, seleção em roxo; limão só no indicador.
class ConnectBottomNav extends StatelessWidget {
  const ConnectBottomNav({super.key});

  /// Altura só dos ícones + labels (sem safe area).
  static const _contentHeight = 56.0;

  static double bottomSafe(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom;

  static bool _hasCenterCheckIn(BuildContext context) =>
      context.select<AppState, bool>((s) => s.canUseMemberCheckIn);

  static double totalHeight(BuildContext context) =>
      _contentHeight + bottomSafe(context);

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

    final repository = AssociatesRepository(context.read<CatalogState>());
    final gym = repository.gymById(primaryId);
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

  int _selectedNavIndex(int homeTabIndex, bool hasCheckIn) {
    if (!hasCheckIn) return homeTabIndex;
    return homeTabIndex == 0 ? 0 : 2;
  }

  @override
  Widget build(BuildContext context) {
    final homeTabIndex = context.select<AppState, int>((s) => s.homeTabIndex);
    final hasCheckIn = _hasCenterCheckIn(context);
    final selectedIndex = _selectedNavIndex(homeTabIndex, hasCheckIn);

    final navTheme = NavigationBarThemeData(
      height: _contentHeight,
      backgroundColor: Colors.transparent,
      indicatorColor: AppColors.limeSoft,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          height: 1,
          color: selected ? AppColors.primary : AppColors.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 22,
          color: selected ? AppColors.primary : AppColors.textMuted,
        );
      }),
    );

    // NavigationBar já inclui SafeArea inferior — não somar padding manual (empurrava ícones).
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(navigationBarTheme: navTheme),
        child: NavigationBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        selectedIndex: selectedIndex,
            onDestinationSelected: (i) {
              final state = context.read<AppState>();
              if (hasCheckIn) {
                if (i == 1) {
                  _openCheckIn(context);
                  return;
                }
                if (i == 0) {
                  state.openGuideTab();
                } else {
                  state.openPlanTab();
                }
                return;
              }
              if (i == 0) {
                state.openGuideTab();
              } else {
                state.openPlanTab();
              }
            },
            destinations: hasCheckIn
                ? const [
                    NavigationDestination(
                      icon: Icon(Icons.explore_outlined),
                      selectedIcon: Icon(Icons.explore_rounded),
                      label: 'Explorar',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.qr_code_scanner_outlined),
                      selectedIcon: Icon(Icons.qr_code_scanner_rounded),
                      label: 'Check-in',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.account_circle_outlined),
                      selectedIcon: Icon(Icons.account_circle_rounded),
                      label: 'Conta',
                    ),
                  ]
                : const [
                    NavigationDestination(
                      icon: Icon(Icons.explore_outlined),
                      selectedIcon: Icon(Icons.explore_rounded),
                      label: 'Explorar',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.account_circle_outlined),
                      selectedIcon: Icon(Icons.account_circle_rounded),
                      label: 'Conta',
                    ),
                  ],
        ),
      ),
    );
  }

  static double scrollBottomPadding(BuildContext context, {double extra = 8}) {
    return totalHeight(context) + extra;
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
