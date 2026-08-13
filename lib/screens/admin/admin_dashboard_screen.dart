import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/page_transitions.dart';
import '../../widgets/press_effect.dart';
import '../../widgets/severity_badge.dart';
import 'simulate_disaster_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _service = AdminService();
  late Future<List<List<dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<List<dynamic>>> _load() => Future.wait([
        _service.fetchDisasters(),
        _service.fetchUsers(),
        _service.fetchNotifications(),
      ]);

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.red600,
          onRefresh: _refresh,
          child: FutureBuilder<List<List<dynamic>>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.red600));
              }
              if (snapshot.hasError) {
                return ListView(
                  children: [
                    const SizedBox(height: 120),
                    const Icon(Icons.cloud_off, size: 56, color: AppColors.coral300),
                    const SizedBox(height: 12),
                    Center(child: Text('Could not load: ${snapshot.error}')),
                  ],
                );
              }
              final disasters = snapshot.data![0];
              final users = snapshot.data![1];
              final notifications = snapshot.data![2];
              final sent = notifications.where((n) => n['delivery_status'] == 'sent').length;
              final failed = notifications.where((n) => n['delivery_status'] == 'failed').length;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  FadeSlideIn(
                    child: Row(
                      children: [
                        _stat('Events', '${disasters.length}', Icons.crisis_alert),
                        const SizedBox(width: 10),
                        _stat('Users', '${users.length}', Icons.people_outline),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeSlideIn(
                    index: 1,
                    child: Row(
                      children: [
                        _stat('Delivered', '$sent', Icons.check_circle_outline,
                            color: AppColors.severityLow),
                        const SizedBox(width: 10),
                        _stat('Failed', '$failed', Icons.error_outline,
                            color: AppColors.burgundy900),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('Recent events'),
                  const SizedBox(height: 10),
                  if (disasters.isEmpty)
                    _empty('No disaster events recorded yet.')
                  else
                    ...disasters.take(8).toList().asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: FadeSlideIn(index: e.key, child: _eventCard(e.value)),
                          ),
                        ),
                  const SizedBox(height: 24),
                  _sectionTitle('Notification delivery'),
                  const SizedBox(height: 10),
                  if (notifications.isEmpty)
                    _empty('No notifications dispatched yet.')
                  else
                    ...notifications.take(10).toList().asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: FadeSlideIn(index: e.key, child: _notificationRow(e.value)),
                          ),
                        ),
                ],
              );
            },
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: PressEffect(
            onTap: () async {
              final created = await Navigator.of(context)
                  .push<bool>(smoothRoute(const SimulateDisasterScreen()));
              if (created == true) _refresh();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.burgundy900.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Broadcast New Alert',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: AppColors.burgundy900,
        ),
      );

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(text, style: const TextStyle(color: Colors.black45, fontSize: 13)),
      );

  Widget _stat(String label, String value, IconData icon, {Color color = AppColors.red600}) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
              ),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventCard(dynamic e) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e['title'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${e['category']} · ${e['source']} · '
                    '${DateFormat('d MMM, h:mm a').format(DateTime.parse(e['occurred_at']).toLocal())}',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
            SeverityBadge(severity: e['severity'], compact: true),
          ],
        ),
      ),
    );
  }

  Widget _notificationRow(dynamic n) {
    final status = n['delivery_status'] as String;
    final color = status == 'sent'
        ? AppColors.severityLow
        : status == 'failed'
            ? AppColors.burgundy900
            : AppColors.severityModerate;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              status == 'sent'
                  ? Icons.check_circle
                  : status == 'failed'
                      ? Icons.cancel
                      : Icons.schedule,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n['email'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    n['error'] ?? n['title'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Text(
              status.toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
