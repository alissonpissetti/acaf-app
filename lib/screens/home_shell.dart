import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/connect_bottom_nav.dart';
import 'gym_guide_screen.dart';
import 'my_plan_screen.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final guest = context.select<AppState, bool>((s) => s.isGuestGuideMode);
    final index = context.select<AppState, int>((s) => s.homeTabIndex);
    final tabIndex = guest ? 0 : index;

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      extendBody: false,
      resizeToAvoidBottomInset: true,
      body: guest
          ? const HomeAssociatesScreen()
          : IndexedStack(
              index: tabIndex,
              children: [
                HomeAssociatesScreen(),
                MyPlanScreen(),
              ],
            ),
      bottomNavigationBar: const ConnectBottomNav(),
    );
  }
}
