import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';

// Lets the user set any location they like: search an address, tap the map, or
// snap back to GPS. Pops a [PickedLocation], or null if they backed out.
class LocationPickerScreen extends StatefulWidget {
  final PickedLocation? initial;
  final String title;
  final String subtitle;
  final String confirmLabel;

  const LocationPickerScreen({
    super.key,
    this.initial,
    this.title = 'Choose a location',
    this.subtitle = 'Search, tap the map, or use GPS',
    this.confirmLabel = 'Use this location',
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _fallbackCenter = LatLng(20.5937, 78.9629); // India, roughly centred.

  final _service = LocationService();
  final _mapController = MapController();
  final _search = TextEditingController();

  late LatLng _selected;
  String? _label;
  bool _resolving = false;
  bool _searching = false;
  bool _locating = false;

  // Guards against an older reverse-geocode overwriting a newer selection.
  int _labelRequest = 0;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _selected = initial != null
        ? LatLng(initial.latitude, initial.longitude)
        : _fallbackCenter;
    _label = initial?.label;
    if (initial == null) _useCurrentLocation(recenterOnly: true);
  }

  @override
  void dispose() {
    _search.dispose();
    _mapController.dispose();
    super.dispose();
  }

  double get _zoom => widget.initial == null ? 4.5 : 13;

  void _select(LatLng point, {String? label, double? zoom}) {
    setState(() {
      _selected = point;
      _label = label;
    });
    _mapController.move(point, zoom ?? _mapController.camera.zoom);
    if (label == null) _resolveLabel(point);
  }

  Future<void> _resolveLabel(LatLng point) async {
    final request = ++_labelRequest;
    setState(() => _resolving = true);
    final label = await _service.reverseGeocode(point.latitude, point.longitude);
    if (!mounted || request != _labelRequest) return;
    setState(() {
      _label = label;
      _resolving = false;
    });
  }

  Future<void> _useCurrentLocation({bool recenterOnly = false}) async {
    setState(() => _locating = true);
    try {
      final pos = await _service.getCurrentPosition();
      if (!mounted) return;
      _select(LatLng(pos.latitude, pos.longitude), zoom: 13);
    } catch (e) {
      // On first open we only try to be helpful — no need to nag if GPS is off.
      if (mounted && !recenterOnly) _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
    if (mounted) setState(() => _locating = false);
  }

  Future<void> _runSearch() async {
    final query = _search.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _searching = true);
    final results = await _service.searchAddress(query);
    if (!mounted) return;
    setState(() => _searching = false);

    if (results.isEmpty) {
      _showMessage('No place matched "$query". Try a different search or tap the map.');
      return;
    }
    if (results.length == 1) {
      _applyResult(results.first);
      return;
    }

    final chosen = await showModalBottomSheet<PickedLocation>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select a match',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
            ...results.map(
              (r) => ListTile(
                leading: const Icon(Icons.place_outlined, color: AppColors.red600),
                title: Text(r.label ?? r.coordinates, style: const TextStyle(fontSize: 14)),
                subtitle: Text(r.coordinates, style: const TextStyle(fontSize: 11)),
                onTap: () => Navigator.of(context).pop(r),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (chosen != null) _applyResult(chosen);
  }

  void _applyResult(PickedLocation result) {
    _select(LatLng(result.latitude, result.longitude), label: result.label, zoom: 13);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      title: widget.title,
      subtitle: widget.subtitle,
      showBack: true,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _runSearch(),
              decoration: InputDecoration(
                hintText: 'Search a city, area or address',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: _searching
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward, color: AppColors.red600),
                  onPressed: _searching ? null : _runSearch,
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selected,
                      initialZoom: _zoom,
                      onTap: (_, point) => _select(point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.LifeLoop.disaster_alert_system',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selected,
                            width: 46,
                            height: 46,
                            alignment: Alignment.topCenter,
                            child: const Icon(
                              Icons.location_on,
                              size: 46,
                              color: AppColors.red600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'picker-gps',
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.red600,
                    onPressed: _locating ? null : () => _useCurrentLocation(),
                    child: _locating
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                  ),
                ),
                const Positioned(
                  left: 16,
                  top: 12,
                  child: _MapHint(),
                ),
              ],
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.place, size: 18, color: AppColors.red600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _resolving
                              ? 'Resolving address…'
                              : _label ?? 'Dropped pin',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: Text(
                      '${_selected.latitude.toStringAsFixed(4)}, '
                      '${_selected.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(
                        PickedLocation(
                          latitude: _selected.latitude,
                          longitude: _selected.longitude,
                          label: _label,
                        ),
                      ),
                      icon: const Icon(Icons.check),
                      label: Text(widget.confirmLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapHint extends StatelessWidget {
  const _MapHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Tap anywhere to drop the pin',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
