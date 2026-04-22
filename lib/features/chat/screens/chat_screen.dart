import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import '../chat_provider.dart';
import '../chat_service.dart';
import '../widgets/chat_bubble.dart';
import '../../auth/providers/auth_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isUploading = false;
  bool _hasText = false;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    _focusNode.addListener(() {
      // When keyboard appears, hide emoji picker
      if (_focusNode.hasFocus && _showEmojiPicker) {
        setState(() => _showEmojiPicker = false);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatMessagesProvider.notifier).initChat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      // Closing emoji picker → show keyboard
      setState(() => _showEmojiPicker = false);
      _focusNode.requestFocus();
    } else {
      // Opening emoji picker → hide keyboard
      _focusNode.unfocus();
      setState(() => _showEmojiPicker = true);
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    if (animated) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() => _isUploading = true);
      try {
        final files =
            result.paths.where((p) => p != null).map((p) => File(p!)).toList();
        await ref.read(chatMessagesProvider.notifier).sendFiles(files);
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  void _handleSend() {
    if (_controller.text.trim().isEmpty) return;
    ref
        .read(chatMessagesProvider.notifier)
        .sendMessage(_controller.text.trim());
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final customer = ref.watch(authProvider).customer;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listen(chatMessagesProvider, (prev, next) {
      if ((next.length) > (prev?.length ?? 0)) {
        Future.delayed(const Duration(milliseconds: 80), _scrollToBottom);
      }
    });

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0E1621) : const Color(0xFFE8EDF3),
      appBar: _buildAppBar(context, isDark),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState(context)
                : _buildMessageList(messages, customer?.id, isDark),
          ),
          _buildInputArea(isDark),
          // Emoji picker panel
          if (_showEmojiPicker)
            _buildEmojiPicker(isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: isDark
          ? const Color(0xFF17212B)
          : const Color(0xFF6366F1),
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      leadingWidth: 40,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.maybePop(context),
        color: Colors.white,
      ),
      title: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.support_agent_rounded,
                    color: Colors.white, size: 22),
              ),
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isDark
                            ? const Color(0xFF17212B)
                            : const Color(0xFF6366F1),
                        width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Support NexaFlow',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80), shape: BoxShape.circle),
                  ),
                  const Text('En ligne',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone_outlined, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 56, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: 20),
          const Text('Commencez une conversation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Notre équipe de support est là pour vous aider.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(
      List<ChatMessage> messages, String? customerId, bool isDark) {
    final items = <_ChatListItem>[];
    DateTime? lastDate;

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final msgDay =
          DateTime(msg.createdAt.year, msg.createdAt.month, msg.createdAt.day);

      if (lastDate == null || lastDate != msgDay) {
        items.add(_ChatListItem.separator(msg.createdAt));
        lastDate = msgDay;
      }

      final isMe =
          msg.senderId == customerId || msg.senderType == 'customer';
      final isLast = i == messages.length - 1 ||
          _isFromDifferentSender(messages[i], messages[i + 1], customerId);

      items.add(_ChatListItem.message(msg, isMe, isLast));
    }

    return GestureDetector(
      onTap: () {
        // Tap on list → hide emoji picker and keyboard
        if (_showEmojiPicker) setState(() => _showEmojiPicker = false);
        _focusNode.unfocus();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item.isSeparator) {
            return ChatDateSeparator(date: item.date!);
          }
          return ChatBubble(
            message: item.message!,
            isMe: item.isMe!,
            showTail: item.showTail!,
          );
        },
      ),
    );
  }

  bool _isFromDifferentSender(
      ChatMessage a, ChatMessage b, String? customerId) {
    final aIsMe = a.senderId == customerId || a.senderType == 'customer';
    final bIsMe = b.senderId == customerId || b.senderType == 'customer';
    return aIsMe != bIsMe;
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17212B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attach button
            _InputIconButton(
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.attach_file_rounded,
                      color: Colors.grey.shade500, size: 22),
              onTap: _isUploading ? null : _pickFiles,
            ),

            // Text field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF242F3D)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: 'Écrivez un message...',
                    hintStyle: TextStyle(
                        color: Colors.grey.shade500, fontSize: 15),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),

            // Emoji toggle button (always visible)
            AnimatedRotation(
              turns: _showEmojiPicker ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: _InputIconButton(
                icon: Icon(
                  _showEmojiPicker
                      ? Icons.keyboard_rounded
                      : Icons.sentiment_satisfied_alt_rounded,
                  color: _showEmojiPicker
                      ? const Color(0xFF6366F1)
                      : Colors.grey.shade500,
                  size: 24,
                ),
                onTap: _toggleEmojiPicker,
              ),
            ),

            // Send button (only when has text)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: _hasText
                  ? _SendButton(
                      key: const ValueKey('send'), onTap: _handleSend)
                  : const SizedBox(key: ValueKey('empty'), width: 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPicker(bool isDark) {
    return SizedBox(
      height: 280,
      child: EmojiPicker(
        textEditingController: _controller,
        scrollController: ScrollController(),
        config: Config(
          locale: const Locale('fr'),
          height: 280,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            emojiSizeMax: 28 *
                (foundation.defaultTargetPlatform == TargetPlatform.iOS
                    ? 1.2
                    : 1.0),
            backgroundColor:
                isDark ? const Color(0xFF17212B) : const Color(0xFFF8FAFC),
            columns: 8,
          ),
          skinToneConfig: const SkinToneConfig(),
          categoryViewConfig: CategoryViewConfig(
            iconColorSelected: const Color(0xFF6366F1),
            indicatorColor: const Color(0xFF6366F1),
            backgroundColor:
                isDark ? const Color(0xFF17212B) : const Color(0xFFF8FAFC),
          ),
          bottomActionBarConfig: BottomActionBarConfig(
            backgroundColor:
                isDark ? const Color(0xFF17212B) : Colors.white,
            buttonColor: const Color(0xFF6366F1),
          ),
          searchViewConfig: SearchViewConfig(
            backgroundColor:
                isDark ? const Color(0xFF242F3D) : Colors.white,
            buttonIconColor: const Color(0xFF6366F1),
          ),
        ),
        onEmojiSelected: (category, emoji) {
          // emoji_picker_flutter inserts directly via controller
          // but we update the hasText state manually
          setState(() => _hasText = _controller.text.trim().isNotEmpty);
        },
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SendButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

class _InputIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  const _InputIconButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: icon,
      ),
    );
  }
}

class _ChatListItem {
  final bool isSeparator;
  final DateTime? date;
  final ChatMessage? message;
  final bool? isMe;
  final bool? showTail;

  const _ChatListItem._({
    required this.isSeparator,
    this.date,
    this.message,
    this.isMe,
    this.showTail,
  });

  factory _ChatListItem.separator(DateTime date) =>
      _ChatListItem._(isSeparator: true, date: date);

  factory _ChatListItem.message(ChatMessage msg, bool isMe, bool showTail) =>
      _ChatListItem._(
        isSeparator: false,
        message: msg,
        isMe: isMe,
        showTail: showTail,
      );
}
