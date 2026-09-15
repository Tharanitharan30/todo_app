import 'package:flutter/material.dart';
import 'neumorphic_card.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NeumorphicCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Command Center',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Local-First Productivity & Finance',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'A local-first personal productivity, task management, finance tracking, analytics, and notification center built with Flutter and Drift SQLite.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoBadge(context, 'App Version', '1.0.0'),
              _buildInfoBadge(context, 'Database Schema', 'v4'),
              _buildInfoBadge(context, 'Architecture', 'Drift / SQLite'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
