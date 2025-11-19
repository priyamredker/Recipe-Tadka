import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUser(String uid, String email) async {
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'role': 'regular',
      'isVIP': false,
      'isGuest': false,
    });
  }

  Stream<UserModel?> getUser(String uid) {
    if (uid.isEmpty || uid == 'guest') {
      return Stream.value(UserModel.guest());
    }
    
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) => snapshot.exists ? UserModel.fromFirestore(snapshot) : null);
  }

  // Upgrade user to VIP
  Future<void> upgradeToVIP(String uid) async {
    if (uid.isEmpty || uid == 'guest') return;
    
    await _firestore.collection('users').doc(uid).update({
      'isVIP': true,
      'role': 'vip',
    });
  }

  // Check if user is VIP
  Future<bool> isUserVIP(String uid) async {
    if (uid.isEmpty || uid == 'guest') return false;
    
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return false;
    
    return doc.data()?['isVIP'] ?? false;
  }
}