class ParticipantModel {
  final String uid;
  final String fullName;
  final String role; // 'admin', 'dj', 'listener'
  final DateTime joinedAt;

  const ParticipantModel({
    required this.uid,
    required this.fullName,
    required this.role,
    required this.joinedAt,
  });

  factory ParticipantModel.fromMap(Map<String, dynamic> map, String uid) {
    return ParticipantModel(
      uid: uid,
      fullName: map['fullName'] ?? 'Unknown',
      role: map['role'] ?? 'listener',
      joinedAt: map['joinedAt'] != null
          ? (map['joinedAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'role': role,
      'joinedAt': joinedAt,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isDJ => role == 'dj' || role == 'admin';
}