import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'add_expense_dialog.dart';
import 'add_income_dialog.dart';
import 'add_task_dialog.dart';

class CommandPaletteItem {
  final String label;
  final IconData icon;
  final VoidCallback action;

  const CommandPaletteItem({
    required this.label,
    required this.icon,
    required this.action,
  });
}

class CommandPaletteDialog extends StatefulWidget {
  const CommandPaletteDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const CommandPaletteDialog(),
    );
  }

  @override
  State<CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<CommandPaletteDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  int _selectedIndex = 0;
  String _filter = '';

  List<CommandPaletteItem> _getCommands(BuildContext context) {
    return [
      CommandPaletteItem(
        label: 'Add Task',
        icon: Icons.add_task,
        action: () {
          Navigator.of(context).pop();
          showDialog(context: context, builder: (_) => const AddTaskDialog());
        },
      ),
      CommandPaletteItem(
        label: 'Add Expense',
        icon: Icons.account_balance_wallet_outlined,
        action: () {
          Navigator.of(context).pop();
          showDialog(
            context: context,
            builder: (_) => const AddExpenseDialog(),
          );
        },
      ),
      CommandPaletteItem(
        label: 'Add Income',
        icon: Icons.attach_money,
        action: () {
          Navigator.of(context).pop();
          showDialog(context: context, builder: (_) => const AddIncomeDialog());
        },
      ),
      CommandPaletteItem(
        label: 'Start Focus',
        icon: Icons.timer_outlined,
        action: () {
          Navigator.of(context).pop();
          context.go('/focus');
        },
      ),
      CommandPaletteItem(
        label: 'Open Calendar',
        icon: Icons.calendar_month_outlined,
        action: () {
          Navigator.of(context).pop();
          context.go('/calendar');
        },
      ),
      CommandPaletteItem(
        label: 'Open Analytics',
        icon: Icons.bar_chart_outlined,
        action: () {
          Navigator.of(context).pop();
          context.go('/analytics');
        },
      ),
      CommandPaletteItem(
        label: 'Open Finance',
        icon: Icons.account_balance_wallet,
        action: () {
          Navigator.of(context).pop();
          context.go('/finance');
        },
      ),
      CommandPaletteItem(
        label: 'Open Notifications',
        icon: Icons.notifications_outlined,
        action: () {
          Navigator.of(context).pop();
          context.go('/notifications');
        },
      ),
      CommandPaletteItem(
        label: 'Open Settings',
        icon: Icons.settings_outlined,
        action: () {
          Navigator.of(context).pop();
          context.go('/settings');
        },
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allCommands = _getCommands(context);
    final filtered = allCommands
        .where((cmd) => cmd.label.toLowerCase().contains(_filter.toLowerCase()))
        .toList();

    if (_selectedIndex >= filtered.length) {
      _selectedIndex = filtered.isNotEmpty ? filtered.length - 1 : 0;
    }

    final theme = Theme.of(context);

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            setState(() {
              if (filtered.isNotEmpty) {
                _selectedIndex = (_selectedIndex + 1) % filtered.length;
              }
            });
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            setState(() {
              if (filtered.isNotEmpty) {
                _selectedIndex =
                    (_selectedIndex - 1 + filtered.length) % filtered.length;
              }
            });
          } else if (event.logicalKey == LogicalKeyboardKey.enter) {
            if (filtered.isNotEmpty && _selectedIndex < filtered.length) {
              filtered[_selectedIndex].action();
            }
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Dialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.only(top: 80, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 550,
          constraints: const BoxConstraints(maxHeight: 450),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header input
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      '>',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _inputFocusNode,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Search or run a command...',
                          border: InputBorder.none,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _filter = val;
                            _selectedIndex = 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Commands list
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No matching commands',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isSelected = index == _selectedIndex;

                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: theme
                                .colorScheme
                                .primaryContainer
                                .withAlpha(80),
                            leading: Icon(
                              item.icon,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.iconTheme.color,
                            ),
                            title: Text(
                              item.label,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            onTap: item.action,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
