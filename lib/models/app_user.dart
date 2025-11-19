class AppUser {
  final String uid;
  final String email;
  final String role; // "user" or "admin"
  final bool premium;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.premium,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      premium: data['premium'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'premium': premium,
      'updatedAt': DateTime.now(),
    };
  }
}
