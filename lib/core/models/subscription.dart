class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String period; // monthly, yearly
  final List<String> features;
  final bool isPopular;
  final String? badge;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.period,
    required this.features,
    this.isPopular = false,
    this.badge,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num? ?? 0).toDouble(),
      period: json['period'] as String? ?? 'monthly',
      features: (json['features'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isPopular: json['isPopular'] as bool? ?? false,
      badge: json['badge'] as String?,
    );
  }
}

class UserSubscription {
  final String id;
  final String planId;
  final String planName;
  final String status; // active, expired, cancelled
  final String startDate;
  final String endDate;

  UserSubscription({
    required this.id,
    required this.planId,
    required this.planName,
    required this.status,
    required this.startDate,
    required this.endDate,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      planId: json['planId'] as String? ?? '',
      planName: json['planName'] as String? ?? 'Plan',
      status: json['status'] as String? ?? 'active',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
    );
  }
}
