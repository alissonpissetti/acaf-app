import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/associates_repository.dart';
import '../state/catalog_state.dart';
import '../models/associate_search_filters.dart';
import '../models/gym.dart';
import '../state/app_state.dart';
import '../state/location_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/connect_bottom_nav.dart';
import '../widgets/gym_card.dart';
import '../widgets/gym_card_skeleton.dart';
import '../widgets/home_quick_actions_panel.dart';
import '../widgets/movly_discover_card.dart';
import '../widgets/movly_empty_state.dart';
import '../widgets/movly_home_header.dart';
import '../widgets/section_header.dart';
import 'financial_screen.dart';
import 'gym_network_screen.dart';
import 'member_check_in_screen.dart';
import 'user_account_screen.dart';

/// Tela inicial: associados ordenados por distância.
class HomeAssociatesScreen extends StatefulWidget {
  const HomeAssociatesScreen({super.key});

  @override
  State<HomeAssociatesScreen> createState() => _HomeAssociatesScreenState();
}

class _HomeAssociatesScreenState extends State<HomeAssociatesScreen> {
  final _scrollController = ScrollController();
  AssociatesRepository? _repository;
  AssociateSearchFilters _filters = AssociateSearchFilters.empty;
  int _visibleCount = AssociatesRepository.homePageSize;
  bool _loadingMore = false;
  String? _listCityFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollNearEnd);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollNearEnd);
    _scrollController.dispose();
    super.dispose();
  }

  void _resetPagination() {
    _visibleCount = AssociatesRepository.homePageSize;
    _loadingMore = false;
  }

  void _onScrollNearEnd() {
    if (!_scrollController.hasClients || _loadingMore) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;
    if (position.pixels < position.maxScrollExtent - 400) return;
    _loadMoreAssociates();
  }

  Future<void> _loadMoreAssociates() async {
    final location = context.read<LocationState>();
    final total = _associates(location).length;
    if (_visibleCount >= total) return;

    setState(() => _loadingMore = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() {
      final next = _visibleCount + AssociatesRepository.homePageSize;
      _visibleCount = next > total ? total : next;
      _loadingMore = false;
    });
  }

  Future<void> _onRefresh() async {
    final location = context.read<LocationState>();
    if (location.usingCurrentLocation) {
      await location.useCurrentLocation();
    } else {
      location.refreshDistancesFromCache();
    }
    setState(_resetPagination);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repository ??= AssociatesRepository(context.read<CatalogState>());
  }

  List<Gym> _associates(LocationState location) =>
      _repository!.searchWithFilters(
        filters: _filters,
        cityFilter: location.listCityFilter,
      );

  void _openNetwork(Gym unit) {
    final network = _repository!.networkForUnit(unit);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GymNetworkScreen(network: network, initialUnit: unit),
      ),
    );
  }

  bool get _hasActiveFilters => !_filters.isEmpty;

  void _clearAllFilters() {
    setState(() {
      _filters = AssociateSearchFilters.empty;
      _resetPagination();
    });
  }

  Gym? _primaryGym(AppState appState) {
    final gymId = appState.primaryGymId;
    if (gymId != null) {
      return _repository!.gymById(gymId);
    }
    return null;
  }

  void _openCheckIn(AppState appState) {
    final gym = _primaryGym(appState);
    if (gym == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escolha sua academia principal em uma unidade do Guia.'),
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
    final location = context.watch<LocationState>();
    final appState = context.watch<AppState>();
    final allAssociates = _associates(location);
    if (_listCityFilter != location.listCityFilter) {
      _listCityFilter = location.listCityFilter;
      _resetPagination();
    }
    final associates = allAssociates.take(_visibleCount).toList();
    final hasMore = _visibleCount < allAssociates.length;
    final isMember = appState.activeConnectSubscription != null;
    final primaryGym = _primaryGym(appState);

    final listTitle = location.loading
        ? 'Buscando unidades…'
        : allAssociates.isEmpty
            ? 'Nenhum resultado'
            : '${allAssociates.length} unidades perto de você';

    return RefreshIndicator(
      color: AppColors.onLime,
      onRefresh: _onRefresh,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: ConnectBottomNav.scrollBottomPadding(context)),
        children: [
          const MovlyHomeHeader(),
          Transform.translate(
            offset: const Offset(0, -18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
              child: MovlyDiscoverCard(
                filters: _filters,
                onFiltersChanged: (value) => setState(() {
                  _filters = value;
                  _resetPagination();
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (isMember) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
              child: HomeQuickActionsPanel(
                homeGymName: primaryGym?.name ?? appState.primaryGymName,
                actions: [
                  HomeQuickAction(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Check-in',
                    onTap: () => _openCheckIn(appState),
                  ),
                  HomeQuickAction(
                    icon: Icons.wallet_outlined,
                    label: 'Plano',
                    onTap: () => appState.openPlanTab(),
                  ),
                  HomeQuickAction(
                    icon: Icons.person_outline_rounded,
                    label: 'Perfil',
                    onTap: () => UserAccountScreen.open(context),
                  ),
                  HomeQuickAction(
                    icon: Icons.receipt_long_outlined,
                    label: 'Financeiro',
                    onTap: () => FinancialScreen.open(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.section),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
            child: SectionHeader(
              title: listTitle,
              subtitle: location.loading ? null : 'Ordenadas pela distância da sua região',
              actionLabel: _hasActiveFilters ? 'Limpar filtros' : null,
              onAction: _hasActiveFilters ? _clearAllFilters : null,
            ),
          ),
          if (!location.loading && allAssociates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
              child: MovlyEmptyState(
                title: 'Nada por aqui ainda',
                message: 'Tente outra cidade ou remova alguns filtros para ver academias disponíveis.',
                actionLabel: _hasActiveFilters ? 'Limpar filtros' : 'Trocar região',
                onAction: _hasActiveFilters
                    ? _clearAllFilters
                    : () => _onRefresh(),
              ),
            )
          else if (location.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onLime),
              ),
            )
          else
            ...associates.asMap().entries.map(
              (entry) {
                final associate = entry.value;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageX,
                    0,
                    AppSpacing.pageX,
                    AppSpacing.block,
                  ),
                  child: GymCard(
                    gym: associate,
                    network: _repository!.networkForUnit(associate),
                    distanceRank: entry.key + 1,
                    cardContext: GymCardContext.homeUnitIndex,
                    networkUnitCount: _repository!.networkUnitCount(associate.networkId),
                    onTap: () => _openNetwork(associate),
                  ),
                );
              },
            ),
          if (_loadingMore && hasMore)
            const Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.pageX, 0, AppSpacing.pageX, AppSpacing.block),
              child: GymCardSkeleton(),
            ),
        ],
      ),
    );
  }
}
