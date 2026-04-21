import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/shop_providers.dart';

class BrandLogo extends ConsumerWidget {
  final double size;
  final bool showText;
  final bool showSlogan;
  final Color? color;

  const BrandLogo({
    super.key,
    this.size = 40,
    this.showText = true,
    this.showSlogan = false,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(storeConfigProvider);
    final theme = Theme.of(context);
    
    return configAsync.maybeWhen(
      data: (config) {
        final storeName = config?.identity['storeName'] ?? 'NexaFlow';
        final storeSlogan = config?.identity['storeSlogan'];

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(size * 0.28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.shopping_bag_rounded,
                    color: Colors.white,
                    size: size * 0.6,
                  ),
                ),
                if (showText) ...[
                  const SizedBox(width: 12),
                  Text(
                    storeName,
                    style: TextStyle(
                      fontSize: size * 0.55,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: color ?? theme.textTheme.titleLarge?.color,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ],
            ),
            if (showSlogan && storeSlogan != null && storeSlogan.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(left: showText ? size + 12 : 0, top: 2),
                child: Text(
                  storeSlogan,
                  style: TextStyle(
                    fontSize: size * 0.28,
                    fontWeight: FontWeight.w500,
                    color: (color ?? theme.textTheme.titleLarge?.color)?.withOpacity(0.6),
                    fontFamily: 'Outfit',
                  ),
                ),
              ),
          ],
        );
      },
      orElse: () => _buildBasicLogo(context),
    );
  }

  Widget _buildBasicLogo(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Icon(Icons.shopping_bag_rounded, color: Colors.white, size: size * 0.6),
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          Text(
            'NexaFlow',
            style: TextStyle(
              fontSize: size * 0.55,
              fontWeight: FontWeight.w800,
              color: color ?? Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
        ],
      ],
    );
  }
}
