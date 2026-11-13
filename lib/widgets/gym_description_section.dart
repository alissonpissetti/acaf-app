import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Descrição da unidade no portal parceiro (`GymUnit.description`).
class GymDescriptionSection extends StatefulWidget {
  const GymDescriptionSection({
    super.key,
    required this.description,
    this.title = 'Descrição',
    this.compact = false,
    this.showEmptyPlaceholder = false,
  });

  final String? description;
  final String title;
  final bool compact;
  final bool showEmptyPlaceholder;

  @override
  State<GymDescriptionSection> createState() => _GymDescriptionSectionState();
}

class _GymDescriptionSectionState extends State<GymDescriptionSection> {
  static const _collapsedMaxLines = 4;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.description?.trim();
    final hasText = text != null && text.isNotEmpty;

    if (!hasText && !widget.showEmptyPlaceholder) {
      return const SizedBox.shrink();
    }

    final titleStyle = widget.compact ? AppTypography.label : AppTypography.sectionTitle;
    final bodyStyle = widget.compact
        ? AppTypography.bodyMuted.copyWith(height: 1.45)
        : AppTypography.body.copyWith(height: 1.5, color: AppColors.foreground);

    final bodyText = hasText ? text : 'Sem descrição';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: titleStyle),
        const SizedBox(height: AppSpacing.tight),
        Text(
          bodyText,
          style: hasText
              ? bodyStyle
              : bodyStyle.copyWith(color: AppColors.textMuted, fontStyle: FontStyle.italic),
          maxLines: hasText && !_expanded ? _collapsedMaxLines : null,
          overflow: hasText && !_expanded ? TextOverflow.ellipsis : null,
        ),
        if (hasText && _needsExpandToggle(context, text, bodyStyle)) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _expanded ? 'Ver menos' : 'Ver mais',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool _needsExpandToggle(BuildContext context, String text, TextStyle style) {
    if (_expanded) return true;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: _collapsedMaxLines,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: MediaQuery.sizeOf(context).width - (AppSpacing.pageX * 2) - 32);
    return painter.didExceedMaxLines;
  }
}
