class UserProfile {
  final int id;
  final String firebaseUid;
  final String email;
  final String? displayName;
  final String role;
  final double? latitude;
  final double? longitude;
  final String? locationLabel;

  UserProfile({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.latitude,
    required this.longitude,
    required this.locationLabel,
  });

  bool get isAdmin => role == 'admin';
  bool get hasLocation => latitude != null && longitude != null;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      firebaseUid: json['firebase_uid'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      role: json['role'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationLabel: json['location_label'] as String?,
    );
  }
}
