import 'package:flutter/material.dart';
import '../services/recipe_api_service.dart';
import '../screens/vip_upsell_screen.dart';

class RecipeList extends StatelessWidget {
  final bool isVIP;
  const RecipeList({super.key, required this.isVIP});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Recipe>>(
      future: RecipeApiService.fetchRecipes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading recipes'));
        }
        final recipes = snapshot.data ?? [];
        if (recipes.isEmpty) {
          return const Center(child: Text('No recipes found.'));
        }

        return ListView.builder(
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final r = recipes[index];
            final locked = r.isPremium && !isVIP;

            return Card(
              margin: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    r.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(r.title),
                subtitle: locked
                    ? const Text('VIP-only recipe – Upgrade to view')
                    : const Text('Tap to see recipe details'),
                trailing: locked
                    ? const Icon(Icons.lock)
                    : const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  if (locked) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const VipUpsellScreen()),
                    );
                  } else {
                    // You can make a RecipeDetailScreen if needed
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
