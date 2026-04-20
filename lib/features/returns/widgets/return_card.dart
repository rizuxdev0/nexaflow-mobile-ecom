import 'package:flutter/material.dart';
import '../../../core/models/returns.dart';
import 'package:intl/intl.dart';

class ReturnCard extends StatelessWidget {
  final ProductReturn returnRequest;
  final VoidCallback? onTap;

  const ReturnCard({
    super.key,
    required this.returnRequest,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final statusColor = _getStatusColor(returnRequest.status);
    final statusLabel = _getStatusLabel(returnRequest.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Retour #${returnRequest.returnNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _StatusBadge(label: statusLabel, color: statusColor),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Commande #${returnRequest.orderNumber}'),
            const SizedBox(height: 4),
            Text(
              '${returnRequest.items.length} article(s) • ${DateFormat('dd/MM/yyyy').format(DateTime.parse(returnRequest.createdAt))}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Motif: ${returnRequest.reason.label}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Color _getStatusColor(ReturnStatus status) {
    switch (status) {
      case ReturnStatus.pending: return Colors.orange;
      case ReturnStatus.approved: return Colors.blue;
      case ReturnStatus.refunded: return Colors.green;
      case ReturnStatus.exchanged: return Colors.purple;
      case ReturnStatus.rejected: return Colors.red;
    }
  }

  String _getStatusLabel(ReturnStatus status) {
    switch (status) {
      case ReturnStatus.pending: return 'En attente';
      case ReturnStatus.approved: return 'Approuvé';
      case ReturnStatus.refunded: return 'Remboursé';
      case ReturnStatus.exchanged: return 'Échangé';
      case ReturnStatus.rejected: return 'Refusé';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
