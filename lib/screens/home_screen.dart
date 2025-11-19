import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/recipe_service.dart';
import '../services/usage_service.dart';
import 'recipe_detail_screen.dart';
import 'subscription_screen.dart';

enum MealCategory { breakfast, lunch, dinner, dessert }

extension MealCategoryDetails on MealCategory {
  String get title {
    switch (this) {
      case MealCategory.breakfast:
        return 'Breakfast';
      case MealCategory.lunch:
        return 'Lunch';
      case MealCategory.dinner:
        return 'Dinner';
      case MealCategory.dessert:
        return 'Dessert';
    }
  }

  String get subtitle {
    switch (this) {
      case MealCategory.breakfast:
        return 'Fresh starts';
      case MealCategory.lunch:
        return 'Midday bites';
      case MealCategory.dinner:
        return 'Cozy evenings';
      case MealCategory.dessert:
        return 'Sweet treats';
    }
  }

  IconData get icon {
    switch (this) {
      case MealCategory.breakfast:
        return Icons.free_breakfast;
      case MealCategory.lunch:
        return Icons.lunch_dining;
      case MealCategory.dinner:
        return Icons.dinner_dining;
      case MealCategory.dessert:
        return Icons.icecream;
    }
  }

  List<Color> get gradient {
    switch (this) {
      case MealCategory.breakfast:
        return [Colors.orange.shade300, Colors.deepOrange.shade400];
      case MealCategory.lunch:
        return [Colors.teal.shade300, Colors.teal.shade600];
      case MealCategory.dinner:
        return [Colors.indigo.shade300, Colors.indigo.shade600];
      case MealCategory.dessert:
        return [Colors.pink.shade300, Colors.pink.shade500];
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  List<Recipe> _recipes = [];
  bool _isLoading = false;
  late TabController _tabController;
  final RecipeService _recipeService = RecipeService();
  MealCategory _selectedCategory = MealCategory.breakfast;
  int _categoryRequestId = 0;
  final Map<String, String> _moodFilters = const {
    'Comfort Food': 'pasta',
    'Quick Eats': 'quick',
    'High Protein': 'chicken',
    'Veggie Boost': 'vegetarian',
  };
  String? _activeFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategoryRecipes(_selectedCategory);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllRecipes() async {
    setState(() => _isLoading = true);
    try {
      final recipes = await _recipeService.getAllRecipes(maxPerCategory: 3);
      if (!mounted) return;
      setState(() => _recipes = recipes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded ${recipes.length} recipes from all categories!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _searchRecipes(String query) async {
    if (query.isEmpty) {
      await _loadCategoryRecipes(_selectedCategory);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final recipes = await _recipeService.searchRecipes(query);
      setState(() => _recipes = recipes);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyMoodFilter(String queryKey) async {
    setState(() => _activeFilter = queryKey);
    await _searchRecipes(queryKey);
  }

  Future<void> _loadRandomSpotlight() async {
    final randomCategory = MealCategory.values[Random().nextInt(MealCategory.values.length)];
    await _loadCategoryRecipes(randomCategory);
  }

  Future<void> _loadCategoryRecipes(MealCategory category) async {
    final requestId = ++_categoryRequestId;
    setState(() {
      _selectedCategory = category;
      _isLoading = true;
    });
    try {
      List<Recipe> recipes;
      switch (category) {
        case MealCategory.breakfast:
          recipes = await _recipeService.getBreakfastRecipes();
          break;
        case MealCategory.lunch:
          recipes = await _recipeService.getLunchRecipes();
          break;
        case MealCategory.dinner:
          recipes = await _recipeService.getDinnerRecipes();
          break;
        case MealCategory.dessert:
          recipes = await _recipeService.getDessertRecipes();
          break;
      }
      if (!mounted || requestId != _categoryRequestId) return;
      setState(() => _recipes = recipes);
    } finally {
      if (mounted && requestId == _categoryRequestId) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = Provider.of<UserModel?>(context);
    final isGuest = user?.isGuest ?? true;
    final isVIP = user?.isVIP ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Recipe Tadka'),
            if (isVIP) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade400, Colors.amber.shade700],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.workspace_premium, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'VIP',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (isGuest)
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Sign In'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepOrange,
              ),
            )
          else ...[
            if (!isVIP)
              IconButton(
                icon: const Icon(Icons.workspace_premium),
                color: Colors.amber,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen(),
                    ),
                  );
                },
                tooltip: 'Upgrade to VIP',
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadCategoryRecipes(_selectedCategory),
              tooltip: 'Refresh Recipes',
            ),
            IconButton(
              icon: const Icon(Icons.restaurant_menu),
              onPressed: _loadAllRecipes,
              tooltip: 'Load All Recipes',
            ),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => Navigator.pushNamed(context, '/profile'),
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Recipes', icon: Icon(Icons.restaurant)),
            Tab(text: 'VIP Premium', icon: Icon(Icons.workspace_premium)),
          ],
        ),
      ),
      drawer: _buildDrawer(context, authService, user, isGuest, isVIP),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecipeList(context, user, false),
          _buildRecipeList(context, user, true),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthService authService, UserModel? user, bool isGuest, bool isVIP) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(isGuest ? 'Guest User' : (user?.email ?? 'Welcome')),
            accountEmail: Text(isGuest ? 'Limited Access' : (user?.role ?? '')),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                isGuest ? Icons.person_outline : Icons.person,
                color: Colors.deepOrange,
                size: 40,
              ),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepOrange.shade400,
                  Colors.deepOrange.shade700,
                ],
              ),
            ),
          ),
          if (isGuest) ...[
            ListTile(
              leading: const Icon(Icons.login, color: Colors.deepOrange),
              title: const Text('Sign In to Unlock More'),
              subtitle: const Text('Get full access'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
            ),
            const Divider(),
          ],
          if (!isGuest) ...[
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              trailing: isVIP
                  ? const Icon(Icons.workspace_premium, color: Colors.amber)
                  : null,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            if (!isVIP)
              ListTile(
                leading: const Icon(Icons.workspace_premium, color: Colors.amber),
                title: const Text('Upgrade to VIP'),
                subtitle: const Text('Unlock all features'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen(),
                    ),
                  );
                },
              ),
          ],
          if (user?.role == 'vip' || user?.role == 'admin')
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('VIP Recipes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/vip');
              },
            ),
          if (user?.role == 'admin')
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin Panel'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin');
              },
            ),
          if (!isGuest) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                authService.signOut();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMealTemplates(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            'Cook by craving',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Tap a template to instantly load curated recipes.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final category = MealCategory.values[index];
              final isSelected = category == _selectedCategory;
              final colors = category.gradient;
              return SizedBox(
                width: 190,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _loadCategoryRecipes(category),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: colors.last.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: isSelected ? 0.9 : 0.4),
                        width: 1.4,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          category.icon,
                          color: Colors.white,
                          size: 32,
                        ),
                        const Spacer(),
                        Text(
                          category.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              isSelected ? 'Showing' : 'Explore',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: MealCategory.values.length,
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeList(BuildContext context, UserModel? user, bool isPremium) {
    final isGuest = user?.isGuest ?? true;
    final isVIP = user?.isVIP ?? false;
    
    // Limit recipes for guests
    final displayRecipes = isGuest && !isPremium
        ? (_recipes.length > 6 ? _recipes.sublist(0, 6) : _recipes)
        : _recipes;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeroBanner(context, isGuest, isVIP)),
        SliverToBoxAdapter(child: const SizedBox(height: 12)),
        SliverToBoxAdapter(child: _buildQuickShortcuts(context, isGuest, isVIP)),
        SliverToBoxAdapter(child: const SizedBox(height: 8)),
        SliverToBoxAdapter(child: _buildMoodFilters()),
        SliverToBoxAdapter(child: _buildMealTemplates(context)),
        SliverPadding(
          padding: const EdgeInsets.all(8.0),
          sliver: SliverToBoxAdapter(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for recipes',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchRecipes(_searchController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: _searchRecipes,
            ),
          ),
        ),
        if (isPremium && !isVIP)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade400, Colors.amber.shade700],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.lock, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'Premium Content Locked',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Upgrade to VIP to access exclusive recipes',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.amber.shade700,
                    ),
                    child: const Text('Upgrade Now'),
                  ),
                ],
              ),
            ),
          ),
        if (_isLoading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (displayRecipes.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No recipes found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try searching with different keywords',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _loadCategoryRecipes(_selectedCategory),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reload Recipes'),
                ),
              ],
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(8.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (isGuest && !isPremium && index == displayRecipes.length) {
                    return _buildUpgradeCard(context);
                  }

                  final recipe = displayRecipes[index];
                  final isLocked = isPremium && !isVIP;

                  return Hero(
                    tag: 'recipe_${recipe.id}',
                    child: GestureDetector(
                      onTap: () async {
                        // Always check the current user status from provider at tap time
                        final currentUser = Provider.of<UserModel?>(context, listen: false);
                        final usageService = Provider.of<UsageService>(context, listen: false);
                        final currentIsVIP = currentUser?.isVIP ?? false;
                        final currentIsGuest = currentUser?.isGuest ?? true;
                        
                        // If this is the premium tab and user is not VIP, show upgrade
                        if (isPremium && !currentIsVIP) {
                          if (currentIsGuest) {
                            Navigator.pushNamed(context, '/login');
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SubscriptionScreen(),
                              ),
                            );
                          }
                          return;
                        }

                        // User can view the recipe
                        if (currentIsVIP) {
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
                          // Check daily usage limit for non-VIP users
                          final canView = await usageService.canViewRecipe(currentUser);
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    currentIsGuest
                                        ? 'Daily limit reached (1/1). Sign in to view 3 recipes per day!'
                                        : 'Daily limit reached (3/3). Upgrade to VIP for unlimited access!',
                                  ),
                                  backgroundColor: Colors.deepOrange,
                                  action: SnackBarAction(
                                    label: currentIsGuest ? 'Sign In' : 'Upgrade',
                                    textColor: Colors.white,
                                    onPressed: () {
                                      if (currentIsGuest) {
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
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(
                                            recipe.imageUrl,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                          loadingProgress.expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
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
                                          if (isLocked)
                                            Container(
                                              color: Colors.black.withValues(alpha: 0.5),
                                              child: const Icon(
                                                Icons.lock,
                                                size: 48,
                                                color: Colors.white,
                                              ),
                                            ),
                                        ],
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
                              if (isPremium && isVIP)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.workspace_premium,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'VIP',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                childCount: displayRecipes.length + (isGuest && !isPremium ? 1 : 0),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUpgradeCard(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepOrange.shade400,
              Colors.deepOrange.shade700,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/login'),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.lock_open, size: 48, color: Colors.white),
              SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Sign in to unlock more recipes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, bool isGuest, bool isVIP) {
    final theme = Theme.of(context);
    final headline = isVIP ? 'Tonight\'s your chef\'s kiss' : 'Dinner plans? Sorted.';
    final sub =
        isVIP ? 'Jump back into premium feasts curated for you.' : 'Sign in or go VIP for unlimited culinary adventures.';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              Colors.deepOrange.shade400,
              Colors.pink.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sub,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (isGuest) {
                        Navigator.pushNamed(context, '/login');
                      } else if (!isVIP) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SubscriptionScreen(),
                          ),
                        );
                      } else {
                        _loadCategoryRecipes(_selectedCategory);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isGuest ? 'Sign in' : isVIP ? 'Cook now' : 'Go VIP'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.local_fire_department,
                size: 42,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickShortcuts(BuildContext context, bool isGuest, bool isVIP) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _ShortcutCard(
            icon: Icons.bolt,
            label: 'Spotlight',
            onTap: _loadRandomSpotlight,
          ),
          const SizedBox(width: 12),
          _ShortcutCard(
            icon: Icons.restaurant_menu,
            label: 'All Recipes',
            onTap: _loadAllRecipes,
          ),
          const SizedBox(width: 12),
          _ShortcutCard(
            icon: isGuest ? Icons.login : Icons.person,
            label: isGuest ? 'Sign In' : 'Profile',
            onTap: () {
              if (isGuest) {
                Navigator.pushNamed(context, '/login');
              } else {
                Navigator.pushNamed(context, '/profile');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMoodFilters() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _moodFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = _moodFilters.keys.elementAt(index);
          final query = _moodFilters.values.elementAt(index);
          final isSelected = _activeFilter == query;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => _applyMoodFilter(query),
            selectedColor: Colors.deepOrange.shade400,
            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.deepOrange),
            backgroundColor: Colors.deepOrange.shade50,
          );
        },
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.deepOrange),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}