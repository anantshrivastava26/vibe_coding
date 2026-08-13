import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/page_transitions.dart';
import '../../widgets/press_effect.dart';
import '../location/location_picker_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _location = LocationService();
  bool _updating = false;

  Future<void> _refreshLocation() async {
    setState(() => _updating = true);
    try {
      final pos = await _location.getCurrentPosition();
      final label = await _location.reverseGeocode(pos.latitude, pos.longitude);
      await _save(PickedLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        label: label,
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
    if (mounted) setState(() => _updating = false);
  }

  // Opens the map picker seeded with whatever location is currently saved.
  Future<void> _chooseCustomLocation() async {
    final profile = context.read<AuthService>().profile;
    final current = profile?.hasLocation == true
        ? PickedLocation(
            latitude: profile!.latitude!,
            longitude: profile.longitude!,
            label: profile.locationLabel,
          )
        : null;

    final picked = await Navigator.of(context).push<PickedLocation>(
      smoothRoute(LocationPickerScreen(
        initial: current,
        title: 'Change location',
        subtitle: 'Alerts follow the pin you drop here',
        confirmLabel: 'Save this location',
      )),
    );
    if (picked == null || !mounted) return;

    setState(() => _updating = true);
    try {
      await _save(picked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
    if (mounted) setState(() => _updating = false);
  }

  Future<void> _save(PickedLocation location) async {
    await _location.updateLocation(
      latitude: location.latitude,
      longitude: location.longitude,
      label: location.label,
    );
    if (!mounted) return;
    await context.read<AuthService>().syncProfile();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Location updated.')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final profile = auth.profile;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        FadeSlideIn(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profile?.email ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.red600.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      (profile?.role ?? 'user').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.red600,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          index: 1,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on, size: 18, color: AppColors.red600),
                      SizedBox(width: 8),
                      Text('Alert location',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile?.locationLabel ?? 'No address resolved',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile?.hasLocation == true
                        ? '${profile!.latitude!.toStringAsFixed(4)}, ${profile.longitude!.toStringAsFixed(4)}'
                        : 'Not set',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _updating ? null : _chooseCustomLocation,
                      icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                      label: const Text('Change location'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _updating ? null : _refreshLocation,
                      icon: _updating
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, size: 18),
                      label: Text(_updating ? 'Updating…' : 'Sync to my GPS location'),
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
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        FadeSlideIn(
          index: 2,
          child: PressEffect(
            onTap: () => context.read<AuthService>().logout(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.burgundy900.withValues(alpha: 0.15)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, size: 18, color: AppColors.burgundy900),
                  SizedBox(width: 8),
                  Text('Sign out',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: AppColors.burgundy900)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
