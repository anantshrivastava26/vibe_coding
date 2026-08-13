import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SeverityBadge extends StatelessWidget {
  final String severity;
  final bool compact;

  const SeverityBadge({super.key, required this.severity, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = severityColor(severity);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            severity.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 10 : 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
