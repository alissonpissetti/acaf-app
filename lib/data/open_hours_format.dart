/// Agrupa dias consecutivos com o mesmo horário para exibição compacta.
class OpenHoursRow {
  const OpenHoursRow({required this.daysLabel, required this.rangeLabel});

  final String daysLabel;
  final String rangeLabel;
}

const _weekdayOrder = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

const _weekdayLabels = {
  'mon': 'segunda-feira',
  'tue': 'terça-feira',
  'wed': 'quarta-feira',
  'thu': 'quinta-feira',
  'fri': 'sexta-feira',
  'sat': 'sábado',
  'sun': 'domingo',
};

String _dayLabelShort(String day) {
  final short = _weekdayLabels[day] ?? day;
  final slice = short.length >= 3 ? short.substring(0, 3) : short;
  return slice[0].toUpperCase() + slice.substring(1);
}

String _dayLabelRange(String start, String end) {
  if (start == end) return _dayLabelShort(start);
  return '${_dayLabelShort(start)}–${_dayLabelShort(end)}';
}

String _dayRange(Map<String, dynamic>? day) {
  if (day == null) return '—';
  final closed = day['closed'] as bool? ?? false;
  if (closed) return 'Fechado';
  final open = (day['open'] as String?)?.trim() ?? '';
  final close = (day['close'] as String?)?.trim() ?? '';
  if (open.isEmpty || close.isEmpty) return '—';
  return '$open–$close';
}

List<OpenHoursRow> openHoursRowsFromWeeklySchedule(Map<String, dynamic>? schedule) {
  if (schedule == null || schedule.isEmpty) return const [];

  final groups = <({String start, String end, String range})>[];

  for (final day in _weekdayOrder) {
    final row = schedule[day] as Map<String, dynamic>?;
    final range = _dayRange(row);
    final last = groups.isEmpty ? null : groups.last;
    final prevIndex = last == null ? -1 : _weekdayOrder.indexOf(last.end);
    final dayIndex = _weekdayOrder.indexOf(day);
    final isAdjacent = last != null && dayIndex == prevIndex + 1 && last.range == range;

    if (isAdjacent) {
      groups[groups.length - 1] = (start: last.start, end: day, range: range);
    } else {
      groups.add((start: day, end: day, range: range));
    }
  }

  return groups
      .map(
        (g) => OpenHoursRow(
          daysLabel: _dayLabelRange(g.start, g.end),
          rangeLabel: g.range,
        ),
      )
      .toList();
}

List<OpenHoursRow> openHoursRowsFromSummary(String summary) {
  final trimmed = summary.trim();
  if (trimmed.isEmpty) return const [];

  return trimmed
      .split('·')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .map((part) {
        final space = part.lastIndexOf(' ');
        if (space <= 0) return OpenHoursRow(daysLabel: part, rangeLabel: '');
        return OpenHoursRow(
          daysLabel: part.substring(0, space).trim(),
          rangeLabel: part.substring(space + 1).trim(),
        );
      })
      .toList();
}

List<OpenHoursRow> openHoursRows({
  Map<String, dynamic>? weeklySchedule,
  String summary = '',
}) {
  final fromSchedule = openHoursRowsFromWeeklySchedule(weeklySchedule);
  if (fromSchedule.isNotEmpty) return fromSchedule;
  return openHoursRowsFromSummary(summary);
}
