import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

/// Abre a aba Minha conta no [HomeShell], fechando telas empilhadas (detalhe da unidade, etc.).
void openConnectPlanTab(BuildContext context) {
  context.read<AppState>().openPlanTab();
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.popUntil((route) => route.isFirst);
  }
}
