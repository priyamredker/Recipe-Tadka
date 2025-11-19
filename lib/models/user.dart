import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role; // 'regular', 'vip', 'admin'
  final bool isVIP;
  final bool isGuest;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.isVIP = false,
    this.isGuest = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'regular',
      isVIP: data['isVIP'] ?? false,
      isGuest: data['isGuest'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'role': role,
      'isVIP': isVIP,
      'isGuest': isGuest,
    };
  }

  // Create a guest user
  factory UserModel.guest() {
    return UserModel(
      uid: 'guest',
      email: 'guest@recipetadka.com',
      role: 'regular',
      isVIP: false,
      isGuest: true,
    );
  }
}