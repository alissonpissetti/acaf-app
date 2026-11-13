import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/associates_repository.dart';
import '../models/gym.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Mapa de unidades próximas (OpenStreetMap via flutter_map).
class ExploreAssociatesMap extends StatefulWidget {
  const ExploreAssociatesMap({
    super.key,
    required this.gyms,
    required this.centerLat,
    required this.centerLng,
    required this.showUserLocation,
    required this.onGymTap,
    this.onRecenter,
    this.onViewportIdle,
    this.viewportLoading = false,
  });

  final List<Gym> gyms;
  final double centerLat;
  final double centerLng;
  final bool showUserLocation;
  final ValueChanged<Gym> onGymTap;
  final VoidCallback? onRecenter;
  final void Function(GeoBounds bounds)? onViewportIdle;
  final bool viewportLoading;

  @override
  State<ExploreAssociatesMap> createState() => _ExploreAssociatesMapState();
}

class _ExploreAssociatesMapState extends State<ExploreAssociatesMap> {
  static const _userAgentPackage = 'com.movly.app';
  static const _minZoom = 5.0;
  static const _maxZoom = 18.0;
  static const _defaultZoom = 13.5;
  static const _viewportDebounce = Duration(milliseconds: 300);

  final _mapController = MapController();
  late LatLng _center;
  bool _didMoveToCenter = false;
  Timer? _viewportDebounceTimer;

  @override
  void initState() {
    super.initState();
    _center = LatLng(widget.centerLat, widget.centerLng);
  }

  @override
  void didUpdateWidget(covariant ExploreAssociatesMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = LatLng(widget.centerLat, widget.centerLng);
    if (oldWidget.centerLat != widget.centerLat ||
        oldWidget.centerLng != widget.centerLng) {
      _center = next;
      _mapController.move(next, _mapController.camera.zoom);
    }
  }

  @override
  void dispose() {
    _viewportDebounceTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _onMapEvent(MapEvent event) {
    final isIdle = switch (event) {
      MapEventMoveEnd() => true,
      MapEventFlingAnimationEnd() => true,
      _ => false,
    };
    if (!isIdle || widget.onViewportIdle == null) return;

    _viewportDebounceTimer?.cancel();
    _viewportDebounceTimer = Timer(_viewportDebounce, () {
      if (!mounted) return;
      final bounds = _mapController.camera.visibleBounds;
      widget.onViewportIdle!(
        (
          north: bounds.north,
          south: bounds.south,
          east: bounds.east,
          west: bounds.west,
        ),
      );
    });
  }

  void _emitInitialViewport() {
    if (widget.onViewportIdle == null || !_didMoveToCenter) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bounds = _mapController.camera.visibleBounds;
      widget.onViewportIdle!(
        (
          north: bounds.north,
          south: bounds.south,
          east: bounds.east,
          west: bounds.west,
        ),
      );
    });
  }

  List<Marker> _gymMarkers() {
    return widget.gyms.map((gym) {
      final point = LatLng(gym.latitude!, gym.longitude!);
      return Marker(
        point: point,
        width: 44,
        height: 44,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => widget.onGymTap(gym),
          child: Tooltip(
            message: gym.name,
            child: const Icon(
              Icons.location_on_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Marker> _userMarker() {
    if (!widget.showUserLocation) return const [];
    final point = LatLng(widget.centerLat, widget.centerLng);
    return [
      Marker(
        point: point,
        width: 28,
        height: 28,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.lime,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.onLime, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.onLime.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.person_pin_circle, size: 18, color: AppColors.onLime),
        ),
      ),
    ];
  }

  void _recenter() {
    _mapController.move(_center, _defaultZoom);
    widget.onRecenter?.call();
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final next = (camera.zoom + delta).clamp(_minZoom, _maxZoom);
    if (next != camera.zoom) {
      _mapController.move(camera.center, next);
    }
  }

  Widget _mapControlShell({required Widget child}) {
    return Material(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_didMoveToCenter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(_center, _defaultZoom);
        setState(() => _didMoveToCenter = true);
        _emitInitialViewport();
      });
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: _defaultZoom,
            minZoom: _minZoom,
            maxZoom: _maxZoom,
            onMapEvent: _onMapEvent,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: _userAgentPackage,
            ),
            MarkerLayer(markers: [..._gymMarkers(), ..._userMarker()]),
            const RichAttributionWidget(
              showFlutterMapAttribution: false,
              attributions: [
                TextSourceAttribution('© OpenStreetMap'),
              ],
            ),
          ],
        ),
        Positioned(
          right: 12,
          top: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _mapControlShell(
                child: IconButton(
                  tooltip: 'Centralizar',
                  visualDensity: VisualDensity.compact,
                  onPressed: _recenter,
                  icon: const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _mapControlShell(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Aproximar',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _zoomBy(1),
                      icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 22),
                    ),
                    const Divider(height: 1, thickness: 1, color: AppColors.border),
                    IconButton(
                      tooltip: 'Afastar',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _zoomBy(-1),
                      icon: const Icon(Icons.remove_rounded, color: AppColors.primary, size: 22),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.viewportLoading)
          Positioned(
            left: 12,
            right: 12,
            top: 8,
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: AppColors.border,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        if (widget.gyms.isEmpty && !widget.viewportLoading)
          ColoredBox(
            color: AppColors.surface.withValues(alpha: 0.92),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Nenhuma unidade com localização para exibir no mapa.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMuted,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
