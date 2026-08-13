import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/page_transitions.dart';
import '../location/location_picker_screen.dart';

class LocationSetupScreen extends StatefulWidget {
  const LocationSetupScreen({super.key});

  @override
  State<LocationSetupScreen> createState() => _LocationSetupScreenState();
}

class _LocationSetupScreenState extends State<LocationSetupScreen> {
  final _service = LocationService();
  bool _busy = false;
  String? _status;

  Future<void> _useCurrentLocation() async {
    setState(() {
      _busy = true;
      _status = 'Getting your location…';
    });
    try {
      final pos = await _service.getCurrentPosition();
      setState(() => _status = 'Resolving address…');
      final label = await _service.reverseGeocode(pos.latitude, pos.longitude);
      await _save(PickedLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        label: label,
      ));
    } catch (e) {
      if (mounted) {
        setState(() => _status = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  // Lets people who can't or won't share GPS pick their area by hand.
  Future<void> _chooseManually() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      smoothRoute(const LocationPickerScreen(
        title: 'Set your location',
        subtitle: 'Search a place or tap the map',
        confirmLabel: 'Save this location',
      )),
    );
    if (picked == null || !mounted) return;

    setState(() {
      _busy = true;
      _status = 'Saving ${picked.label ?? picked.coordinates}…';
    });
    try {
      await _save(picked);
    } catch (e) {
      if (mounted) {
        setState(() => _status = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _save(PickedLocation location) async {
    await _service.updateLocation(
      latitude: location.latitude,
      longitude: location.longitude,
      label: location.label,
    );
    if (!mounted) return;
    await context.read<AuthService>().syncProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeSlideIn(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 56, color: AppColors.red600),
                        const SizedBox(height: 16),
                        Text('Set your location',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        const Text(
                          'We use your location only to decide whether a disaster affects your area. '
                          'You will only be alerted about events near you.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _status != null
                              ? Padding(
                                  key: const ValueKey('status'),
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    _status!,
                                    style: const TextStyle(
                                      color: AppColors.burgundy700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(key: ValueKey('empty')),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _busy ? null : _useCurrentLocation,
                            icon: _busy
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.my_location),
                            label: Text(_busy ? 'Please wait…' : 'Use my current location'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : _chooseManually,
                            icon: const Icon(Icons.map_outlined, size: 18),
                            label: const Text('Set a custom location'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.red600,
                              side: const BorderSide(color: AppColors.red600),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.read<AuthService>().logout(),
                          child: const Text('Sign out'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
