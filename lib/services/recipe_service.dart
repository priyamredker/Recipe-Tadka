import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/recipe.dart';
import 'gemini_service.dart';

class RecipeService {
  static const String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  RecipeService({GeminiService? geminiService})
      : _geminiService = geminiService ?? GeminiService();

  final GeminiService _geminiService;
  final List<Recipe> _breakfastCache = [];
  final List<Recipe> _lunchCache = [];
  final List<Recipe> _dinnerCache = [];
  final List<Recipe> _dessertCache = [];
  final List<Recipe> _vegCache = [];

  Future<List<Recipe>> getRandomRecipes({int desiredCount = 10}) async {
    final randomSelection =
        await _fetchMeals('$_baseUrl/randomselection.php', desiredCount: desiredCount);
    if (randomSelection.isNotEmpty) return randomSelection;
    
    // Fallback: fetch multiple random individual recipes
    final Set<String> seenIds = {};
    final List<Recipe> randomRecipes = [];
    
    for (int i = 0; i < desiredCount * 2; i++) {
      final random = await _fetchMeals('$_baseUrl/random.php');
      for (final recipe in random) {
        if (seenIds.add(recipe.id)) {
          randomRecipes.add(recipe);
          if (randomRecipes.length >= desiredCount) break;
        }
      }
      if (randomRecipes.length >= desiredCount) break;
    }
    
    if (randomRecipes.isNotEmpty) return randomRecipes;
    return getDiscoveryFeed(desiredCount: desiredCount);
  }

  Future<List<Recipe>> getDiscoveryFeed({int desiredCount = 10}) async {
    final Set<String> seenIds = {};
    final List<Recipe> aggregated = [];

    void addRecipes(List<Recipe> recipes) {
      for (final recipe in recipes) {
        if (seenIds.add(recipe.id)) {
          aggregated.add(recipe);
          if (aggregated.length >= desiredCount) return;
        }
      }
    }

    // Get latest recipes
    addRecipes(await _fetchMeals('$_baseUrl/latest.php'));

    // Mix of different search queries for variety
    const queries = [
      'chicken', 'pasta', 'curry', 'salad', 'dessert',
      'vegetarian', 'seafood', 'soup', 'rice', 'bread',
      'beef', 'lamb', 'pork', 'fish', 'cake',
      'pie', 'pizza', 'burger', 'sandwich', 'noodles'
    ];
    
    // Shuffle and pick random queries for variety
    final shuffledQueries = List<String>.from(queries)..shuffle();
    for (final query in shuffledQueries.take(10)) {
      if (aggregated.length >= desiredCount) break;
      addRecipes(await _fetchMeals('$_baseUrl/search.php?s=$query'));
    }

    // Add from all available categories
    final categories = [
      'Beef', 'Chicken', 'Dessert', 'Lamb', 'Miscellaneous',
      'Pasta', 'Pork', 'Seafood', 'Side', 'Starter',
      'Vegan', 'Vegetarian', 'Breakfast', 'Goat'
    ];
    
    for (final category in categories) {
      if (aggregated.length >= desiredCount) break;
      addRecipes(await _fetchMeals('$_baseUrl/filter.php?c=$category'));
    }

    // Add from specific meal areas for international variety
    final areas = [
      'American', 'British', 'Canadian', 'Chinese', 'Croatian',
      'Dutch', 'Egyptian', 'French', 'Greek', 'Indian',
      'Irish', 'Italian', 'Jamaican', 'Japanese', 'Kenyan',
      'Malaysian', 'Mexican', 'Moroccan', 'Polish', 'Portuguese',
      'Russian', 'Spanish', 'Thai', 'Tunisian', 'Turkish',
      'Vietnamese'
    ];
    
    final shuffledAreas = List<String>.from(areas)..shuffle();
    for (final area in shuffledAreas.take(5)) {
      if (aggregated.length >= desiredCount) break;
      addRecipes(await _fetchMeals('$_baseUrl/filter.php?a=$area'));
    }

    // Fallback recipes
    if (aggregated.length < desiredCount) {
      for (final recipe in _fallbackRecipes) {
        if (aggregated.length >= desiredCount) break;
        if (seenIds.add(recipe.id)) {
          aggregated.add(recipe);
        }
      }
    }

    return aggregated.take(desiredCount).toList();
  }

  Future<Recipe?> getRecipeDetails(String id) async {
    final response = await http.get(Uri.parse('$_baseUrl/lookup.php?i=$id'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] != null) {
        return Recipe.fromJson(data['meals'][0]);
      }
    }
    return null;
  }

  Future<List<Recipe>> searchRecipes(String query) async {
    // Search by name first
    final nameResults = await _fetchMeals('$_baseUrl/search.php?s=$query');
    
    // If we got results from name search, return them
    if (nameResults.isNotEmpty) {
      return nameResults;
    }
    
    // If no results, check if query contains meal type or diet keywords
    final lowerQuery = query.toLowerCase();
    
    if (lowerQuery.contains('breakfast')) {
      return await getBreakfastRecipes();
    }
    
    if (lowerQuery.contains('lunch')) {
      return await getLunchRecipes();
    }
    
    if (lowerQuery.contains('dinner')) {
      return await getDinnerRecipes();
    }
    
    if (lowerQuery.contains('veg') || lowerQuery.contains('vegetarian')) {
      return await getVegFavorites(desiredCount: 20);
    }
    
    if (lowerQuery.contains('non-veg') || lowerQuery.contains('nonveg') || 
        lowerQuery.contains('chicken') || lowerQuery.contains('meat') ||
        lowerQuery.contains('fish') || lowerQuery.contains('seafood')) {
      return await getNonVegRecipes();
    }
    
    // Return empty list if no matches found
    return [];
  }

  Future<List<Recipe>> _fetchMeals(String url, {int desiredCount = 0}) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final meals = data['meals'] as List?;
        if (meals != null) {
          var recipes = meals
              .map((entry) => Recipe.fromJson(entry as Map<String, dynamic>))
              .toList();
          recipes = await _enrichWithImages(recipes);
          if (desiredCount > 0) {
            return recipes.take(desiredCount).toList();
          }
          return recipes;
        }
      }
    } catch (e) {
      debugPrint('RecipeService error for $url: $e');
    }
    return [];
  }

  Future<List<Recipe>> _enrichWithImages(List<Recipe> recipes) async {
    if (!_geminiService.isConfigured) return recipes;
    final List<Recipe> enhanced = [];
    for (final recipe in recipes) {
      if (recipe.hasImage) {
        enhanced.add(recipe);
        continue;
      }
      final generated = await _geminiService.generateDishImage(recipe.name);
      if (generated != null) {
        enhanced.add(recipe.copyWith(imageUrl: generated));
      } else {
        enhanced.add(recipe);
      }
    }
    return enhanced;
  }

  static final List<Recipe> _fallbackRecipes = [
    const Recipe(
      id: 'sample_paneer_wrap',
      name: 'Tandoori Paneer Wrap',
      imageUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800',
      instructions:
          'Marinate paneer with yogurt & spices, grill until charred, then wrap with crunchy veggies and mint chutney.',
      ingredients: [
        '200g paneer cubes',
        '4 tbsp yogurt',
        'Mint chutney',
        'Onion & capsicum',
        'Whole wheat wrap',
      ],
    ),
    const Recipe(
      id: 'sample_masala_dosa',
      name: 'Crispy Masala Dosa',
      imageUrl:
          'https://images.unsplash.com/photo-1608039829574-853a17a654d8?w=800',
      instructions:
          'Spread fermented batter thin on a hot tawa, fill with spiced potato masala, fold and serve with chutneys.',
      ingredients: [
        '2 cups dosa batter',
        'Potato masala',
        'Ghee',
        'Coconut chutney',
        'Sambar',
      ],
    ),
    const Recipe(
      id: 'sample_pesto_pasta',
      name: 'Roasted Veg Pesto Pasta',
      imageUrl:
          'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=800',
      instructions:
          'Toss al dente pasta with basil pesto, roasted veggies, and toasted nuts for crunch.',
      ingredients: [
        'Penne pasta',
        'Basil pesto',
        'Cherry tomatoes',
        'Zucchini',
        'Toasted pine nuts',
      ],
    ),
    const Recipe(
      id: 'sample_choco_cake',
      name: 'Molten Chocolate Cake',
      imageUrl:
          'https://images.unsplash.com/photo-1505253758473-96b7015fcd40?w=800',
      instructions:
          'Bake rich chocolate batter until edges set but center stays gooey. Serve warm with berries.',
      ingredients: [
        'Dark chocolate',
        'Butter',
        'Eggs',
        'Sugar',
        'Flour',
      ],
    ),
  ];

  Future<List<Recipe>> getBreakfastRecipes() async {
    if (_breakfastCache.isNotEmpty) return _breakfastCache;
    final filters = await _fetchMeals('$_baseUrl/filter.php?c=Breakfast');
    final detailed = await _enrichMealsWithDetails(filters);
    _breakfastCache.addAll(detailed);
    return _breakfastCache;
  }

  Future<List<Recipe>> getLunchRecipes() async {
    if (_lunchCache.isNotEmpty) return _lunchCache;
    final chicken = await _fetchMeals('$_baseUrl/filter.php?c=Chicken');
    final seafood = await _fetchMeals('$_baseUrl/filter.php?c=Seafood');
    final detailed = await _enrichMealsWithDetails([...chicken, ...seafood]);
    _lunchCache.addAll(detailed);
    return _lunchCache;
  }

  Future<List<Recipe>> getDinnerRecipes() async {
    if (_dinnerCache.isNotEmpty) return _dinnerCache;
    final beef = await _fetchMeals('$_baseUrl/filter.php?c=Beef');
    final lamb = await _fetchMeals('$_baseUrl/filter.php?c=Lamb');
    final detailed = await _enrichMealsWithDetails([...beef, ...lamb]);
    _dinnerCache.addAll(detailed);
    return _dinnerCache;
  }

  Future<List<Recipe>> getDessertRecipes() async {
    if (_dessertCache.isNotEmpty) return _dessertCache;
    final dessert = await _fetchMeals('$_baseUrl/filter.php?c=Dessert');
    final detailed = await _enrichMealsWithDetails(dessert);
    _dessertCache.addAll(detailed);
    return _dessertCache;
  }

  Future<List<Recipe>> getVegFavorites({int desiredCount = 8}) async {
    if (_vegCache.isNotEmpty) return _vegCache.take(desiredCount).toList();
    final vegFilters = await _fetchMeals('$_baseUrl/filter.php?c=Vegetarian');
    final veganFilters = await _fetchMeals('$_baseUrl/filter.php?c=Vegan');
    final detailed = await _enrichMealsWithDetails([...vegFilters, ...veganFilters]);
    _vegCache.addAll(detailed);
    return _vegCache.take(desiredCount).toList();
  }

  Future<List<Recipe>> getNonVegRecipes({int desiredCount = 20}) async {
    final chicken = await _fetchMeals('$_baseUrl/filter.php?c=Chicken');
    final seafood = await _fetchMeals('$_baseUrl/filter.php?c=Seafood');
    final beef = await _fetchMeals('$_baseUrl/filter.php?c=Beef');
    final lamb = await _fetchMeals('$_baseUrl/filter.php?c=Lamb');
    final pork = await _fetchMeals('$_baseUrl/filter.php?c=Pork');
    final allNonVeg = [...chicken, ...seafood, ...beef, ...lamb, ...pork];
    final detailed = await _enrichMealsWithDetails(allNonVeg);
    return detailed.take(desiredCount).toList();
  }

  Future<List<Recipe>> _enrichMealsWithDetails(List<Recipe> recipes) async {
    final List<Recipe> detailed = [];
    for (final recipe in recipes) {
      final detail = await getRecipeDetails(recipe.id);
      detailed.add(detail ?? recipe);
    }
    return detailed;
  }

  // Get recipes by cuisine/area
  Future<List<Recipe>> getRecipesByArea(String area) async {
    final recipes = await _fetchMeals('$_baseUrl/filter.php?a=$area');
    return await _enrichMealsWithDetails(recipes);
  }

  // Get recipes by category
  Future<List<Recipe>> getRecipesByCategory(String category) async {
    final recipes = await _fetchMeals('$_baseUrl/filter.php?c=$category');
    return await _enrichMealsWithDetails(recipes);
  }

  // Get all available categories
  Future<List<String>> getAllCategories() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/categories.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final categories = data['categories'] as List?;
        if (categories != null) {
          return categories
              .map((cat) => cat['strCategory'] as String)
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
    return [];
  }

  // Get all available areas/cuisines
  Future<List<String>> getAllAreas() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/list.php?a=list'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final areas = data['meals'] as List?;
        if (areas != null) {
          return areas
              .map((area) => area['strArea'] as String)
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching areas: $e');
    }
    return [];
  }

  // Get a comprehensive collection of recipes from all categories
  Future<List<Recipe>> getAllRecipes({int maxPerCategory = 5}) async {
    final Set<String> seenIds = {};
    final List<Recipe> allRecipes = [];

    void addRecipes(List<Recipe> recipes) {
      for (final recipe in recipes) {
        if (seenIds.add(recipe.id)) {
          allRecipes.add(recipe);
        }
      }
    }

    // Fetch from all major categories
    final categories = await getAllCategories();
    for (final category in categories) {
      final recipes = await _fetchMeals('$_baseUrl/filter.php?c=$category');
      final detailed = await _enrichMealsWithDetails(
        recipes.take(maxPerCategory).toList()
      );
      addRecipes(detailed);
    }

    // Fetch from all areas for international variety
    final areas = await getAllAreas();
    for (final area in areas) {
      final recipes = await _fetchMeals('$_baseUrl/filter.php?a=$area');
      final detailed = await _enrichMealsWithDetails(
        recipes.take(maxPerCategory).toList()
      );
      addRecipes(detailed);
    }

    return allRecipes;
  }
}
