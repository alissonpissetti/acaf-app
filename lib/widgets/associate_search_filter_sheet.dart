import 'package:flutter/material.dart';

import '../data/facility_filter_catalog.dart';
import '../data/modality_catalog.dart';
import '../models/associate_search_filters.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Abre modal grande (busca + filtros).
Future<AssociateSearchFilters?> showAssociateSearchFilterSheet(
  BuildContext context, {
  required AssociateSearchFilters initial,
  AssociateFilterSheetFocus focus = AssociateFilterSheetFocus.search,
}) {
  return showModalBottomSheet<AssociateSearchFilters>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    enableDrag: false,
    isDismissible: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) {
      final size = MediaQuery.sizeOf(sheetContext);
      final viewBottom = MediaQuery.viewInsetsOf(sheetContext).bottom;
      final maxH = size.height * 0.88;
      final height = (maxH - viewBottom).clamp(320.0, maxH);

      return Padding(
        padding: EdgeInsets.only(bottom: viewBottom),
        child: SizedBox(
          width: size.width,
          height: height,
          child: Material(
            color: AppColors.surface,
            child: AssociateSearchFilterSheet(initial: initial, focus: focus),
          ),
        ),
      );
    },
  );
}

enum AssociateFilterSheetFocus { search, filters }

class AssociateSearchFilterSheet extends StatefulWidget {
  const AssociateSearchFilterSheet({
    super.key,
    required this.initial,
    this.focus = AssociateFilterSheetFocus.search,
  });

  final AssociateSearchFilters initial;
  final AssociateFilterSheetFocus focus;

  @override
  State<AssociateSearchFilterSheet> createState() => _AssociateSearchFilterSheetState();
}

class _AssociateSearchFilterSheetState extends State<AssociateSearchFilterSheet> {
  late final TextEditingController _queryController;
  late final ScrollController _scrollController;
  late Set<String> _modalities;
  late Set<String> _structure;
  late Set<String> _advantages;
  double? _minRating;
  String _modalitySearch = '';
  late final TextEditingController _modalitySearchController;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.initial.query);
    _modalitySearchController = TextEditingController();
    _modalities = Set<String>.from(widget.initial.modalities);
    _structure = Set<String>.from(widget.initial.structureKeys);
    _advantages = Set<String>.from(widget.initial.advantageKeys);
    _minRating = widget.initial.minRating;
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _modalitySearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  AssociateSearchFilters get _draft => AssociateSearchFilters(
        query: _queryController.text,
        modalities: _modalities,
        minRating: _minRating,
        structureKeys: _structure,
        advantageKeys: _advantages,
      );

  void _clearAll() {
    setState(() {
      _queryController.clear();
      _modalities.clear();
      _structure.clear();
      _advantages.clear();
      _minRating = null;
    });
  }

  void _apply() {
    Navigator.pop(context, _draft);
  }

  @override
  Widget build(BuildContext context) {
    final modalityOptions = allModalityOptions()
        .where((o) => modalityFilterMatchesQuery(o, _modalitySearch))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.sizeOf(context);
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : media.width;
        final height = constraints.maxHeight.isFinite ? constraints.maxHeight : media.height * 0.88;

        return SizedBox(
          width: width,
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Buscar e filtrar', style: AppTypography.sectionTitle),
                    ),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  children: [
                    Text('Busca', style: AppTypography.label),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _queryController,
                      autofocus: widget.focus == AssociateFilterSheetFocus.search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Busque por qualquer coisa',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),
                    _SectionTitle(title: 'Avaliação mínima'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _RatingChip(
                          label: 'Qualquer',
                          selected: _minRating == null,
                          onTap: () => setState(() => _minRating = null),
                        ),
                        for (final r in [4.0, 4.5, 4.7, 4.8])
                          _RatingChip(
                            label: '${r.toStringAsFixed(1)}+',
                            selected: _minRating == r,
                            onTap: () => setState(() => _minRating = r),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.section),
                    _SectionTitle(title: 'Modalidades'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _modalitySearchController,
                      onChanged: (v) => setState(() => _modalitySearch = v),
                      decoration: const InputDecoration(
                        hintText: 'Filtrar lista de modalidades',
                        isDense: true,
                        prefixIcon: Icon(Icons.search_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...modalityOptions.map(
                      (key) => CheckboxListTile(
                        value: _modalities.contains(key),
                        onChanged: (_) {
                          setState(() {
                            if (_modalities.contains(key)) {
                              _modalities.remove(key);
                            } else {
                              _modalities.add(key);
                            }
                          });
                        },
                        title: Text(
                          modalityFilterLabel(key),
                          style: AppTypography.body.copyWith(fontSize: 14),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        activeColor: AppColors.orange,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),
                    _SectionTitle(title: 'Estrutura'),
                    const SizedBox(height: 4),
                    Text(
                      'Infraestrutura da unidade',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 10),
                    _FilterChipGroup(
                      options: FacilityFilterCatalog.structureOptions,
                      selected: _structure,
                      onChanged: (next) => setState(() => _structure = next),
                    ),
                    const SizedBox(height: AppSpacing.section),
                    _SectionTitle(title: 'Vantagens'),
                    const SizedBox(height: 4),
                    Text(
                      'Serviços e benefícios',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 10),
                    _FilterChipGroup(
                      options: FacilityFilterCatalog.advantageOptions,
                      selected: _advantages,
                      onChanged: (next) => setState(() => _advantages = next),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 12 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(onPressed: _clearAll, child: const Text('Limpar tudo')),
                    ),
                    FilledButton(
                      onPressed: _apply,
                      child: Text(
                        _draft.isEmpty ? 'Aplicar' : 'Aplicar (${_draft.activeCount})',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTypography.sectionTitle.copyWith(fontSize: 16));
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != 'Qualquer') ...[
            const Icon(Icons.star_rounded, size: 14, color: AppColors.orange),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.orangeSoft,
      checkmarkColor: AppColors.orange,
      side: BorderSide(color: selected ? AppColors.orange : AppColors.border),
      labelStyle: AppTypography.caption.copyWith(
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: selected ? AppColors.orangeDark : AppColors.foreground,
      ),
    );
  }
}

class _FilterChipGroup extends StatelessWidget {
  const _FilterChipGroup({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<FacilityFilterOption> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isOn = selected.contains(opt.key);
        return FilterChip(
          label: Text(opt.label),
          selected: isOn,
          onSelected: (_) {
            final next = Set<String>.from(selected);
            if (isOn) {
              next.remove(opt.key);
            } else {
              next.add(opt.key);
            }
            onChanged(next);
          },
          selectedColor: AppColors.orangeSoft,
          checkmarkColor: AppColors.orange,
          side: BorderSide(color: isOn ? AppColors.orange : AppColors.border),
          labelStyle: AppTypography.caption.copyWith(
            fontWeight: isOn ? FontWeight.w600 : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }
}

/// Resumo na home: busca + filtros abrem o mesmo modal.
class HomeSearchFilterBar extends StatelessWidget {
  const HomeSearchFilterBar({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  static const _barHeight = 48.0;

  final AssociateSearchFilters filters;
  final ValueChanged<AssociateSearchFilters> onFiltersChanged;

  Future<void> _open(BuildContext context, {AssociateFilterSheetFocus focus = AssociateFilterSheetFocus.search}) async {
    final result = await showAssociateSearchFilterSheet(
      context,
      initial: filters,
      focus: focus,
    );
    if (!context.mounted) return;
    if (result != null) {
      onFiltersChanged(result);
    }
  }

  String get _searchSummary {
    if (filters.query.trim().isNotEmpty) return filters.query.trim();
    return 'Buscar academia ou modalidade';
  }

  int get _nonQueryFilterCount {
    var n = filters.activeCount;
    if (filters.query.trim().isNotEmpty) n -= 1;
    return n < 0 ? 0 : n;
  }

  @override
  Widget build(BuildContext context) {
    final hasFilters = _nonQueryFilterCount > 0;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: _barHeight,
            child: Material(
              color: AppColors.surfaceMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _open(context, focus: AssociateFilterSheetFocus.search),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: filters.query.isNotEmpty ? AppColors.orange : AppColors.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _searchSummary,
                          style: AppTypography.body.copyWith(
                            fontSize: 15,
                            color: filters.query.isNotEmpty ? AppColors.foreground : AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: _barHeight,
          height: _barHeight,
          child: Material(
            color: hasFilters ? AppColors.orangeSoft : AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: hasFilters ? AppColors.orange : AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _open(context, focus: AssociateFilterSheetFocus.filters),
              borderRadius: BorderRadius.circular(14),
              child: Tooltip(
                message: 'Filtros avançados',
                child: Center(
                  child: Icon(
                    Icons.tune_rounded,
                    size: 22,
                    color: hasFilters ? AppColors.orange : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
