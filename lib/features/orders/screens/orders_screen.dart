import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nexaflow_mobile/core/api/shop_providers.dart';
import 'package:nexaflow_mobile/core/models/models.dart';
import 'order_detail_screen.dart';

// ── Status configuration ────────────────────────────────────────────
final _statusConfig = <String, Map<String, dynamic>>{
  'pending':    {'label': 'En attente',  'color': const Color(0xFFF59E0B), 'icon': Icons.schedule_outlined},
  'confirmed':  {'label': 'Confirmé',    'color': const Color(0xFF3B82F6), 'icon': Icons.check_circle_outline},
  'processing': {'label': 'En cours',    'color': const Color(0xFF8B5CF6), 'icon': Icons.autorenew_outlined},
  'shipped':    {'label': 'Expédié',     'color': const Color(0xFF06B6D4), 'icon': Icons.local_shipping_outlined},
  'delivered':  {'label': 'Livré',       'color': const Color(0xFF10B981), 'icon': Icons.done_all_outlined},
  'completed':  {'label': 'Terminé',     'color': const Color(0xFF10B981), 'icon': Icons.verified_outlined},
  'cancelled':  {'label': 'Annulé',      'color': const Color(0xFFEF4444), 'icon': Icons.cancel_outlined},
};

final _tabs = <Map<String, String>>[
  {'key': 'all',        'label': 'Toutes'},
  {'key': 'pending',    'label': 'En attente'},
  {'key': 'confirmed',  'label': 'Confirmées'},
  {'key': 'processing', 'label': 'En cours'},
  {'key': 'shipped',    'label': 'Expédiées'},
  {'key': 'delivered',  'label': 'Livrées'},
  {'key': 'cancelled',  'label': 'Annulées'},
];

String _fmtDate(String raw) {
  try {
    return DateFormat('dd MMM yyyy', 'fr_FR').format(DateTime.parse(raw).toLocal());
  } catch (_) {
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }
}

String _fmtAmount(double v) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0).format(v);

// ── Refreshable orders provider ──────────────────────────────────────
final _ordersRefreshProvider = StateProvider<int>((ref) => 0);

// ══════════════════════════════════════════════════════════════════════
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.read(_ordersRefreshProvider.notifier).state++;
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final _ = ref.watch(_ordersRefreshProvider); // trigger rebuild on refresh
    final ordersAsync = ref.watch(ordersProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = const Color(0xFF6366F1);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mes Commandes', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, size: 22),
            tooltip: 'Actualiser',
            onPressed: _refresh,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: ordersAsync.maybeWhen(
            data: (_) => TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: primary,
              labelColor: primary,
              unselectedLabelColor: Colors.grey,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              tabAlignment: TabAlignment.start,
              tabs: _tabs.map((t) => Tab(text: t['label'] as String)).toList(),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(error: e.toString(), onRetry: _refresh),
        data: (orders) {
          // ── Summary stats ─────────────────────────────────────
          final pending   = orders.where((o) => o.status == 'pending').length;
          final active    = orders.where((o) => ['confirmed','processing','shipped'].contains(o.status)).length;
          final delivered = orders.where((o) => ['delivered','completed'].contains(o.status)).length;

          return Column(
            children: [
              // Stats bar
              if (orders.isNotEmpty)
                _StatsBar(total: orders.length, pending: pending, active: active, delivered: delivered),

              // Tab views
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  color: primary,
                  child: TabBarView(
                    controller: _tabController,
                    children: _tabs.map((tab) {
                      final key = tab['key'] as String;
                      final filtered = key == 'all'
                          ? orders
                          : orders.where((o) => o.status == key).toList();
                      return _OrderList(orders: filtered, tabKey: key);
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Stats bar ────────────────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final int total, pending, active, delivered;
  const _StatsBar({required this.total, required this.pending, required this.active, required this.delivered});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          _Stat(value: total,     label: 'Total',    color: const Color(0xFF6366F1)),
          _divider(),
          _Stat(value: pending,   label: 'En attente', color: const Color(0xFFF59E0B)),
          _divider(),
          _Stat(value: active,    label: 'En cours',   color: const Color(0xFF3B82F6)),
          _divider(),
          _Stat(value: delivered, label: 'Livrées',    color: const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.25), margin: const EdgeInsets.symmetric(horizontal: 12));
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _Stat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text('$value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
      ],
    ),
  );
}

// ── Order list ───────────────────────────────────────────────────────
class _OrderList extends StatelessWidget {
  final List<Order> orders;
  final String tabKey;
  const _OrderList({required this.orders, required this.tabKey});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return _EmptyTab(tabKey: tabKey);

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _OrderCard(order: orders[i]),
    );
  }
}

// ── Order card ───────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cfg = _statusConfig[order.status] ?? _statusConfig['pending']!;
    final color = cfg['color'] as Color;
    final label = cfg['label'] as String;
    final icon = cfg['icon'] as IconData;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
          boxShadow: isDark ? [] : [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            // Top strip: order number + status badge
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 10),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.orderNumber,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(_fmtDate(order.createdAt),
                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: color.withOpacity(0.25)),
                    ),
                    child: Text(label,
                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100),

            // Products preview
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                children: [
                  ...order.items.take(2).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${item.productName} × ${item.quantity}',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(_fmtAmount(item.total),
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )),
                  if (order.items.length > 2)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('+ ${order.items.length - 2} autre(s) article(s)',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ),
                ],
              ),
            ),

            Divider(height: 20, indent: 16, endIndent: 16,
                color: isDark ? Colors.white10 : Colors.grey.shade100),

            // Bottom: total + arrow
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 14, 14),
              child: Row(
                children: [
                  Text('${order.items.length} article(s)',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const Spacer(),
                  Text(_fmtAmount(order.total),
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF6366F1))),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty tab ────────────────────────────────────────────────────────
class _EmptyTab extends StatelessWidget {
  final String tabKey;
  const _EmptyTab({required this.tabKey});

  @override
  Widget build(BuildContext context) {
    final isAll = tabKey == 'all';
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Container(
              height: constraints.maxHeight,
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isAll ? Icons.receipt_long_outlined : Icons.inbox_outlined,
                        size: 38, color: const Color(0xFF6366F1).withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isAll ? 'Aucune commande' : 'Aucune commande dans cet onglet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAll
                          ? 'Vos commandes apparaîtront ici dès que vous aurez effectué un achat.'
                          : 'Vous n\'avez pas de commandes avec ce statut pour le moment.',
                      style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }
    );
  }
}

// ── Error view ───────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Impossible de charger les commandes',
              style: TextStyle(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(error, style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            ),
          ),
        ],
      ),
    ),
  );
}
