import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../models/user.dart';
import '../services/recipe_service.dart';
import '../services/usage_service.dart';
import 'recipe_detail_screen.dart';
import 'subscription_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _recipeService = RecipeService();
  List<String> _categories = [];
  List<String> _areas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndAreas();
  }

  Future<void> _loadCategoriesAndAreas() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _recipeService.getAllCategories();
      final areas = await _recipeService.getAllAreas();
      setState(() {
        _categories = categories;
        _areas = areas;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Browse Recipes'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Categories', icon: Icon(Icons.category)),
              Tab(text: 'Cuisines', icon: Icon(Icons.public)),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildCategoryGrid(_categories, true),
                  _buildCategoryGrid(_areas, false),
                ],
              ),
      ),
    );
  }

  Widget _buildCategoryGrid(List<String> items, bool isCategory) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No items available'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryRecipesScreen(
                    title: item,
                    isCategory: isCategory,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepOrange.shade300,
                    Colors.deepOrange.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CategoryRecipesScreen extends StatefulWidget {
  final String title;
  final bool isCategory;

  const CategoryRecipesScreen({
    super.key,
    required this.title,
    required this.isCategory,
  });

  @override
  State<CategoryRecipesScreen> createState() => _CategoryRecipesScreenState();
}

class _CategoryRecipesScreenState extends State<CategoryRecipesScreen> {
  final _recipeService = RecipeService();
  List<Recipe> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
    try {
      final recipes = widget.isCategory
          ? await _recipeService.getRecipesByCategory(widget.title)
          : await _recipeService.getRecipesByArea(widget.title);
      setState(() => _recipes = recipes);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipes.isEmpty
              ? const Center(
                  child: Text('No recipes found'),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = _recipes[index];
                    return Hero(
                      tag: 'recipe_${recipe.id}_${widget.title}',
                      child: GestureDetector(
                        onTap: () async {
                          // Check usage limit for both guests and regular users (VIP has unlimited access)
                          final user = Provider.of<UserModel?>(context, listen: false);
                          final usageService = Provider.of<UsageService>(context, listen: false);
                          
                          if (user?.isVIP ?? false) {
                            // VIP users have unlimited access
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RecipeDetailScreen(recipe: recipe),
                                ),
                              );
                            }
                          } else {
                            final canView = await usageService.canViewRecipe(user);
                            if (canView) {
                              // Navigate to recipe detail (view will be recorded there)
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RecipeDetailScreen(recipe: recipe),
                                  ),
                                );
                              }
                            } else {
                              // Show limit reached message
                              if (context.mounted) {
                                final isGuest = user?.isGuest ?? true;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isGuest
                                          ? 'Daily limit reached (1/1). Sign in to view 3 recipes per day!'
                                          : 'Daily limit reached (3/3). Upgrade to VIP for unlimited access!',
                                    ),
                                    backgroundColor: Colors.deepOrange,
                                    action: SnackBarAction(
                                      label: isGuest ? 'Sign In' : 'Upgrade',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        if (isGuest) {
                                          Navigator.pushNamed(context, '/login');
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const SubscriptionScreen(),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    recipe.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade300,
                                        child: Icon(
                                          Icons.restaurant,
                                          size: 48,
                                          color: Colors.grey.shade500,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  recipe.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
