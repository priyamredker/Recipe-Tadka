import 'package:flutter/material.dart';

class VipUpsellScreen extends StatelessWidget {
  const VipUpsellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Go VIP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upgrade to VIP',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            const Text('VIP gets you:'),
            const SizedBox(height: 8),
            const ListTile(
              leading: Icon(Icons.star),
              title: Text('Access to exclusive premium recipes'),
            ),
            const ListTile(
              leading: Icon(Icons.no_adult_content_outlined),
              title: Text('Ad-free cooking experience'),
            ),
            const ListTile(
              leading: Icon(Icons.favorite),
              title: Text('Unlimited favourites & collections'),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Get VIP'),
                      content: const Text(
                          'In this mini project, VIP is activated when an Admin toggles your account to premium in the Admin Panel.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Get VIP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
