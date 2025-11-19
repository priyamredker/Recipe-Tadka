import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../models/user.dart';
import '../services/recipe_service.dart';
import '../widgets/recipe_image.dart';
import 'recipe_detail_screen.dart';
import 'subscription_screen.dart';

class VipScreen extends StatefulWidget {
  const VipScreen({super.key});

  @override
  State<VipScreen> createState() => _VipScreenState();
}

class _VipScreenState extends State<VipScreen> {
  final RecipeService _recipeService = RecipeService();
  bool _isLoading = true;
  List<Recipe> _premiumRecipes = [];
  List<Recipe> _favoriteRecipes = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _isLoading = true);
    final premium = await _recipeService.searchRecipes('premium');
    final favorites = await _recipeService.getDiscoveryFeed(desiredCount: 6);
    setState(() {
      _premiumRecipes = premium;
      _favoriteRecipes = favorites;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel?>();
    if (user == null || !user.isVIP) {
      return const _VipLockedView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('VIP Recipes'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _init,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionHeader(
                    title: 'Premium Recipes',
                    subtitle: 'Exclusive chef collaborations updated weekly.',
                    icon: Icons.workspace_premium,
                  ),
                  _buildCarousel(_premiumRecipes),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    title: 'Unlimited Favorites',
                    subtitle: 'Handpicked suggestions to bookmark.',
                    icon: Icons.favorite,
                  ),
                  _buildCarousel(_favoriteRecipes, isFavoriteMode: true),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.deepOrange),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  Widget _buildCarousel(
    List<Recipe> recipes, {
    bool showPlayIcon = false,
    bool isFavoriteMode = false,
  }) {
    if (recipes.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('Fresh VIP items are loading...'),
      );
    }

    return SizedBox(
      height: 230,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.7),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12, top: 12),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: RecipeImage(
                        imageUrl: recipe.imageUrl,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  recipe.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (showPlayIcon)
                                const Icon(Icons.play_circle, color: Colors.deepOrange),
                              if (isFavoriteMode)
                                IconButton(
                                  icon: const Icon(Icons.favorite, color: Colors.deepOrange),
                                  onPressed: () {},
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${recipe.ingredients.length} premium ingredients',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VipLockedView extends StatelessWidget {
  const _VipLockedView();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel?>();
    final isGuest = user?.isGuest ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('VIP Recipes')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This section is for VIP members only.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (isGuest) {
                  Navigator.pushReplacementNamed(context, '/login');
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                  );
                }
              },
              child: Text(isGuest ? 'Sign In to Continue' : 'Upgrade to VIP'),
            ),
          ],
        ),
      ),
    );
  }
}

