import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gym.dart';
import '../models/primary_gym.dart';
import '../services/check_in_location.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Check-in na unidade: o usuário confirma manualmente (GPS + API).
class MemberCheckInScreen extends StatefulWidget {
  const MemberCheckInScreen({
    super.key,
    required this.gym,
    this.planName,
    this.checkInCode,
  });

  final Gym gym;
  final String? planName;
  final String? checkInCode;

  @override
  State<MemberCheckInScreen> createState() => _MemberCheckInScreenState();
}

class _MemberCheckInScreenState extends State<MemberCheckInScreen> {
  _CheckInPhase _phase = _CheckInPhase.ready;
  String? _message;
  double? _distanceKm;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareScreen());
  }

  Future<void> _prepareScreen() async {
    setState(() {
      _loadingLocation = true;
      _phase = _CheckInPhase.ready;
      _message = null;
    });

    await context.read<AppState>().refreshConnectProfile();
    await _refreshDistance();

    if (!mounted) return;
    setState(() => _loadingLocation = false);
  }

  Future<void> _refreshDistance() async {
    if (widget.gym.latitude == null || widget.gym.longitude == null) {
      setState(() => _distanceKm = null);
      return;
    }

    try {
      final position = await CheckInLocationService().resolvePosition(
        gymLatitude: widget.gym.latitude,
        gymLongitude: widget.gym.longitude,
      );
      final km = CheckInLocationService.distanceKm(
        position.latitude,
        position.longitude,
        widget.gym.latitude!,
        widget.gym.longitude!,
      );
      if (mounted) setState(() => _distanceKm = km);
    } catch (_) {
      if (mounted) setState(() => _distanceKm = null);
    }
  }

  Future<void> _runCheckIn() async {
    setState(() {
      _phase = _CheckInPhase.loading;
      _message = null;
    });

    final error = await context.read<AppState>().performGeoCheckIn(
      gym: widget.gym,
      checkInCode: widget.checkInCode,
    );

    if (!mounted) return;

    if (error == null) {
      await context.read<AppState>().refreshConnectProfile();
      setState(() {
        _phase = _CheckInPhase.success;
        _message = 'Entrada liberada automaticamente na recepção.';
      });
    } else {
      setState(() {
        _phase = _CheckInPhase.error;
        _message = error;
      });
    }
  }

  bool get _isDistanceError =>
      _message != null &&
      (_message!.contains('km') || _message!.toLowerCase().contains('localização'));

  bool get _isDuplicateError =>
      _message != null && _message!.toLowerCase().contains('já fez check-in');

  @override
  Widget build(BuildContext context) {
    final primary = context.watch<AppState>().primaryGym;
    final progress = primary != null && primary.gymId == widget.gym.id
        ? _progressHint(primary.checkInsSinceFirst, primary.canChangeToAnotherGym)
        : null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Check-in')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.pageX),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.gym.name, style: AppTypography.sectionTitle),
            const SizedBox(height: 4),
            Text(widget.gym.locationLabel, style: AppTypography.bodyMuted),
            if (widget.planName != null) ...[
              const SizedBox(height: 8),
              Text('Plano: ${widget.planName}', style: AppTypography.caption),
            ],
            if (progress != null) ...[
              const SizedBox(height: 8),
              Text(progress, style: AppTypography.caption.copyWith(color: AppColors.orangeDark)),
            ],
            if (_loadingLocation) ...[
              const SizedBox(height: 8),
              Text('Obtendo localização…', style: AppTypography.caption),
            ] else if (_distanceKm != null) ...[
              const SizedBox(height: 8),
              Text(
                'Você está ${_distanceKm!.toStringAsFixed(1).replaceAll('.', ',')} km desta unidade.',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: AppSpacing.section),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _phaseIcon(),
                    const SizedBox(height: 16),
                    Text(
                      _phaseTitle(),
                      style: AppTypography.cardTitle,
                      textAlign: TextAlign.center,
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _message!,
                        style: AppTypography.bodyMuted,
                        textAlign: TextAlign.center,
                      ),
                    ] else if (_phase == _CheckInPhase.ready) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Toque em confirmar quando estiver na academia (dentro de 1 km).',
                        style: AppTypography.bodyMuted,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Check-in na academia principal, dentro de 1 km, com GPS ativo.',
                      style: AppTypography.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (_phase == _CheckInPhase.ready) ...[
              FilledButton(
                onPressed: _loadingLocation ? null : () => _runCheckIn(),
                child: const Text('Confirmar check-in'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
            if (_phase == _CheckInPhase.error) ...[
              OutlinedButton(
                onPressed: () => _prepareScreen(),
                child: const Text('Atualizar localização'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => _runCheckIn(),
                child: const Text('Tentar novamente'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
            if (_phase == _CheckInPhase.success || _phase == _CheckInPhase.loading)
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _phaseIcon() {
    switch (_phase) {
      case _CheckInPhase.ready:
        return Icon(Icons.qr_code_scanner_rounded, size: 88, color: AppColors.orange);
      case _CheckInPhase.loading:
        return const SizedBox(
          width: 72,
          height: 72,
          child: CircularProgressIndicator(strokeWidth: 3),
        );
      case _CheckInPhase.success:
        return Icon(Icons.check_circle_rounded, size: 88, color: Colors.green.shade600);
      case _CheckInPhase.error:
        if (_isDuplicateError) {
          return Icon(Icons.info_outline_rounded, size: 88, color: AppColors.orangeDark);
        }
        if (_isDistanceError) {
          return Icon(Icons.location_off_rounded, size: 88, color: AppColors.orangeDark);
        }
        return Icon(Icons.error_outline_rounded, size: 88, color: AppColors.orangeDark);
    }
  }

  String _phaseTitle() {
    switch (_phase) {
      case _CheckInPhase.ready:
        return 'Pronto para check-in';
      case _CheckInPhase.loading:
        return 'Validando localização…';
      case _CheckInPhase.success:
        return 'Check-in confirmado';
      case _CheckInPhase.error:
        if (_isDuplicateError) return 'Check-in já realizado hoje';
        return 'Check-in não realizado';
    }
  }

  String _progressHint(int count, bool canChange) {
    if (canChange) {
      return 'Check-in $count na sua academia principal · você já pode trocar de unidade.';
    }
    final left = (PrimaryGymChoice.minCheckInsToChange - count).clamp(0, PrimaryGymChoice.minCheckInsToChange);
    return 'Check-in $count na academia principal · faltam $left para liberar troca de unidade.';
  }
}

enum _CheckInPhase { ready, loading, success, error }
