import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/search_provider.dart';
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
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search everything...',
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      ref.read(searchProvider.notifier).search('');
                    },
                  )
                : null,
          ),
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
                  child: FilterChip(
                    label: Text(cat.label),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(searchProvider.notifier).setCategoryFilter(cat);
                    },
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
          ...recent.map(
            (term) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history, size: 20),
              title: Text(term),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  ref.read(searchProvider.notifier).removeRecentSearch(term);
                },
              ),
              onTap: () => _executeSearch(term),
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
            ActionChip(
              avatar: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Tasks'),
              onPressed: () => context.go('/tasks'),
            ),
            ActionChip(
              avatar: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
              ),
              label: const Text('Expenses'),
              onPressed: () => context.go('/finance'),
            ),
            ActionChip(
              avatar: const Icon(Icons.attach_money, size: 18),
              label: const Text('Income'),
              onPressed: () => context.go('/finance'),
            ),
            ActionChip(
              avatar: const Icon(Icons.calendar_month_outlined, size: 18),
              label: const Text('Calendar'),
              onPressed: () => context.go('/calendar'),
            ),
            ActionChip(
              avatar: const Icon(Icons.timer_outlined, size: 18),
              label: const Text('Focus'),
              onPressed: () => context.go('/focus'),
            ),
            ActionChip(
              avatar: const Icon(Icons.pie_chart_outline, size: 18),
              label: const Text('Budgets'),
              onPressed: () => context.go('/finance'),
            ),
          ],
        ),

        if (recent.isEmpty) ...[
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Icon(Icons.search, size: 48, color: theme.disabledColor),
                const SizedBox(height: 12),
                Text(
                  'Start typing to search everything.',
                  style: TextStyle(color: theme.disabledColor),
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
              color: theme.disabledColor,
            ),
            const SizedBox(height: 12),
            Text(
              'No results found for "${state.query}"',
              style: TextStyle(color: theme.disabledColor, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: state.results.length,
      separatorBuilder: (ctx, idx) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = state.results[index];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 20,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(item.subtitle),
          trailing: item.badgeText != null
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (item.badgeColor ?? Colors.blue).withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (item.badgeColor ?? Colors.blue).withAlpha(100),
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
                )
              : null,
          onTap: () => _handleResultClick(item),
        );
      },
    );
  }
}
