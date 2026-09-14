import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/calendar_provider.dart';
import 'calendar_task_item.dart';

class CalendarAgendaView extends ConsumerWidget {
  const CalendarAgendaView({super.key});

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Today';
    } else if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow';
    }

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final calState = ref.watch(calendarStateProvider);
    final agendaMap = ref.watch(calendarAgendaTasksProvider);

    return Column(
      children: [
        // CATEGORY FILTER CHIPS
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: ['all', 'personal', 'work', 'study', 'project', 'other']
                .map((cat) {
                  final isSelected =
                      calState.categoryFilter.toLowerCase() == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(
                        cat == 'all'
                            ? 'All Categories'
                            : '${cat[0].toUpperCase()}${cat.substring(1)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        ref
                            .read(calendarStateProvider.notifier)
                            .setCategoryFilter(selected ? cat : 'all');
                      },
                    ),
                  );
                })
                .toList(),
          ),
        ),

        const Divider(height: 1),

        // CHRONOLOGICAL LIST
        Expanded(
          child: agendaMap.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.event_available_outlined,
                          size: 56,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No scheduled tasks found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your agenda is clear for the upcoming days.',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: agendaMap.keys.length,
                  itemBuilder: (context, index) {
                    final date = agendaMap.keys.elementAt(index);
                    final tasks = agendaMap[date] ?? [];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _formatDateHeader(date),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Divider(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...tasks.map((t) => CalendarTaskItem(task: t)),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
