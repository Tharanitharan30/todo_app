import 'package:flutter/material.dart';

import '../services/backup_service.dart';

class CsvImportDialog extends StatelessWidget {
  final CsvImportPreview preview;
  final VoidCallback onConfirmImport;

  const CsvImportDialog({
    super.key,
    required this.preview,
    required this.onConfirmImport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.file_upload_outlined, color: Colors.blue),
          const SizedBox(width: 8),
          Text('Import ${preview.type.toUpperCase()} CSV'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Parsed CSV rows for ${preview.type}:'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildRow('Total Rows Found', '${preview.totalRows}', Colors.black),
                const Divider(),
                _buildRow('Valid Rows', '${preview.validRows}', Colors.green),
                const Divider(),
                _buildRow('Invalid / Skipped', '${preview.invalidRows}',
                    preview.invalidRows > 0 ? Colors.red : Colors.grey),
              ],
            ),
          ),
          if (preview.validRows == 0) ...[
            const SizedBox(height: 12),
            const Text(
              'No valid rows found to import. Please check your CSV column headers.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: preview.validRows > 0
              ? () {
                  Navigator.of(context).pop();
                  onConfirmImport();
                }
              : null,
          child: Text('Import ${preview.validRows} Valid Rows'),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
