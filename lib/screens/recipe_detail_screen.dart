import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../models/user.dart';
import '../services/usage_service.dart';
import '../services/recipe_download_service.dart';
import '../widgets/recipe_image.dart';
import 'login_screen.dart';
import 'subscription_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _canViewRecipe = true;
  bool _checkingLimit = true;
  bool _isDownloaded = false;
  bool _isDownloading = false;
  final RecipeDownloadService _downloadService = RecipeDownloadService();

  @override
  void initState() {
    super.initState();
    _checkUsageLimit();
    _checkIfDownloaded();
  }

  Future<void> _checkIfDownloaded() async {
    final isDownloaded = await _downloadService.isRecipeDownloaded(widget.recipe.id);
    if (mounted) {
      setState(() => _isDownloaded = isDownloaded);
    }
  }

  Future<void> _toggleDownload() async {
    setState(() => _isDownloading = true);
    
    try {
      if (_isDownloaded) {
        await _downloadService.removeDownloadedRecipe(widget.recipe.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recipe removed from downloads')),
          );
        }
      } else {
        await _downloadService.downloadRecipe(widget.recipe);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recipe downloaded for offline access! 📱')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
        await _checkIfDownloaded();
      }
    }
  }

  Future<void> _checkUsageLimit() async {
    final user = Provider.of<UserModel?>(context, listen: false);
    final usageService = Provider.of<UsageService>(context, listen: false);
    
    // Check limits for both guests and regular users (VIP has unlimited access)
    if (user?.isVIP ?? false) {
      if (mounted) {
        setState(() {
          _canViewRecipe = true;
          _checkingLimit = false;
        });
      }
    } else {
      final canView = await usageService.canViewRecipe(user);
      if (canView) {
        // Record the view if user can view the recipe
        await usageService.recordRecipeView(user);
      }
      if (mounted) {
        setState(() {
          _canViewRecipe = canView;
          _checkingLimit = false;
        });
      }
    }
  }

  Future<void> _recordViewAndNavigateToLogin() async {
    final user = Provider.of<UserModel?>(context, listen: false);
    final usageService = Provider.of<UsageService>(context, listen: false);
    
    // Record the view for guests
    if (user?.isGuest ?? true) {
      await usageService.recordRecipeView(user);
    }
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _recordViewAndNavigateToSubscription() async {
    final user = Provider.of<UserModel?>(context, listen: false);
    final usageService = Provider.of<UsageService>(context, listen: false);
    
    // Record the view for regular users
    if (user != null && !user.isGuest && !user.isVIP) {
      await usageService.recordRecipeView(user);
    }
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingLimit) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_canViewRecipe) {
      final user = Provider.of<UserModel?>(context, listen: false);
      final isGuest = user?.isGuest ?? true;
      
      return Scaffold(
        appBar: AppBar(title: Text(widget.recipe.name)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock,
                  size: 80,
                  color: Colors.deepOrange,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Daily Limit Reached',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isGuest
                      ? 'You\'ve reached your daily limit of 1 recipe as a guest. Sign in to view 3 recipes per day!'
                      : 'You\'ve reached your daily limit of 3 recipes. Upgrade to VIP for unlimited access!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: isGuest
                      ? _recordViewAndNavigateToLogin
                      : _recordViewAndNavigateToSubscription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                  child: Text(
                    isGuest ? 'Sign In to View More' : 'Upgrade to VIP',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.name),
        actions: [
          // Download button for VIP users
          Consumer<UserModel?>(
            builder: (context, user, _) {
              if (user?.isVIP ?? false) {
                return IconButton(
                  onPressed: _isDownloading ? null : _toggleDownload,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isDownloaded ? Icons.download_done : Icons.download,
                          color: _isDownloaded ? Colors.green : null,
                        ),
                  tooltip: _isDownloaded ? 'Remove from downloads' : 'Download for offline',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecipeImage(
              imageUrl: widget.recipe.imageUrl,
              borderRadius: BorderRadius.circular(16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ingredients',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            for (final ingredient in widget.recipe.ingredients)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(ingredient),
              ),
            const SizedBox(height: 20),
            const Text(
              'Instructions',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(widget.recipe.instructions),
          ],
        ),
      ),
    );
  }
}

