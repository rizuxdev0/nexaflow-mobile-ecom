import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/cart/providers/cart_provider.dart';
import 'core/api/global_message_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  final String location;
  const MainShell({super.key, required this.child, required this.location});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _routes = ['/', '/catalogue', '/chat', '/cart', '/compte'];
  static const _labels = ['Accueil', 'Catalogue', 'Chat', 'Panier', 'Compte'];
  static const _icons = [
    Icons.home_outlined,
    Icons.grid_view_outlined,
    Icons.chat_bubble_outline_rounded,
    Icons.shopping_cart_outlined,
    Icons.person_outline,
  ];
  static const _activeIcons = [
    Icons.home_rounded,
    Icons.grid_view_rounded,
    Icons.chat_bubble_rounded,
    Icons.shopping_cart_rounded,
    Icons.person_rounded,
  ];

  int _calculateSelectedIndex(String location) {
    if (location == '/') return 0;
    if (location.startsWith('/catalogue')) return 1;
    if (location.startsWith('/chat')) return 2;
    if (location.startsWith('/cart')) return 3;
    if (location.startsWith('/compte')) return 4;
    return 0; // Default to home
  }

  void _onTap(int idx, BuildContext context) {
    // Protected tabs: Chat (2) and Account (4)
    if (idx == 2 || idx == 4) {
      final isAuth = ref.read(authProvider).isAuthenticated;
      if (!isAuth) {
        context.push('/connexion');
        return;
      }
    }
    context.go(_routes[idx]);
  }

  @override
  Widget build(BuildContext context) {
    final _currentIndex = _calculateSelectedIndex(widget.location);
    final cartCount = ref.watch(cartProvider).itemCount;
    final theme = Theme.of(context);

    // Listen for global error messages (timeouts, connection issues)
    ref.listen<GlobalMessage?>(globalMessageProvider, (previous, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  next.isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(next.message)),
              ],
            ),
            backgroundColor: next.isError ? Colors.red.shade700 : Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
        // Clear the state after showing
        Future.microtask(() => ref.read(globalMessageProvider.notifier).state = null);
      }
    });

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => _onTap(idx, context),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: List.generate(_routes.length, (idx) {
            final isCart = idx == 3;
            return NavigationDestination(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(_icons[idx]),
                  if (isCart && cartCount > 0)
                    Positioned(
                      right: -8, top: -8,
                      child: Container(
                        width: 18, height: 18,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6366F1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ],
              ),
              selectedIcon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(_activeIcons[idx]),
                  if (isCart && cartCount > 0)
                    Positioned(
                      right: -8, top: -8,
                      child: Container(
                        width: 18, height: 18,
                        decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                        child: Center(child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                      ),
                    ),
                ],
              ),
              label: _labels[idx],
            );
          }),
        ),
      ),
    );
  }
}
