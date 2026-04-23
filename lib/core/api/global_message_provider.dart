import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlobalMessage {
  final String message;
  final bool isError;
  final DateTime timestamp;

  GlobalMessage({
    required this.message, 
    this.isError = true,
  }) : timestamp = DateTime.now();
}

final globalMessageProvider = StateProvider<GlobalMessage?>((ref) => null);
