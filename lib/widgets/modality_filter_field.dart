import 'package:flutter/material.dart';

import '../data/modality_catalog.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Campo compacto + bottom sheet para muitas modalidades.
class ModalityFilterField extends StatelessWidget {
  const ModalityFilterField({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  Future<void> _openSheet(BuildContext context) async {
    final result = await showModalityFilterSheet(
      context,
      initialSelection: selected,
    );
    if (result != null) {
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Modalidades', style: AppTypography.label),
        const SizedBox(height: AppSpacing.tight),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _openSheet(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected.isEmpty ? AppColors.border : AppColors.orange,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    size: 20,
                    color: selected.isEmpty ? AppColors.textMuted : AppColors.orange,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selected.isEmpty
                          ? 'Todas as modalidades'
                          : '${selected.length} modalidade${selected.length == 1 ? '' : 's'} selecionada${selected.length == 1 ? '' : 's'}',
                      style: AppTypography.body.copyWith(fontSize: 13),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 22),
                ],
              ),
            ),
          ),
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...selected.take(4).map(
                    (key) => InputChip(
                      label: Text(modalityFilterLabel(key), style: AppTypography.caption),
                      onDeleted: () {
                        final next = Set<String>.from(selected)..remove(key);
                        onChanged(next);
                      },
                      deleteIconColor: AppColors.orange,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              if (selected.length > 4)
                Chip(
                  label: Text('+${selected.length - 4}', style: AppTypography.caption),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Bottom sheet com busca e seleção múltipla.
Future<Set<String>?> showModalityFilterSheet(
  BuildContext context, {
  required Set<String> initialSelection,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _ModalityFilterSheet(initialSelection: initialSelection),
  );
}

class _ModalityFilterSheet extends StatefulWidget {
  const _ModalityFilterSheet({required this.initialSelection});

  final Set<String> initialSelection;

  @override
  State<_ModalityFilterSheet> createState() => _ModalityFilterSheetState();
}

class _ModalityFilterSheetState extends State<_ModalityFilterSheet> {
  late final Set<String> _draft = Set<String>.from(widget.initialSelection);
  final _searchController = TextEditingController();
  String _search = '';

  List<String> get _allOptions => allModalityOptions();

  List<String> get _visibleOptions =>
      _allOptions.where((o) => modalityFilterMatchesQuery(o, _search)).toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggle(String key) {
    setState(() {
      if (_draft.contains(key)) {
        _draft.remove(key);
      } else {
        _draft.add(key);
      }
    });
  }

  void _selectAllVisible() {
    setState(() => _draft.addAll(_visibleOptions));
  }

  void _clearAll() {
    setState(_draft.clear);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Filtrar modalidades', style: AppTypography.sectionTitle),
                    ),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _search = v),
                  decoration: const InputDecoration(
                    hintText: 'Buscar modalidade',
                    prefixIcon: Icon(Icons.search_rounded, size: 22),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    TextButton(onPressed: _selectAllVisible, child: const Text('Marcar visíveis')),
                    TextButton(onPressed: _clearAll, child: const Text('Limpar')),
                    const Spacer(),
                    Text(
                      '${_draft.length} selecionada${_draft.length == 1 ? '' : 's'}',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: _visibleOptions.length,
                  itemBuilder: (context, index) {
                    final key = _visibleOptions[index];
                    final checked = _draft.contains(key);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (_) => _toggle(key),
                      title: Text(modalityFilterLabel(key), style: AppTypography.body.copyWith(fontSize: 14)),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      activeColor: AppColors.orange,
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _draft),
                    child: Text(
                      _draft.isEmpty ? 'Aplicar sem filtro' : 'Aplicar (${_draft.length})',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
