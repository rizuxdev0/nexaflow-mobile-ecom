import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../chat_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'dart:io';

class ChatDateSeparator extends StatelessWidget {
  final DateTime date;
  const ChatDateSeparator({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDay = DateTime(date.year, date.month, date.day);

    String label;
    if (msgDay == today) {
      label = "Aujourd'hui";
    } else if (msgDay == yesterday) {
      label = 'Hier';
    } else {
      label = DateFormat('d MMMM yyyy', 'fr').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300, endIndent: 12)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300, indent: 12)),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showTail;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showTail = true,
  });

  static const _myColor = Color(0xFF6366F1);
  static const _theirColor = Color(0xFFEEEFF4);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theirBubbleColor = isDark ? const Color(0xFF2A2A3C) : _theirColor;

    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 60 : 8,
        right: isMe ? 8 : 60,
        top: 2,
        bottom: showTail ? 6 : 2,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            if (showTail)
              _SupportAvatar()
            else
              const SizedBox(width: 34),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: _BubbleBody(
              message: message,
              isMe: isMe,
              showTail: showTail,
              bubbleColor: isMe ? _myColor : theirBubbleColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.support_agent_rounded, size: 16, color: Colors.white),
    );
  }
}

class _BubbleBody extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showTail;
  final Color bubbleColor;

  const _BubbleBody({
    required this.message,
    required this.isMe,
    required this.showTail,
    required this.bubbleColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasOnlyImage = message.content == null || message.content!.trim().isEmpty;
    final hasAttachments = message.attachments != null && message.attachments!.isNotEmpty;

    return CustomPaint(
      painter: _BubbleTailPainter(isMe: isMe, showTail: showTail, color: bubbleColor),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : (showTail ? 4 : 18)),
            bottomRight: Radius.circular(isMe ? (showTail ? 4 : 18) : 18),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : (showTail ? 4 : 18)),
            bottomRight: Radius.circular(isMe ? (showTail ? 4 : 18) : 18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hasAttachments)
                _buildAttachments(context),
              if (!hasOnlyImage)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    hasAttachments ? 6 : 10,
                    12,
                    4,
                  ),
                  child: Text(
                    message.content!,
                    style: TextStyle(
                      color: isMe ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 8, 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(message.createdAt),
                      style: TextStyle(
                        color: isMe ? Colors.white60 : Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.done_all_rounded, size: 14, color: Colors.white60),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachments(BuildContext context) {
    return Column(
      children: message.attachments!.map((a) => _AttachmentWidget(
        attachment: a,
        isMe: isMe,
      )).toList(),
    );
  }
}

class _AttachmentWidget extends StatelessWidget {
  final ChatAttachment attachment;
  final bool isMe;
  const _AttachmentWidget({required this.attachment, required this.isMe});

  bool get _isImage => attachment.type.startsWith('image/');

  @override
  Widget build(BuildContext context) {
    if (_isImage) {
      return GestureDetector(
        onTap: () => _showFullScreenImage(context, attachment.url),
        child: CachedNetworkImage(
          imageUrl: attachment.url,
          width: 260,
          height: 200,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: 260, height: 200,
            color: Colors.grey.shade200,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
        ),
      );
    }

    // File card
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isMe ? Colors.white24 : const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.insert_drive_file_rounded,
              color: isMe ? Colors.white : const Color(0xFF6366F1), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isMe ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  attachment.type.split('/').last.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe ? Colors.white60 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.download_rounded,
              size: 20, color: isMe ? Colors.white70 : const Color(0xFF6366F1)),
            onPressed: () => _downloadFile(context, attachment),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFile(BuildContext context, ChatAttachment attachment) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Téléchargement de ${attachment.name}...')),
      );
      final dio = Dio();
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/${attachment.name}';
      await dio.download(attachment.url, savePath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enregistré : ${attachment.name}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      _openUrl(attachment.url);
    }
  }

  void _showFullScreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
            Positioned(
              top: 48,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Custom painter for the Telegram-style bubble tail
class _BubbleTailPainter extends CustomPainter {
  final bool isMe;
  final bool showTail;
  final Color color;

  _BubbleTailPainter({
    required this.isMe,
    required this.showTail,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showTail) return;

    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();

    if (isMe) {
      // Right tail
      path.moveTo(size.width, size.height - 18);
      path.lineTo(size.width + 8, size.height - 4);
      path.lineTo(size.width - 2, size.height - 6);
      path.close();
    } else {
      // Left tail
      path.moveTo(0, size.height - 18);
      path.lineTo(-8, size.height - 4);
      path.lineTo(2, size.height - 6);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter old) =>
      old.isMe != isMe || old.showTail != showTail || old.color != color;
}
