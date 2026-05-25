class Institute {
  final String id;
  final String name;
  final String? contactEmail;
  final String? logo;
  final String subscriptionPlan;
  final DateTime? subscriptionExpiresAt;
  final Map<String, dynamic> features;
  final String status;

  Institute({
    required this.id,
    required this.name,
    this.contactEmail,
    this.logo,
    required this.subscriptionPlan,
    this.subscriptionExpiresAt,
    required this.features,
    required this.status,
  });

  factory Institute.fromJson(Map<String, dynamic> json) {
    return Institute(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      contactEmail: json['contactEmail'],
      logo: json['logo'],
      subscriptionPlan: json['subscriptionPlan'] ?? 'Free',
      subscriptionExpiresAt: json['subscriptionExpiresAt'] != null 
          ? DateTime.parse(json['subscriptionExpiresAt']) 
          : null,
      features: json['features'] ?? {},
      status: json['status'] ?? 'active',
    );
  }

  bool get isExpired {
    if (subscriptionExpiresAt == null) return false;
    return subscriptionExpiresAt!.isBefore(DateTime.now());
  }

  int get maxTutors => features['maxTutors'] ?? 0;
  int get maxStudents => features['maxStudents'] ?? 0;
  int get storageLimitGB => features['storageLimitGB'] ?? 0;
  int get aiCreditsPerMonth => features['aiCreditsPerMonth'] ?? 0;
}
