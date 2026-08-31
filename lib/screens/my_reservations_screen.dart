import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/modality_schedule.dart';
import '../services/connect_api.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/connect_page_header.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MyReservationsScreen()),
    );
  }

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  final _api = ConnectApi();
  List<ModalityReservation> _reservations = const [];
  bool _loading = true;
  String? _cancellingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final appState = context.read<AppState>();
    final enrollment = appState.companyEnrollment;
    final holderName =
        enrollment?.collaboratorLabel ?? enrollment?.companyName ?? 'Associado app';
    final rows = await _api.fetchMyReservations(holderName);
    if (!mounted) return;
    setState(() {
      _reservations = rows;
      _loading = false;
    });
  }

  Future<void> _cancel(ModalityReservation reservation) async {
    setState(() => _cancellingId = reservation.id);
    final ok = await _api.cancelReservation(reservation.id);
    if (!mounted) return;
    setState(() => _cancellingId = null);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível cancelar a reserva.')),
      );
      return;
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConnectPageHeader(
            title: 'Minhas reservas',
            subtitle: 'Aulas com horário reservado nas unidades parceiras.',
            trailing: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _reservations.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Você ainda não possui reservas de aula.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMuted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.pageX),
                        itemCount: _reservations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _reservations[index];
                          final busy = _cancellingId == item.id;
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.modality, style: AppTypography.cardTitle),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.occurrenceDate} · ${item.startTime}–${item.endTime}',
                                    style: AppTypography.bodyMuted,
                                  ),
                                  if (item.instructorName != null)
                                    Text(
                                      'Prof. ${item.instructorName}',
                                      style: AppTypography.caption,
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.orangeSoft,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          item.statusLabel,
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.orangeDark,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (item.status == 'confirmed')
                                        TextButton(
                                          onPressed: busy ? null : () => _cancel(item),
                                          child: busy
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : const Text('Cancelar'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
