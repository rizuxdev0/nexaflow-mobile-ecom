import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../providers/custom_pack_provider.dart';

class PackHistoryScreen extends ConsumerWidget {
  const PackHistoryScreen({super.key});

  String _formatAmount(double amount) {
    return NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(packHistoryProvider);
    final primaryColor = const Color(0xFF6366F1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Packs'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(packHistoryProvider.notifier).fetchHistory(),
          ),
        ],
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
        data: (requests) => requests.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_edu, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('Aucune demande trouvée', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text('Vos demandes de packs apparaîtront ici.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final pack = requests[index];
                  
                  final Color statusColor = pack.status == 'approved' ? Colors.green : 
                                      pack.status == 'rejected' ? Colors.red :
                                      pack.status == 'converted' ? Colors.blue : 
                                      Colors.orange;
                                      
                  final String statusLabel = pack.status == 'approved' ? 'Approuvé' :
                                       pack.status == 'rejected' ? 'Refusé' :
                                       pack.status == 'converted' ? 'Commandé' :
                                       'En attente';

                  return GestureDetector(
                    onTap: () => context.push('/pack-detail/${pack.id}', extra: pack),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          if (Theme.of(context).brightness == Brightness.light)
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Demande #${pack.id.substring(0, 8).toUpperCase()}', 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(statusLabel, 
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(pack.createdAt)), 
                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const Divider(height: 24),
                          ...pack.items.take(2).map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Text('${item.quantity}×', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                Text(_formatAmount(item.unitPrice * item.quantity), style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )),
                          if (pack.items.length > 2)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text('+ ${pack.items.length - 2} autres articles...', style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                            ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total estimé', style: TextStyle(color: Colors.grey)),
                              Text(_formatAmount(pack.discountedTotal), 
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: primaryColor)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Center(child: Text('Appuyez pour voir le détail', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
