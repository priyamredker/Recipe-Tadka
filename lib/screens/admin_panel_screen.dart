import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _searchController = TextEditingController();
  DocumentSnapshot<Map<String, dynamic>>? _searchedUser;
  bool _loadingUser = false;

  Future<void> _searchUser() async {
    setState(() => _loadingUser = true);
    final email = _searchController.text.trim();
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    setState(() {
      _searchedUser = query.docs.isNotEmpty ? query.docs.first : null;
      _loadingUser = false;
    });
  }

  Future<void> _togglePremium(bool premium) async {
    if (_searchedUser == null) return;
    final userDoc = _searchedUser!;
    final uid = userDoc.id;
    final email = userDoc['email'];

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'premium': premium,
      'updatedAt': DateTime.now(),
    });

    // audit log
    if (!mounted) return;
    final adminUid =
        Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    await FirebaseFirestore.instance.collection('audit_logs').add({
      'actorUid': adminUid,
      'action': premium ? 'SET_PREMIUM_TRUE' : 'SET_PREMIUM_FALSE',
      'target': email,
      'timestamp': DateTime.now(),
    });

    await _searchUser(); // refresh card
  }

  Future<void> _toggleFeatureFlag(String key, bool value) async {
    final docRef =
        FirebaseFirestore.instance.collection('app_config').doc('prod');
    await docRef.set({
      'features': {key: value}
    }, SetOptions(merge: true));

    if (!mounted) return;
    final adminUid =
        Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    await FirebaseFirestore.instance.collection('audit_logs').add({
      'actorUid': adminUid,
      'action': 'TOGGLE_FEATURE_$key',
      'target': 'app_config/prod',
      'timestamp': DateTime.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final isAdmin = auth.isAdmin;

    if (!isAdmin) {
      // required for "Admin Panel hidden for non-admin" test
      return const Scaffold(
        body: Center(child: Text('Unauthorized')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('User Management',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search user by email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loadingUser ? null : _searchUser,
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loadingUser) const Center(child: CircularProgressIndicator()),
            if (!_loadingUser && _searchedUser != null) _buildUserCard(),

            const Divider(height: 32),
            Text('Feature Flags',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('app_config')
                  .doc('prod')
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text('Loading config...');
                }
                final data = snapshot.data!.data() ?? {};
                final features =
                    Map<String, dynamic>.from(data['features'] ?? {});
                final newUI = features['newUI'] ?? true;

                return SwitchListTile(
                  title: const Text('New UI'),
                  value: newUI,
                  onChanged: (val) => _toggleFeatureFlag('newUI', val),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    final data = _searchedUser!.data()!;
    final email = data['email'];
    final premium = data['premium'] ?? false;

    return Card(
      child: ListTile(
        title: Text(email),
        subtitle: Text('Premium: $premium'),
        trailing: Switch(
          value: premium,
          onChanged: (val) => _togglePremium(val),
        ),
      ),
    );
  }
}
