import 'dart:convert';
import 'package:http/http.dart' as http;

class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final bool isPremium;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.isPremium,
  });
}

class RecipeApiService {
  static Future<List<Recipe>> fetchRecipes() async {
    // Example free API (Themealdb):
    final url =
        Uri.parse('https://www.themealdb.com/api/json/v1/1/search.php?s=chicken');

    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('Failed to load recipes');
    }

    final data = jsonDecode(res.body);
    final meals = data['meals'] as List<dynamic>? ?? [];

    return meals.map((m) {
      final id = m['idMeal'] as String;
      final isPremium = id.hashCode.isEven; // simple condition for demo

      return Recipe(
        id: id,
        title: m['strMeal'] ?? '',
        imageUrl: m['strMealThumb'] ?? '',
        isPremium: isPremium,
      );
    }).toList();
  }
}
