import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexaflow_mobile/core/models/models.dart';
import 'package:intl/intl.dart';
import '../providers/compare_provider.dart';

class CompareScreen extends ConsumerWidget {
  const CompareScreen({super.key});

  String _formatAmount(double amount) {
    return NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparedProducts = ref.watch(compareProvider);
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF6366F1);

    if (comparedProducts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Comparateur')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.compare_arrows, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Aucun produit à comparer',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Sélectionnez jusqu\'à 3 produits dans le catalogue.', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparateur'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => ref.read(compareProvider.notifier).clearGroup(),
            child: const Text('Tout vider', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(160),
              border: TableBorder(
                horizontalInside: BorderSide(color: Colors.grey.withOpacity(0.2)),
                verticalInside: BorderSide(color: Colors.grey.withOpacity(0.2)),
                bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              children: [
                // Headers & Removes
                TableRow(
                  children: [
                    const Padding(padding: EdgeInsets.all(8.0), child: Text('Produit', style: TextStyle(fontWeight: FontWeight.bold))),
                    ...comparedProducts.map((p) => Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 100,
                                width: double.infinity,
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                child: p.mainImage != null
                                    ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(p.mainImage!, fit: BoxFit.cover))
                                    : const Icon(Icons.image_not_supported, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        Positioned(
                          right: -5,
                          top: -5,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => ref.read(compareProvider.notifier).removeProduct(p.id),
                          ),
                        ),
                      ],
                    )),
                  ],
                ),
                // Prix
                TableRow(
                  children: [
                    const Padding(padding: EdgeInsets.all(12), child: Text('Prix', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
                    ...comparedProducts.map((p) => Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_formatAmount(p.price), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    )),
                  ],
                ),
                // Marque
                TableRow(
                  children: [
                    const Padding(padding: EdgeInsets.all(12), child: Text('Marque', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
                    ...comparedProducts.map((p) => Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(p.brand ?? '-', style: const TextStyle(fontWeight: FontWeight.w500)),
                    )),
                  ],
                ),
                // En stock
                TableRow(
                  children: [
                    const Padding(padding: EdgeInsets.all(12), child: Text('Disponibilité', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
                    ...comparedProducts.map((p) => Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(p.stock > 0 ? Icons.check_circle : Icons.cancel, color: p.stock > 0 ? Colors.green : Colors.red, size: 16),
                          const SizedBox(width: 4),
                          Text(p.stock > 0 ? '${p.stock} sec' : 'Rupture', style: TextStyle(color: p.stock > 0 ? Colors.green : Colors.red, fontSize: 13)),
                        ],
                      ),
                    )),
                  ],
                ),
                // Tags
                TableRow(
                  children: [
                    const Padding(padding: EdgeInsets.all(12), child: Text('Tags', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
                    ...comparedProducts.map((p) => Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: p.tags.map((t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                          child: Text(t, style: const TextStyle(fontSize: 10)),
                        )).toList(),
                      ),
                    )),
                  ],
                ),
                // Description courte
                TableRow(
                  children: [
                    const Padding(padding: EdgeInsets.all(12), child: Text('Description', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
                    ...comparedProducts.map((p) => Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(p.shortDescription ?? p.description, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
