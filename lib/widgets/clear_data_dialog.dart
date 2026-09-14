import 'package:flutter/material.dart';

class ClearDataDialog extends StatefulWidget {
  final String title;
  final String description;
  final String affectedItemsText;
  final bool requireDeleteText;
  final VoidCallback onConfirm;

  const ClearDataDialog({
    super.key,
    required this.title,
    required this.description,
    required this.affectedItemsText,
    this.requireDeleteText = false,
    required this.onConfirm,
  });

  @override
  State<ClearDataDialog> createState() => _ClearDataDialogState();
}

class _ClearDataDialogState extends State<ClearDataDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    if (!widget.requireDeleteText) {
      _canConfirm = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.delete_forever_rounded, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.title)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.description),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Affected Data:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.affectedItemsText,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            if (widget.requireDeleteText) ...[
              const SizedBox(height: 16),
              const Text(
                'Type DELETE to confirm:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'DELETE',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (val) {
                  setState(() {
                    _canConfirm = val.trim() == 'DELETE';
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: _canConfirm
              ? () {
                  Navigator.of(context).pop();
                  widget.onConfirm();
                }
              : null,
          child: const Text('Delete Data'),
        ),
      ],
    );
  }
}
