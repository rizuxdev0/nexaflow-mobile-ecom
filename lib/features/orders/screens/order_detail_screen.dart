import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:nexaflow_mobile/core/models/models.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  // ── Status config ──────────────────────────────────────────
  static final _statusConfig = <String, Map<String, dynamic>>{
    'pending':    {'label': 'En attente',  'icon': Icons.schedule_outlined,       'color': const Color(0xFFF59E0B)},
    'confirmed':  {'label': 'Confirmé',    'icon': Icons.check_circle_outline,     'color': const Color(0xFF3B82F6)},
    'processing': {'label': 'En cours',    'icon': Icons.autorenew_outlined,       'color': const Color(0xFF8B5CF6)},
    'shipped':    {'label': 'Expédié',     'icon': Icons.local_shipping_outlined,  'color': const Color(0xFF06B6D4)},
    'delivered':  {'label': 'Livré',       'icon': Icons.done_all_outlined,        'color': const Color(0xFF10B981)},
    'completed':  {'label': 'Terminé',     'icon': Icons.verified_outlined,        'color': const Color(0xFF10B981)},
    'cancelled':  {'label': 'Annulé',      'icon': Icons.cancel_outlined,          'color': const Color(0xFFEF4444)},
  };

  // ── Timeline steps ─────────────────────────────────────────
  static const _timeline = ['pending', 'confirmed', 'processing', 'shipped', 'delivered'];

  int _currentStep(String status) {
    if (status == 'cancelled') return -1;
    return _timeline.indexOf(status);
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat("dd MMM yyyy 'à' HH:mm", 'fr_FR').format(dt);
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }

  String _formatAmount(double v) =>
      NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0).format(v);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cfg = _statusConfig[order.status] ?? _statusConfig['pending']!;
    final statusColor = cfg['color'] as Color;
    final statusLabel = cfg['label'] as String;
    final statusIcon = cfg['icon'] as IconData;
    final currentStep = _currentStep(order.status);
    final isCancelled = order.status == 'cancelled';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Status Hero Card ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor.withOpacity(0.15), statusColor.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(statusLabel, style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800,
                          color: statusColor,
                        )),
                        const SizedBox(height: 4),
                        Text('Passée le ${_formatDate(order.createdAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(statusLabel,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Timeline (only if not cancelled) ─────────────────
            if (!isCancelled) ...[
              _sectionTitle(context, 'Suivi de commande'),
              const SizedBox(height: 12),
              _buildTimeline(context, currentStep, theme, isDark),
              const SizedBox(height: 20),
            ],

            // ── Order Items ──────────────────────────────────────
            _sectionTitle(context, 'Articles commandés'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Column(
                children: order.items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            // Product image or placeholder
                            Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
                              ),
                              child: item.productImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(item.productImage!, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_outlined, color: Color(0xFF6366F1))),
                                    )
                                  : const Icon(Icons.shopping_bag_outlined, color: Color(0xFF6366F1)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.productName,
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                      maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text('${item.quantity}×', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                      const SizedBox(width: 4),
                                      Text(_formatAmount(item.unitPrice),
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(_formatAmount(item.total),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF6366F1))),
                          ],
                        ),
                      ),
                      if (i < order.items.length - 1)
                        Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── Price Summary ────────────────────────────────────
            _sectionTitle(context, 'Récapitulatif'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _priceRow(context, 'Sous-total', _formatAmount(order.subtotal)),
                  if (order.deliveryFee != null) ...[
                    const SizedBox(height: 8),
                    _priceRow(context, 'Livraison', _formatAmount(order.deliveryFee!)),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      Text(_formatAmount(order.total),
                          style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800,
                            color: Color(0xFF6366F1),
                          )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Extra Info ───────────────────────────────────────
            if (order.paymentMethod != null || order.deliveryAddress != null || order.notes != null) ...[
              _sectionTitle(context, 'Informations'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    if (order.paymentMethod != null)
                      _infoRow(context, Icons.payment_outlined, 'Paiement', order.paymentMethod!),
                    if (order.deliveryAddress != null) ...[
                      if (order.paymentMethod != null) const SizedBox(height: 10),
                      _infoRow(context, Icons.location_on_outlined, 'Adresse', order.deliveryAddress!),
                    ],
                    if (order.notes != null) ...[
                      const SizedBox(height: 10),
                      _infoRow(context, Icons.notes_outlined, 'Note', order.notes!),
                    ],
                  ],
                ),
              ),
            ],

            // ── Return Button (only if delivered/completed) ──────────
            if (['delivered', 'completed'].contains(order.status)) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push('/returns/new', extra: order);
                  },
                  icon: const Icon(Icons.assignment_return_rounded, color: Colors.orange),
                  label: const Text('Signaler un problème / Retour', 
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Timeline widget ──────────────────────────────────────────
  Widget _buildTimeline(BuildContext context, int currentStep, ThemeData theme, bool isDark) {
    final steps = <Map<String, dynamic>>[
      {'label': 'Reçue',      'icon': Icons.receipt_outlined},
      {'label': 'Confirmée',  'icon': Icons.check_circle_outline},
      {'label': 'En cours',   'icon': Icons.autorenew_outlined},
      {'label': 'Expédiée',   'icon': Icons.local_shipping_outlined},
      {'label': 'Livrée',     'icon': Icons.done_all_outlined},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIndex = i ~/ 2;
            final done = stepIndex < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: done ? const Color(0xFF10B981) : Colors.grey.shade300,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final done = stepIndex < currentStep;
          final active = stepIndex == currentStep;
          final icon = steps[stepIndex]['icon'] as IconData;
          final label = steps[stepIndex]['label'] as String;
          final color = done || active ? const Color(0xFF10B981) : Colors.grey.shade400;

          return Column(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: done ? const Color(0xFF10B981) : active ? const Color(0xFF10B981).withOpacity(0.15) : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: done || active ? 2 : 1),
                ),
                child: Icon(icon,
                    size: 16,
                    color: done ? Colors.white : color),
              ),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color),
                  textAlign: TextAlign.center),
            ],
          );
        }),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Text(
    title,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    ),
  );

  Widget _priceRow(BuildContext context, String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
      Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
    ],
  );

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: const Color(0xFF6366F1)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ],
  );
}
