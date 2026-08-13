import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/alert.dart';
import '../../services/alert_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/press_effect.dart';
import '../../widgets/severity_badge.dart';

const Map<String, IconData> categoryIcons = {
  'earthquake': Icons.landscape,
  'flood': Icons.water,
  'cyclone': Icons.cyclone,
  'wildfire': Icons.local_fire_department,
  'landslide': Icons.terrain,
  'other': Icons.warning_amber,
};

class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({super.key});

  @override
  State<AlertHistoryScreen> createState() => AlertHistoryScreenState();
}

class AlertHistoryScreenState extends State<AlertHistoryScreen> {
  final _service = AlertService();
  late Future<List<DisasterAlert>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchMyAlerts();
  }

  Future<void> refresh() async {
    setState(() {
      _future = _service.fetchMyAlerts();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.red600,
      onRefresh: refresh,
      child: FutureBuilder<List<DisasterAlert>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.red600));
          }
          if (snapshot.hasError) {
            return _message(
              icon: Icons.cloud_off,
              title: 'Could not load alerts',
              body: '${snapshot.error}',
            );
          }
          final alerts = snapshot.data ?? [];
          if (alerts.isEmpty) {
            return _message(
              icon: Icons.verified_user,
              title: 'No alerts yet',
              body: 'You are all clear. Alerts for disasters near your location will appear here.',
            );
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: alerts.length,
            separatorBuilder: (_, i) => const SizedBox(height: 12),
            itemBuilder: (context, i) => FadeSlideIn(
              index: i,
              child: _AlertCard(alert: alerts[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _message({required IconData icon, required String title, required String body}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Icon(icon, size: 64, color: AppColors.coral300),
        const SizedBox(height: 16),
        Center(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final DisasterAlert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = severityColor(alert.severity);
    return PressEffect(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _AlertDetailSheet(alert: alert),
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(categoryIcons[alert.category] ?? Icons.warning_amber, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.burgundy900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SeverityBadge(severity: alert.severity, compact: true),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alert.category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w600,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('d MMM yyyy, h:mm a').format(alert.createdAt.toLocal()),
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertDetailSheet extends StatelessWidget {
  final DisasterAlert alert;
  const _AlertDetailSheet({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SeverityBadge(severity: alert.severity),
          const SizedBox(height: 12),
          Text(alert.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          if (alert.description != null && alert.description!.isNotEmpty) ...[
            Text(alert.description!, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 16),
          ],
          Text(
            'Occurred ${DateFormat('d MMM yyyy, h:mm a').format(alert.occurredAt.toLocal())}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            'Location: ${alert.latitude.toStringAsFixed(3)}, ${alert.longitude.toStringAsFixed(3)}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
