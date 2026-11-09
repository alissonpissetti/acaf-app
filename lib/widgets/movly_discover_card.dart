import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/associate_search_filters.dart';
import '../state/location_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'associate_search_filter_sheet.dart';
import 'connect_location_field.dart';
import 'location_picker_sheet.dart';

/// Cartão de descoberta: local + busca/filtros (sobre o gradiente da home).
class MovlyDiscoverCard extends StatelessWidget {
  const MovlyDiscoverCard({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  final AssociateSearchFilters filters;
  final ValueChanged<AssociateSearchFilters> onFiltersChanged;

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationState>();

    return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.onLime.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Onde você quer treinar?',
              style: AppTypography.sectionTitle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12),
            ConnectLocationField(
              label: location.areaLabel,
              loading: location.loading,
              onTap: () => showLocationPickerSheet(context),
              onUseCurrentLocation: location.loading ? null : () => location.useCurrentLocation(),
            ),
            const SizedBox(height: 10),
            HomeSearchFilterBar(
              filters: filters,
              onFiltersChanged: onFiltersChanged,
            ),
          ],
        ),
    );
  }
}
