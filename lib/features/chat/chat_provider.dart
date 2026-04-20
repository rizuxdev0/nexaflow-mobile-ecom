import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexaflow_mobile/features/chat/chat_service.dart';
import 'package:nexaflow_mobile/features/auth/providers/auth_provider.dart';
import 'package:nexaflow_mobile/core/services/notification_service.dart';
import 'package:nexaflow_mobile/features/settings/settings_provider.dart';

final chatServiceProvider = Provider((ref) => ChatService());

final chatMessagesProvider = StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>((ref) {
  final service = ref.watch(chatServiceProvider);
  return ChatMessagesNotifier(service, ref);
});

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  final ChatService _service;
  final Ref _ref;

  ChatMessagesNotifier(this._service, this._ref) : super([]) {
    _service.messagesStream.listen((message) {
      print('ChatMessagesNotifier: New message from stream: ${message.id}');
      
      // If it's a real message from me, check if we have a matching temp message
      if (message.senderType == 'customer') {
        final tempIndex = state.indexWhere((m) => m.id.startsWith('temp_') && m.content == message.content);
        if (tempIndex != -1) {
          final newState = List<ChatMessage>.from(state);
          newState[tempIndex] = message; // Replace temp with real
          state = newState;
          print('ChatMessagesNotifier: Reconciled temp message with real ID: ${message.id}');
          return;
        }
      }

      if (!state.any((m) => m.id == message.id)) {
        state = [...state, message];
        print('ChatMessagesNotifier: State updated. Total: ${state.length}');

        // Detect if it's a message from support to show notification
        final settings = _ref.read(settingsProvider);
        if (message.senderType != 'customer' && settings.notificationsEnabled) {
          NotificationService().showNotification(
            id: message.id.hashCode,
            title: 'Support NexaFlow',
            body: (message.content == null || message.content!.isEmpty) && (message.attachments?.isNotEmpty ?? false)
                ? '📄 Pièce jointe reçue'
                : (message.content ?? ''),
            payload: 'chat',
          );
        }
      }
    });
  }

  Future<void> initChat() async {
    print('ChatMessagesNotifier: Initializing chat...');
    final customer = _ref.read(authProvider).customer;
    if (customer == null) {
      print('ChatMessagesNotifier: No customer found in authProvider');
      return;
    }

    print('ChatMessagesNotifier: Customer found: ${customer.id}');
    await _service.initChat(
      '${customer.firstName} ${customer.lastName}',
      customer.id,
      customer.email,
    );

    final history = await _service.getHistory();
    print('ChatMessagesNotifier: Loaded ${history.length} messages from history');
    state = history;
  }

  void sendMessage(String content) {
    print('ChatMessagesNotifier: Sending message: $content');
    final customer = _ref.read(authProvider).customer;
    if (customer == null) return;

    // Add message optimistically to the UI
    final tempMessage = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      senderType: 'customer',
      senderId: customer.id,
      createdAt: DateTime.now(),
    );
    
    state = [...state, tempMessage];
    print('ChatMessagesNotifier: Added optimistic message to state');
    
    _service.sendMessage(content);
  }

  Future<void> sendFiles(List<File> files) async {
    final attachments = await _service.uploadFiles(files);
    if (attachments.isNotEmpty) {
      _service.sendMessage("", attachments: attachments);
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
