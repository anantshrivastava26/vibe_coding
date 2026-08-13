import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../widgets/page_transitions.dart';
import '../location/location_picker_screen.dart';

const _categories = ['earthquake', 'flood', 'cyclone', 'wildfire', 'landslide', 'other'];
const _severities = ['low', 'moderate', 'high', 'critical'];

class SimulateDisasterScreen extends StatefulWidget {
  const SimulateDisasterScreen({super.key});

  @override
  State<SimulateDisasterScreen> createState() => _SimulateDisasterScreenState();
}

class _SimulateDisasterScreenState extends State<SimulateDisasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = AdminService();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _lat = TextEditingController();
  final _lon = TextEditingController();

  String _category = 'cyclone';
  String _severity = 'high';
  double _radiusKm = 50;
  bool _busy = false;
  String? _epicentreLabel;

  @override
  void initState() {
    super.initState();
    // Prefill with the admin's own coordinates so a test alert reliably
    // matches at least this device during a demo.
    final profile = context.read<AuthService>().profile;
    if (profile?.latitude != null) _lat.text = profile!.latitude!.toStringAsFixed(5);
    if (profile?.longitude != null) _lon.text = profile!.longitude!.toStringAsFixed(5);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _lat.dispose();
    _lon.dispose();
    super.dispose();
  }

  // Picking the epicentre on a map is far less error-prone than typing
  // coordinates when broadcasting to a real region.
  Future<void> _pickEpicentre() async {
    final lat = double.tryParse(_lat.text);
    final lon = double.tryParse(_lon.text);
    final picked = await Navigator.of(context).push<PickedLocation>(
      smoothRoute(LocationPickerScreen(
        initial: lat != null && lon != null
            ? PickedLocation(latitude: lat, longitude: lon, label: _epicentreLabel)
            : null,
        title: 'Pick epicentre',
        subtitle: 'Everyone within the radius gets alerted',
        confirmLabel: 'Use as epicentre',
      )),
    );
    if (picked == null) return;
    setState(() {
      _lat.text = picked.latitude.toStringAsFixed(5);
      _lon.text = picked.longitude.toStringAsFixed(5);
      _epicentreLabel = picked.label;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final result = await _service.simulateDisaster(
        category: _category,
        severity: _severity,
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        latitude: double.parse(_lat.text),
        longitude: double.parse(_lon.text),
        affectedRadiusKm: _radiusKm,
      );
      if (!mounted) return;
      final count = result['alertsCreated'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alert dispatched — $count user(s) in the affected region notified.'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      title: 'Broadcast Alert',
      subtitle: 'Create an event and notify everyone in range',
      showBack: true,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FadeSlideIn(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Disaster type',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((c) {
                          final selected = _category == c;
                          return ChoiceChip(
                            label: Text(c[0].toUpperCase() + c.substring(1)),
                            selected: selected,
                            onSelected: (_) => setState(() => _category = c),
                            selectedColor: AppColors.red600,
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : AppColors.burgundy900,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                              side: BorderSide(
                                color: AppColors.burgundy900.withValues(alpha: 0.15),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text('Severity',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 10),
                      Row(
                        children: _severities.map((s) {
                          final selected = _severity == s;
                          final color = severityColor(s);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: GestureDetector(
                                onTap: () => setState(() => _severity = s),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected ? color : color.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: color.withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    s[0].toUpperCase() + s.substring(1),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: selected ? Colors.white : color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
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
                    children: [
                      TextFormField(
                        controller: _title,
                        decoration: const InputDecoration(
                          labelText: 'Alert title',
                          hintText: 'e.g. Cyclone Warning — Coastal Region',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _description,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FadeSlideIn(
              index: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Epicentre',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _lat,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: const InputDecoration(labelText: 'Latitude'),
                              validator: (v) =>
                                  double.tryParse(v ?? '') == null ? 'Invalid' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lon,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: const InputDecoration(labelText: 'Longitude'),
                              validator: (v) =>
                                  double.tryParse(v ?? '') == null ? 'Invalid' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _pickEpicentre,
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text('Pick epicentre on map'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.red600,
                            side: const BorderSide(color: AppColors.red600),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      if (_epicentreLabel != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _epicentreLabel!,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Affected radius',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(
                            '${_radiusKm.round()} km',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.red600,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _radiusKm,
                        min: 5,
                        max: 500,
                        divisions: 99,
                        activeColor: AppColors.red600,
                        onChanged: (v) => setState(() => _radiusKm = v),
                      ),
                      const Text(
                        'Only users whose saved location falls inside this radius are alerted.',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.campaign),
                label: Text(_busy ? 'Dispatching…' : 'Send Alert Now'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
