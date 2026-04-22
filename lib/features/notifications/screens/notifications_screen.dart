import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/notification_providers.dart';
import 'package:intl/intl.dart' as intl;

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
        actions: [
          TextButton(
            onPressed: () {
              ref.read(notificationsProvider.notifier).markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tout marqué comme lu')));
            },
            child: const Text('Tout marquer comme lu', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text('Aucune notification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Vous êtes à jour dans vos alertes.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(notificationsProvider.notifier).fetchNotifications();
            },
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                
                IconData icon;
                Color color;
                switch (notif.type) {
                  case 'order':
                    icon = Icons.shopping_bag_outlined;
                    color = const Color(0xFF6366F1);
                    break;
                  case 'promo':
                    icon = Icons.local_offer_outlined;
                    color = Colors.pink;
                    break;
                  case 'alert':
                    icon = Icons.warning_amber_rounded;
                    color = Colors.orange;
                    break;
                  default:
                    icon = Icons.notifications_active_outlined;
                    color = Colors.blue;
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  tileColor: notif.isRead ? Colors.transparent : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFF6366F1).withOpacity(0.05)),
                  leading: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      if (!notif.isRead)
                        Positioned(
                          right: 0, top: 0,
                          child: Container(
                            width: 12, height: 12,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    notif.title,
                    style: TextStyle(fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w900, fontSize: 15),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif.message,
                          style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          intl.DateFormat('dd MMM yyyy, HH:mm', 'fr').format(notif.createdAt),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    if (!notif.isRead) {
                      ref.read(notificationsProvider.notifier).markAsRead(notif.id);
                    }
                    // Implement any navigation logic based on notif.type if needed
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(
          child: Text('Erreur: $e', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}
