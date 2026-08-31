import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/modality_booking_access.dart';
import '../models/gym.dart';
import '../models/modality_schedule.dart';
import '../navigation/open_connect_plan_tab.dart';
import '../services/connect_api.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/connect_primary_button.dart';
import '../widgets/modality_slot_card.dart';
import 'daily_pass_screen.dart';

class ModalityBookingScreen extends StatefulWidget {
  const ModalityBookingScreen({
    super.key,
    required this.gym,
    required this.modality,
    this.scheduledModalities = const [],
  });

  final Gym gym;
  final String modality;
  final List<String> scheduledModalities;

  @override
  State<ModalityBookingScreen> createState() => _ModalityBookingScreenState();
}

class _ModalityBookingScreenState extends State<ModalityBookingScreen> {
  final _api = ConnectApi();
  late DateTime _selectedDay;
  List<ModalityAvailabilitySlot> _slots = const [];
  bool _loading = true;
  String? _error;
  String? _bookingKey;

  static const _horizonDays = 28;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadSlots();
  }

  String get _unitId => widget.gym.id;

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadSlots() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final from = _formatDate(DateTime.now());
    final to = _formatDate(DateTime.now().add(const Duration(days: _horizonDays - 1)));
    final result = await _api.fetchModalityAvailability(
      unitId: _unitId,
      from: from,
      to: to,
      modality: widget.modality,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.ok) {
        _slots = result.slots;
        _error = null;
      } else {
        _slots = const [];
        _error = result.errorMessage ?? 'Não foi possível carregar os horários.';
      }
    });
  }

  List<ModalityAvailabilitySlot> get _daySlots {
    final key = _formatDate(_selectedDay);
    return _slots
        .where((s) => s.occurrenceDate == key)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  String _holderName(AppState appState) {
    final enrollment = appState.companyEnrollment;
    return enrollment?.collaboratorLabel ?? enrollment?.companyName ?? 'Associado app';
  }

  Future<void> _confirmAndBook(ModalityAvailabilitySlot slot) async {
    final appState = context.read<AppState>();
    final access = evaluateModalityBookingAccess(
      appState: appState,
      gym: widget.gym,
      modality: widget.modality,
      occurrenceDate: slot.occurrenceDate,
    );
    if (!access.canBook) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(access.reason ?? 'Sem permissão para reservar.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar reserva'),
        content: Text(
          '${slot.modality}\n${slot.startTime}–${slot.endTime}\n'
          '${slot.instructorLabel}\n\n'
          '${slot.available} vaga${slot.available == 1 ? '' : 's'} disponível${slot.available == 1 ? '' : 'eis'} neste horário.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _book(slot);
  }

  Future<void> _book(ModalityAvailabilitySlot slot) async {
    final appState = context.read<AppState>();
    setState(() => _bookingKey = slot.occurrenceKey);

    final result = await _api.createReservation(
      unitId: _unitId,
      occurrenceDate: slot.occurrenceDate,
      slotTemplateId: slot.slotTemplateId,
      overrideId: slot.overrideId,
      holderName: _holderName(appState),
    );

    if (!mounted) return;
    setState(() => _bookingKey = null);

    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ?? 'Não foi possível reservar este horário.',
          ),
        ),
      );
      return;
    }

    await _loadSlots();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reserva confirmada · ${slot.modality} ${slot.startTime}–${slot.endTime}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final daySlots = _daySlots;
    final selectedDateKey = _formatDate(_selectedDay);
    final dayAccess = evaluateModalityBookingAccess(
      appState: appState,
      gym: widget.gym,
      modality: widget.modality,
      occurrenceDate: selectedDateKey,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Reservar ${widget.modality}'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.foreground,
      ),
      body: RefreshIndicator(
        onRefresh: _loadSlots,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pageX),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Text(widget.gym.name, style: AppTypography.cardTitle),
            const SizedBox(height: 4),
            Text(
              'Escolha o dia e o horário. Reserva exige diária válida hoje ou plano nesta unidade.',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.item),
            _ModalityAccessBanner(access: dayAccess, gym: widget.gym),
            const SizedBox(height: AppSpacing.section),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _horizonDays,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final day = DateTime.now().add(Duration(days: index));
                  final selected = _formatDate(day) == _formatDate(_selectedDay);
                  return ChoiceChip(
                    label: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${day.day}/${day.month}', style: const TextStyle(fontSize: 12)),
                        Text(
                          _weekdayLabel(day.weekday),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedDay = day),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _ErrorPanel(message: _error!, onRetry: _loadSlots)
            else if (daySlots.isEmpty)
              _EmptyDayPanel(
                modality: widget.modality,
                dateLabel: _selectedDayLabel(_selectedDay),
              )
            else ...[
              if (!dayAccess.canBook)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.item),
                  child: _AccessGatePanel(
                    access: dayAccess,
                    gym: widget.gym,
                    modality: widget.modality,
                  ),
                ),
              ModalityDaySummary(slots: daySlots),
              const SizedBox(height: AppSpacing.item),
              Text('Horários do dia', style: AppTypography.sectionTitle),
              const SizedBox(height: AppSpacing.item),
              ...daySlots.map(
                (slot) {
                  final slotAccess = evaluateModalityBookingAccess(
                    appState: appState,
                    gym: widget.gym,
                    modality: widget.modality,
                    occurrenceDate: slot.occurrenceDate,
                  );
                  return ModalitySlotCard(
                    slot: slot,
                    busy: _bookingKey == slot.occurrenceKey,
                    onReserve: slotAccess.canBook && !slot.isFull
                        ? () => _confirmAndBook(slot)
                        : null,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    const labels = ['', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return labels[weekday];
  }

  String _selectedDayLabel(DateTime day) {
    return '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}';
  }
}

class _ModalityAccessBanner extends StatelessWidget {
  const _ModalityAccessBanner({required this.access, required this.gym});

  final ModalityBookingAccess access;
  final Gym gym;

  @override
  Widget build(BuildContext context) {
    if (access.canBook) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.orangeSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.orange.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.orange, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                access.accessLabel ?? 'Acesso liberado para reservar',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              access.reason ?? 'Compre uma diária ou vincule seu plano nesta unidade.',
              style: AppTypography.caption,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessGatePanel extends StatelessWidget {
  const _AccessGatePanel({
    required this.access,
    required this.gym,
    required this.modality,
  });

  final ModalityBookingAccess access;
  final Gym gym;
  final String modality;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reserva não disponível',
            style: AppTypography.cardTitle.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            access.reason ?? 'É necessário diária válida hoje ou plano nesta unidade.',
            style: AppTypography.bodyMuted,
          ),
          const SizedBox(height: 14),
          ConnectPrimaryButton(
            label: 'Comprar diária · R\$ ${gym.dailyPassPrice.toStringAsFixed(2)}',
            icon: Icons.qr_code_2_rounded,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => DailyPassScreen(gym: gym)),
              );
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => openConnectPlanTab(context),
            icon: const Icon(Icons.workspace_premium_outlined, size: 20),
            label: const Text('Ver plano em Minha conta'),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.orangeSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Não foi possível carregar a programação',
            style: AppTypography.cardTitle.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(message, style: AppTypography.bodyMuted),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => onRetry(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _EmptyDayPanel extends StatelessWidget {
  const _EmptyDayPanel({required this.modality, required this.dateLabel});

  final String modality;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'Nenhuma aula programada',
            style: AppTypography.sectionTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Não há horários de $modality em $dateLabel. Tente outro dia da lista.',
            style: AppTypography.bodyMuted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ModalityBookingEntry extends StatelessWidget {
  const ModalityBookingEntry({
    super.key,
    required this.gym,
    required this.scheduledModalities,
  });

  final Gym gym;
  final List<String> scheduledModalities;

  @override
  Widget build(BuildContext context) {
    if (scheduledModalities.isEmpty) return const SizedBox.shrink();

    final bookable = scheduledModalities
        .where((m) => gym.modalities.any((u) => u.toLowerCase() == m.toLowerCase()))
        .toList();
    if (bookable.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reservar horário', style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.item),
        ...bookable.map(
          (modality) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ConnectPrimaryButton(
              label: 'Reservar $modality',
              icon: Icons.event_available_rounded,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ModalityBookingScreen(
                      gym: gym,
                      modality: modality,
                      scheduledModalities: scheduledModalities,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.section),
      ],
    );
  }
}
