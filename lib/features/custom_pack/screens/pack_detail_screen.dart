import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexaflow_mobile/core/models/models.dart';

class PackDetailScreen extends StatelessWidget {
  final CustomPackRequest pack;
  const PackDetailScreen({super.key, required this.pack});

  String _formatAmount(double amount) {
    return NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0).format(amount);
  }

  Color _getStatusColor() {
    switch (pack.status) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'converted': return Colors.blue;
      default: return Colors.orange;
    }
  }

  String _getStatusLabel() {
    switch (pack.status) {
      case 'approved': return 'APPROUVÉ';
      case 'rejected': return 'REFUSÉ';
      case 'converted': return 'TRANSFORMÉ EN COMMANDE';
      default: return 'EN ATTENTE D\'EXAMEN';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF6366F1);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Détail du Pack', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getStatusColor().withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _getStatusColor(), shape: BoxShape.circle),
                    child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Demande #${pack.id.substring(0, 8).toUpperCase()}', 
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(_getStatusLabel(), 
                          style: TextStyle(color: _getStatusColor(), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pricing Summary Card
            _buildSectionHeader('Résumé financier'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                   _buildPriceRow('Sous-total initial', _formatAmount(pack.originalTotal), isGrey: true),
                   const SizedBox(height: 12),
                   _buildPriceRow('Remise appliquée', '- ${_formatAmount(pack.savings)}', 
                      isSuccess: true, badge: pack.discountType == 'percentage' ? '-${pack.discountValue.toInt()}%' : null),
                   const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
                   _buildPriceRow('Total du pack', _formatAmount(pack.discountedTotal), isBold: true, color: primaryColor),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Products List
            _buildSectionHeader('Articles du pack (${pack.items.length})'),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pack.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = pack.items[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 60, width: 60,
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                        child: item.image != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(item.image!, fit: BoxFit.cover))
                            : const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('${item.quantity} × ${_formatAmount(item.unitPrice)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(_formatAmount(item.unitPrice * item.quantity), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Notes Section
            if ((pack.customerNote != null && pack.customerNote!.isNotEmpty) || (pack.adminNote != null && pack.adminNote!.isNotEmpty)) ...[
              _buildSectionHeader('Notes & Observations'),
              const SizedBox(height: 12),
              if (pack.customerNote != null && pack.customerNote!.isNotEmpty)
                _buildNoteCard('Votre note', pack.customerNote!, Icons.person_pin_outlined, Colors.blue),
              if (pack.adminNote != null && pack.adminNote!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildNoteCard('Note de l\'administrateur', pack.adminNote!, Icons.admin_panel_settings_outlined, Colors.purple),
              ],
              const SizedBox(height: 32),
            ],

            // Footer info
            Center(
              child: Text(
                'Demande créée le ${DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(DateTime.parse(pack.createdAt))}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5, color: Colors.grey)),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isGrey = false, bool isSuccess = false, bool isBold = false, Color? color, String? badge}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(color: isGrey ? Colors.grey : (isBold ? null : Colors.grey.shade700), fontWeight: isBold ? FontWeight.bold : null)),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(badge, style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        Text(value, style: TextStyle(
          fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
          fontSize: isBold ? 20 : 14,
          color: color ?? (isSuccess ? Colors.green : null),
        )),
      ],
    );
  }

  Widget _buildNoteCard(String title, String content, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }
}
