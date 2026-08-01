import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/associate_search_filters.dart';
import '../state/location_state.dart';
import 'associate_search_filter_sheet.dart';
import 'connect_location_field.dart';
import 'location_picker_sheet.dart';

/// Localização + busca/filtros (modal).
class HomeLocationSearchBlock extends StatelessWidget {
  const HomeLocationSearchBlock({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  final AssociateSearchFilters filters;
  final ValueChanged<AssociateSearchFilters> onFiltersChanged;

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
    );
  }
}
