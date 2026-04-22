import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../models/notification.dart';
import '../../features/auth/providers/auth_provider.dart';

class NotificationsNotifier extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final Ref ref;

  NotificationsNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      state = const AsyncValue.loading();
      final api = ref.read(apiClientProvider);
      final response = await api.get('/notifications');
      
      dynamic extractedData = response.data;
      List<dynamic> list = [];
      
      if (extractedData is Map) {
        // Double unwrap for standard API formats { data: { data: [] } }
        if (extractedData.containsKey('data')) {
          extractedData = extractedData['data'];
        }
        if (extractedData is Map && extractedData.containsKey('data')) {
          extractedData = extractedData['data'];
        } else if (extractedData is Map && extractedData.containsKey('items')) {
          extractedData = extractedData['items'];
        } else if (extractedData is Map && extractedData.containsKey('notifications')) {
          extractedData = extractedData['notifications'];
        }
      }

      if (extractedData is List) {
        list = extractedData;
      }

      final notifications = list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
      state = AsyncValue.data(notifications);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.patch('/notifications/$id/read');
      
      // Update local state
      if (state is AsyncData) {
        final currentList = state.value!;
        state = AsyncValue.data(currentList.map((n) {
          if (n.id == id) {
            return AppNotification(
              id: n.id,
              title: n.title,
              message: n.message,
              type: n.type,
              isRead: true,
              createdAt: n.createdAt,
              data: n.data,
            );
          }
          return n;
        }).toList());
      }
    } catch (e) {
      // Failed to mark as read
      print("Erreur markAsRead: $e");
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/notifications/mark-all-read');
      
      if (state is AsyncData) {
        final currentList = state.value!;
        state = AsyncValue.data(currentList.map((n) {
          return AppNotification(
            id: n.id,
            title: n.title,
            message: n.message,
            type: n.type,
            isRead: true,
            createdAt: n.createdAt,
            data: n.data,
          );
        }).toList());
      }
    } catch (e) {
      print("Erreur markAllAsRead: $e");
    }
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, AsyncValue<List<AppNotification>>>((ref) {
  return NotificationsNotifier(ref);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider);
  return notifs.when(
    data: (list) => list.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
