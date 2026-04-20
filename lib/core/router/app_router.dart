import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/catalogue/screens/catalogue_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/product/screens/product_detail_screen.dart';
import '../../features/account/screens/account_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/compare/screens/compare_screen.dart';
import '../../features/custom_pack/screens/custom_pack_screen.dart';
import '../../features/custom_pack/screens/pack_history_screen.dart';
import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/wishlist/screens/wishlist_screen.dart';
import '../../features/returns/screens/returns_history_screen.dart';
import '../../features/returns/screens/return_request_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/help/screens/help_screen.dart';
import 'package:nexaflow_mobile/features/vendor/screens/become_vendor_screen.dart';
import 'package:nexaflow_mobile/features/vendor/screens/pricing_screen.dart';
import 'package:nexaflow_mobile/features/vendor/screens/subscription_checkout_screen.dart';
import '../../main_shell.dart';
import '../../core/models/models.dart';
import 'package:nexaflow_mobile/core/models/subscription.dart';

GoRouter buildRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      // Don't protect the splash screen
      if (state.matchedLocation == '/splash') return null;
      
      final auth = ref.read(authProvider);
      if (auth.isLoading) return null;
      // Protected routes
      final protectedPaths = ['/checkout', '/compte', '/commandes', '/chat', '/custom-pack', '/pack-history', '/returns', '/become-vendor', '/subscription/checkout'];
      final isProtected = protectedPaths.any((p) => state.matchedLocation.startsWith(p));
      if (isProtected && !auth.isAuthenticated) return '/connexion';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/catalogue', builder: (_, __) => const CatalogueScreen()),
          GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
          GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
          GoRoute(path: '/compte', builder: (_, __) => const AccountScreen()),
          GoRoute(path: '/help', name: 'help', builder: (_, __) => const HelpScreen()),
        ],
      ),
      GoRoute(path: '/connexion', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/product/:id', builder: (_, state) => ProductDetailScreen(productId: state.pathParameters['id']!)),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(path: '/commandes', builder: (_, __) => const OrdersScreen()),
      GoRoute(path: '/returns', builder: (_, __) => const ReturnHistoryScreen()),
      GoRoute(path: '/returns/new', builder: (_, state) => ReturnRequestScreen(order: state.extra as Order)),
      GoRoute(path: '/favoris', builder: (_, __) => const WishlistScreen()),
      GoRoute(path: '/compare', builder: (_, __) => const CompareScreen()),
      GoRoute(path: '/custom-pack', builder: (_, __) => const CustomPackScreen()),
      GoRoute(path: '/pack-history', builder: (_, __) => const PackHistoryScreen()),
      GoRoute(path: '/become-vendor', builder: (_, __) => const BecomeVendorScreen()),
      GoRoute(path: '/pricing', builder: (_, __) => const PricingScreen()),
      GoRoute(
        path: '/subscription/checkout',
        builder: (context, state) => SubscriptionCheckoutScreen(plan: state.extra as SubscriptionPlan),
      ),
    ],
  );
}
