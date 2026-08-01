import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_search_areas.dart';
import '../state/location_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

Future<void> showLocationPickerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _LocationPickerSheet(),
  );
}

class _LocationPickerSheet extends StatelessWidget {
  const _LocationPickerSheet();

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationState>();
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.pageX, 12, AppSpacing.pageX, 12 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Onde buscar unidades?', style: AppTypography.sectionTitle),
          const SizedBox(height: 4),
          Text(
            'Por padrão usamos sua localização atual. Você também pode escolher outra cidade.',
            style: AppTypography.bodyMuted,
          ),
          const SizedBox(height: AppSpacing.block),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.my_location_rounded,
              color: location.usingCurrentLocation ? AppColors.orange : AppColors.textMuted,
            ),
            title: Text('Minha localização atual', style: AppTypography.cardTitle.copyWith(fontSize: 15)),
            subtitle: Text(
              location.currentLocationLabel,
              style: AppTypography.caption,
            ),
            trailing: location.usingCurrentLocation
                ? const Icon(Icons.check_rounded, color: AppColors.orange)
                : null,
            onTap: () async {
              await location.useCurrentLocation();
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const Divider(height: 24),
          Text('Outras regiões', style: AppTypography.label),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.42,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: mockSearchAreas.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final area = mockSearchAreas[index];
                final selected = !location.usingCurrentLocation && location.manualArea?.id == area.id;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(area.label, style: AppTypography.body.copyWith(fontSize: 15)),
                  trailing: selected ? const Icon(Icons.check_rounded, color: AppColors.orange) : null,
                  onTap: () {
                    location.selectArea(area);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
