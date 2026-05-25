class SubscriptionPlan {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String currency;
  final String billingCycle; // monthly, yearly, etc.
  final Map<String, dynamic> features;
  final bool isActive;

  SubscriptionPlan({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.currency,
    required this.billingCycle,
    required this.features,
    required this.isActive,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'INR',
      billingCycle: json['billingCycle'] ?? 'monthly',
      features: json['features'] ?? {},
      isActive: json['isActive'] ?? true,
    );
  }
}
