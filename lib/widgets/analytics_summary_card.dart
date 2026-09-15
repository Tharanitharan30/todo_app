import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/analytics_provider.dart';
import 'neumorphic_card.dart';

class AnalyticsStatTile extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const AnalyticsStatTile({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NeumorphicCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 14,
      borderColor: color.withValues(alpha: 0.3),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            radius: 20,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductivityOverviewCard extends ConsumerWidget {
  const ProductivityOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(productivityOverviewProvider);

    return overviewAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Text('Error: $err'),
      data: (overview) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isWide ? 1.6 : 1.7,
              children: [
                AnalyticsStatTile(
                  title: 'Completion Rate',
                  value: '${overview.completionRate.toStringAsFixed(1)}%',
                  subtitle:
                      '${overview.tasksCompleted}/${overview.tasksCreated} tasks',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
                AnalyticsStatTile(
                  title: 'Completed Tasks',
                  value: '${overview.tasksCompleted}',
                  subtitle:
                      '${overview.avgCompletedPerDay.toStringAsFixed(1)} avg/day',
                  icon: Icons.done_all,
                  color: Colors.blue,
                ),
                AnalyticsStatTile(
                  title: 'Overdue Tasks',
                  value: '${overview.overdueCount}',
                  subtitle: 'require attention',
                  icon: Icons.warning_amber_rounded,
                  color: overview.overdueCount > 0 ? Colors.red : Colors.grey,
                ),
                AnalyticsStatTile(
                  title: 'Important Tasks',
                  value: '${overview.importantCount}',
                  subtitle: 'starred tasks',
                  icon: Icons.star_outline,
                  color: Colors.amber,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
