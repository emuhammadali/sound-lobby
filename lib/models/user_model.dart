class UserModel {
  final String uid;
  final String fullName;
  final String email;

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
    };
  }
}