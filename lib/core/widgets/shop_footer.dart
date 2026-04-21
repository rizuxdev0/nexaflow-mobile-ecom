import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/shop_providers.dart';
import 'brand_logo.dart';

class ShopFooter extends ConsumerWidget {
  const ShopFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(storeConfigProvider);
    final theme = Theme.of(context);

    return configAsync.maybeWhen(
      data: (config) {
        if (config == null) return const SizedBox();
        
        final identity = config.identity;
        final storeSlogan = identity['storeSlogan'] ?? '';
        final contactEmail = identity['contactEmail'] ?? '';
        final contactPhone = identity['contactPhone'] ?? '';
        final social = identity['socialLinks'] as Map<String, dynamic>? ?? {};

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            children: [
              const BrandLogo(size: 32, showSlogan: true),
              const SizedBox(height: 20),
              if (storeSlogan.isNotEmpty)
                Text(
                  storeSlogan,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: 30),
              
              // Contact Section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (contactPhone.isNotEmpty)
                    _ContactItem(icon: Icons.phone_outlined, label: contactPhone),
                  const SizedBox(width: 20),
                  if (contactEmail.isNotEmpty)
                    _ContactItem(icon: Icons.email_outlined, label: contactEmail),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Social Section
              if (social.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (social['facebook']?.isNotEmpty == true) _SocialIcon(icon: Icons.facebook, url: social['facebook']),
                    if (social['instagram']?.isNotEmpty == true) _SocialIcon(icon: Icons.camera_alt_outlined, url: social['instagram']),
                    if (social['twitter']?.isNotEmpty == true) _SocialIcon(icon: Icons.close, url: social['twitter']),
                    if (social['whatsapp']?.isNotEmpty == true) _SocialIcon(icon: Icons.chat_bubble_outline, url: social['whatsapp']),
                  ],
                ),
              
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 20),
              
              // Copyright
              Text(
                '© ${DateTime.now().year} ${identity['storeName'] ?? 'NexaFlow'}. Tous droits réservés.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
      orElse: () => const SizedBox(),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ContactItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6366F1)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final String url;
  const _SocialIcon({required this.icon, required this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF1E293B)),
      ),
    );
  }
}
