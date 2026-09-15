import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/search_provider.dart';
import '../widgets/neumorphic_button.dart';
import '../widgets/neumorphic_card.dart';
import '../widgets/neumorphic_container.dart';
import '../widgets/neumorphic_icon_button.dart';
import '../widgets/neumorphic_input.dart';
import 'task_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    final state = ref.read(searchProvider);
    _controller = TextEditingController(text: state.query);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ref.read(searchProvider.notifier).search(query);
    });
  }

  void _executeSearch(String term) {
    _controller.text = term;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: term.length),
    );
    ref.read(searchProvider.notifier).addRecentSearch(term);
    ref.read(searchProvider.notifier).search(term);
  }

  void _handleResultClick(SearchResultItem item) {
    ref.read(searchProvider.notifier).addRecentSearch(_controller.text);

    switch (item.category) {
      case SearchCategory.tasks:
        final task = item.rawData;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
        );
        break;
      case SearchCategory.expenses:
      case SearchCategory.income:
      case SearchCategory.budgets:
      case SearchCategory.savings:
      case SearchCategory.subscriptions:
        context.go('/finance');
        break;
      case SearchCategory.notifications:
        context.go('/notifications');
        break;
      case SearchCategory.all:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: NeumorphicInput(
          controller: _controller,
          hintText: 'Search everything...',
          prefixIcon: Icons.search,
          suffixIcon: _controller.text.isNotEmpty
              ? NeumorphicIconButton(
                  icon: Icons.clear,
                  size: 30,
                  iconSize: 16,
                  onPressed: () {
                    _controller.clear();
                    ref.read(searchProvider.notifier).search('');
                  },
                )
              : null,
          onChanged: _onQueryChanged,
          onSubmitted: (term) {
            if (term.trim().isNotEmpty) {
              _executeSearch(term);
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: SearchCategory.values.map((cat) {
                final isSelected = searchState.categoryFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(searchProvider.notifier).setCategoryFilter(cat);
                    },
                    child: NeumorphicContainer(
                      style: isSelected
                          ? NeumorphicStyle.inset
                          : NeumorphicStyle.raised,
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.15)
                          : null,
                      borderColor: isSelected
                          ? theme.colorScheme.primary
                          : null,
                      child: Text(
                        cat.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // Main Content
          Expanded(
            child: searchState.isSearching
                ? const Center(child: CircularProgressIndicator())
                : searchState.query.isEmpty
                ? _buildEmptyQueryView(searchState, theme)
                : _buildSearchResultsView(searchState, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyQueryView(SearchState state, ThemeData theme) {
    final recent = state.recentSearches;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (recent.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  ref.read(searchProvider.notifier).clearRecentSearches();
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...recent.map(
            (term) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              child: NeumorphicCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                borderRadius: 10,
                onTap: () => _executeSearch(term),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        term,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    NeumorphicIconButton(
                      icon: Icons.close,
                      size: 28,
                      iconSize: 14,
                      onPressed: () {
                        ref
                            .read(searchProvider.notifier)
                            .removeRecentSearch(term);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        const Text(
          'Quick Shortcuts',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            NeumorphicButton(
              icon: Icons.check_circle_outline,
              label: 'Tasks',
              onPressed: () => context.go('/tasks'),
            ),
            NeumorphicButton(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Expenses',
              onPressed: () => context.go('/finance'),
            ),
            NeumorphicButton(
              icon: Icons.attach_money,
              label: 'Income',
              onPressed: () => context.go('/finance'),
            ),
            NeumorphicButton(
              icon: Icons.calendar_month_outlined,
              label: 'Calendar',
              onPressed: () => context.go('/calendar'),
            ),
            NeumorphicButton(
              icon: Icons.timer_outlined,
              label: 'Focus',
              onPressed: () => context.go('/focus'),
            ),
            NeumorphicButton(
              icon: Icons.pie_chart_outline,
              label: 'Budgets',
              onPressed: () => context.go('/finance'),
            ),
          ],
        ),

        if (recent.isEmpty) ...[
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.search,
                  size: 48,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  'Start typing to search everything.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchResultsView(SearchState state, ThemeData theme) {
    if (state.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No results found for "${state.query}"',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.results.length,
      itemBuilder: (context, index) {
        final item = state.results[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: NeumorphicCard(
            padding: const EdgeInsets.all(12),
            borderRadius: 12,
            onTap: () => _handleResultClick(item),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.15,
                  ),
                  radius: 18,
                  child: Icon(
                    item.icon,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (item.badgeColor ?? Colors.blue).withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (item.badgeColor ?? Colors.blue).withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: Text(
                      item.badgeText!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: item.badgeColor ?? Colors.blue,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
