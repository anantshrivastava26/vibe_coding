class DisasterAlert {
  final int id;
  final String severity;
  final String message;
  final DateTime createdAt;
  final String category;
  final String title;
  final String? description;
  final double latitude;
  final double longitude;
  final DateTime occurredAt;

  DisasterAlert({
    required this.id,
    required this.severity,
    required this.message,
    required this.createdAt,
    required this.category,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.occurredAt,
  });

  factory DisasterAlert.fromJson(Map<String, dynamic> json) {
    return DisasterAlert(
      id: json['id'] as int,
      severity: json['severity'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      category: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      occurredAt: DateTime.parse(json['occurred_at'] as String),
    );
  }
}
