import 'package:flutter/foundation.dart';

class LoyaltyTierConfig {
  final String tier;
  final int minPoints;
  final double multiplier;
  final List<String> perks;
  final String color;
  final String icon;

  LoyaltyTierConfig({
    required this.tier,
    required this.minPoints,
    required this.multiplier,
    required this.perks,
    required this.color,
    required this.icon,
  });

  factory LoyaltyTierConfig.fromJson(Map<String, dynamic> json) {
    return LoyaltyTierConfig(
      tier: json['tier'] ?? '',
      minPoints: json['minPoints'] ?? 0,
      multiplier: (json['multiplier'] ?? 1.0).toDouble(),
      perks: List<String>.from(json['perks'] ?? []),
      color: json['color'] ?? '',
      icon: json['icon'] ?? '',
    );
  }
}

class LoyaltyReward {
  final String id;
  final String name;
  final String description;
  final int pointsCost;
  final String type;
  final String value;
  final int stock;

  LoyaltyReward({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsCost,
    required this.type,
    required this.value,
    required this.stock,
  });

  factory LoyaltyReward.fromJson(Map<String, dynamic> json) {
    return LoyaltyReward(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      pointsCost: json['pointsCost'] ?? 0,
      type: json['type'] ?? '',
      value: json['value'] ?? '',
      stock: json['stock'] ?? 0,
    );
  }
}

class LoyaltyTransaction {
  final String id;
  final String description;
  final int points;
  final String type;
  final DateTime createdAt;

  LoyaltyTransaction({
    required this.id,
    required this.description,
    required this.points,
    required this.type,
    required this.createdAt,
  });

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransaction(
      id: json['id'] ?? '',
      description: json['description'] ?? '',
      points: json['points'] ?? 0,
      type: json['type'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

class LoyaltyConfigData {
  static final List<LoyaltyTierConfig> tiers = [
    LoyaltyTierConfig(tier: 'bronze', minPoints: 0, multiplier: 1, perks: ['Accès aux promotions membres', 'Newsletter exclusive'], color: 'from-amber-600 to-amber-800', icon: '🥉'),
    LoyaltyTierConfig(tier: 'silver', minPoints: 500, multiplier: 1.5, perks: ['Livraison gratuite dès 30 000 FCFA', 'Remise anniversaire 5%', 'Accès ventes privées'], color: 'from-gray-400 to-gray-600', icon: '🥈'),
    LoyaltyTierConfig(tier: 'gold', minPoints: 2000, multiplier: 2, perks: ['Livraison gratuite illimitée', 'Remise anniversaire 10%', 'Service client prioritaire', 'Accès avant-premières'], color: 'from-yellow-400 to-yellow-600', icon: '🥇'),
    LoyaltyTierConfig(tier: 'platinum', minPoints: 5000, multiplier: 3, perks: ['Tout Gold +', 'Personal shopper', 'Retours gratuits 60 jours', 'Événements VIP exclusifs', 'Remise permanente 5%'], color: 'from-purple-400 to-purple-700', icon: '💎'),
  ];

  static LoyaltyTierConfig getTier(int points) {
    var sorted = List<LoyaltyTierConfig>.from(tiers)..sort((a, b) => b.minPoints.compareTo(a.minPoints));
    return sorted.firstWhere((t) => points >= t.minPoints, orElse: () => tiers[0]);
  }

  static LoyaltyTierConfig? getNextTier(int points) {
    final currentTier = getTier(points);
    final idx = tiers.indexWhere((t) => t.tier == currentTier.tier);
    return (idx < tiers.length - 1) ? tiers[idx + 1] : null;
  }
}
