import 'package:hive/hive.dart';
import '../models/recipe.dart';

class RecipeDownloadService {
  static const String _boxName = 'downloaded_recipes';
  late Box<Map> _box;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _box = await Hive.openBox<Map>(_boxName);
      } else {
        _box = Hive.box<Map>(_boxName);
      }
      _initialized = true;
    } catch (e) {
      // Handle initialization error silently
      rethrow;
    }
  }

  /// Download a recipe for offline access
  Future<bool> downloadRecipe(Recipe recipe) async {
    try {
      await initialize();
      final recipeData = {
        'id': recipe.id,
        'name': recipe.name,
        'ingredients': recipe.ingredients,
        'instructions': recipe.instructions,
        'imageUrl': recipe.imageUrl,
        'downloadedAt': DateTime.now().toIso8601String(),
      };
      await _box.put(recipe.id, recipeData);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove a downloaded recipe
  Future<bool> removeDownloadedRecipe(String recipeId) async {
    try {
      await initialize();
      await _box.delete(recipeId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if a recipe is downloaded
  Future<bool> isRecipeDownloaded(String recipeId) async {
    try {
      await initialize();
      return _box.containsKey(recipeId);
    } catch (e) {
      return false;
    }
  }

  /// Get all downloaded recipes
  Future<List<Recipe>> getDownloadedRecipes() async {
    try {
      await initialize();
      final recipes = <Recipe>[];
      for (final data in _box.values) {
        recipes.add(Recipe(
          id: data['id'] ?? '',
          name: data['name'] ?? '',
          ingredients: List<String>.from(data['ingredients'] ?? []),
          instructions: data['instructions'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
        ));
      }
      return recipes;
    } catch (e) {
      return [];
    }
  }

  /// Get a specific downloaded recipe
  Future<Recipe?> getDownloadedRecipe(String recipeId) async {
    try {
      await initialize();
      final data = _box.get(recipeId);
      if (data == null) return null;
      
      return Recipe(
        id: data['id'] ?? '',
        name: data['name'] ?? '',
        ingredients: List<String>.from(data['ingredients'] ?? []),
        instructions: data['instructions'] ?? '',
        imageUrl: data['imageUrl'] ?? '',
      );
    } catch (e) {
      return null;
    }
  }

  /// Get count of downloaded recipes
  Future<int> getDownloadedRecipeCount() async {
    try {
      await initialize();
      return _box.length;
    } catch (e) {
      return 0;
    }
  }

  /// Clear all downloaded recipes
  Future<bool> clearAllDownloads() async {
    try {
      await initialize();
      await _box.clear();
      return true;
    } catch (e) {
      return false;
    }
  }
}
