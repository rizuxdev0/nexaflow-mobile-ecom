import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/return_providers.dart';
import '../widgets/return_card.dart';

class ReturnHistoryScreen extends ConsumerWidget {
  const ReturnHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final returnsAsync = ref.watch(returnHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Retours'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(returnHistoryProvider.future),
        child: returnsAsync.when(
          data: (returns) {
            if (returns.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_return_outlined, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucun retour déclaré',
                      style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Vous pouvez demander un retour depuis l\'historique de vos commandes livrées.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: returns.length,
              itemBuilder: (context, index) {
                return ReturnCard(returnRequest: returns[index]);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text('Erreur: $err'),
          ),
        ),
      ),
    );
  }
}
