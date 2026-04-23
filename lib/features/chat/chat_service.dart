import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:http_parser/http_parser.dart';
import '../../core/api/api_config.dart';
import '../../core/api/api_client.dart';

class ChatMessage {
  final String id;
  final String? content;
  final String senderType;
  final String senderId;
  final DateTime createdAt;
  final List<ChatAttachment>? attachments;

  ChatMessage({
    required this.id,
    this.content,
    required this.senderType,
    required this.senderId,
    required this.createdAt,
    this.attachments,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'],
      senderType: json['senderType'],
      senderId: json['senderId'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((a) => ChatAttachment.fromJson(a))
              .toList()
          : null,
    );
  }
}

class ChatAttachment {
  final String url;
  final String name;
  final String type;

  ChatAttachment({required this.url, required this.name, required this.type});

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      url: json['url'],
      name: json['name'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'name': name,
    'type': type,
  };
}

class ChatService {
  IO.Socket? _socket;
  final _storage = const FlutterSecureStorage();
  final ApiClient _apiClient;
  
  ChatService(this._apiClient);
  
  final _messageController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get messagesStream => _messageController.stream;

  String? _conversationId;
  String? get conversationId => _conversationId;

  Future<void> initChat(String customerName, String customerId, String customerEmail) async {
    try {
      // 1. Create/Get Conversation
      final response = await _apiClient.post('/chat/conversations', data: {
        'customerName': customerName,
        'customerId': customerId,
        'customerEmail': customerEmail,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        _conversationId = data['id'];
      }

      // 2. Initialiser Socket
      final token = await _storage.read(key: ApiConfig.tokenKey);
      final baseUrl = Uri.parse(ApiConfig.baseUrl).origin;

      _socket = IO.io(baseUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .disableAutoConnect()
        .build());

      _socket?.onConnect((_) {
        print('ChatService: Socket Connected! ID: ${_socket?.id}');
        if (_conversationId != null) {
          print('ChatService: Joining room: $_conversationId');
          _socket?.emit('joinConversation', {'conversationId': _conversationId});
        }
      });

      _socket?.onConnectError((err) => print('ChatService: Socket Connection Error: $err'));
      _socket?.onDisconnect((reason) => print('ChatService: Socket Disconnected: $reason'));

      _socket?.off('newMessage');
      _socket?.on('newMessage', (data) {
        try {
          print('ChatService: Received newMessage: $data');
          final message = ChatMessage.fromJson(data);
          _messageController.add(message);
        } catch (e) {
          print('ChatService: Error parsing newMessage: $e');
        }
      });

      // adminReply: server broadcasts this to ALL sockets when admin sends a message
      // This guarantees delivery even if this socket is not in the room
      _socket?.off('adminReply');
      _socket?.on('adminReply', (data) {
        try {
          print('ChatService: Received adminReply: $data');
          final convId = data['conversationId'] as String?;
          // Only process if it belongs to our conversation
          if (convId != null && convId == _conversationId) {
            final message = ChatMessage.fromJson(data['message']);
            _messageController.add(message);
          }
        } catch (e) {
          print('ChatService: Error parsing adminReply: $e');
        }
      });

      _socket?.connect();
    } catch (e) {
      print('ChatService Error: $e');
    }
  }

  Future<List<ChatMessage>> getHistory() async {
    if (_conversationId == null) return [];
    try {
      final response = await _apiClient.get('/chat/conversations/$_conversationId/messages');
      final List data = response.data['data'] ?? response.data;
      return data.map((m) => ChatMessage.fromJson(m)).toList();
    } catch (e) {
      return [];
    }
  }

  void sendMessage(String content, {List<ChatAttachment>? attachments}) {
    if (_socket == null) {
      print('ChatService: Socket is null!');
      return;
    }
    if (_conversationId == null) {
      print('ChatService: ConversationId is null!');
      return;
    }

    print('ChatService: Emitting sendMessage for conversation $_conversationId');
    _socket?.emit('sendMessage', {
      'conversationId': _conversationId,
      'content': content,
      'senderType': 'customer',
      'attachments': attachments?.map((a) => a.toJson()).toList(),
    });
  }

  Future<List<ChatAttachment>> uploadFiles(List<File> files) async {
    try {
      final formData = FormData();
      for (var file in files) {
        final fileName = p.basename(file.path);
        formData.files.add(MapEntry(
          'files',
          await MultipartFile.fromFile(
            file.path,
            filename: fileName,
            contentType: MediaType.parse(_getMimeType(fileName)),
          ),
        ));
      }

      final response = await _apiClient.post('/upload/files', data: formData);
      final List data = response.data['data']?['urls'] ?? response.data['urls'];
      
      return data.map((item) => ChatAttachment.fromJson(item)).toList();
    } catch (e) {
      print('Upload Error: $e');
      return [];
    }
  }

  String _getMimeType(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg': return 'image/jpeg';
      case '.png': return 'image/png';
      case '.pdf': return 'application/pdf';
      default: return 'application/octet-stream';
    }
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _messageController.close();
  }
}
