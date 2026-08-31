import 'package:flutter/material.dart';

import '../models/gym.dart';
import '../services/connect_api.dart';
import '../screens/modality_booking_screen.dart';

/// Busca modalidades com agenda na API e exibe botões de reserva.
class GymModalityBookingSection extends StatefulWidget {
  const GymModalityBookingSection({super.key, required this.gym});

  final Gym gym;

  @override
  State<GymModalityBookingSection> createState() => _GymModalityBookingSectionState();
}

class _GymModalityBookingSectionState extends State<GymModalityBookingSection> {
  final _api = ConnectApi();
  List<String> _scheduledModalities = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final unit = await _api.fetchUnitPublic(widget.gym.id);
    if (!mounted) return;
    setState(() {
      _scheduledModalities = unit?.scheduledModalities ?? widget.gym.scheduledModalities;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _scheduledModalities.isEmpty) {
      return const SizedBox.shrink();
    }
    return ModalityBookingEntry(
      gym: widget.gym,
      scheduledModalities: _scheduledModalities,
    );
  }
}

/// Versão estática quando scheduledModalities já é conhecido.
class GymModalityBookingStatic extends StatelessWidget {
  const GymModalityBookingStatic({
    super.key,
    required this.gym,
    required this.scheduledModalities,
  });

  final Gym gym;
  final List<String> scheduledModalities;

  @override
  Widget build(BuildContext context) {
    return ModalityBookingEntry(
      gym: gym,
      scheduledModalities: scheduledModalities,
    );
  }
}
