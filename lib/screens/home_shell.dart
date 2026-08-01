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
    final index = context.select<AppState, int>((s) => s.homeTabIndex);

    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBody: true,
      body: IndexedStack(
        index: index,
        children: [
          HomeAssociatesScreen(),
          MyPlanScreen(),
        ],
      ),
      bottomNavigationBar: const ConnectBottomNav(),
    );
  }
}
