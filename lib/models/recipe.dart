class Recipe {
  final String id;
  final String name;
  final String imageUrl;
  final String instructions;
  final List<String> ingredients;
  final String? videoUrl;

  static const String placeholderImage =
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800';

  const Recipe({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.instructions,
    required this.ingredients,
    this.videoUrl,
  });

  bool get hasImage => imageUrl.isNotEmpty && imageUrl != placeholderImage;

  Recipe copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? instructions,
    List<String>? ingredients,
    String? videoUrl,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      instructions: instructions ?? this.instructions,
      ingredients: ingredients ?? this.ingredients,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final List<String> ingredientsList = [];
    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'];
      final measure = json['strMeasure$i'];
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        final label = measure != null && measure.toString().trim().isNotEmpty
            ? '${measure.toString().trim()} ${ingredient.toString().trim()}'
            : ingredient.toString().trim();
        ingredientsList.add(label);
      } else {
        break;
      }
    }

    return Recipe(
      id: json['idMeal']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: (json['strMeal'] as String?)?.trim().isNotEmpty == true
          ? json['strMeal']
          : 'Untitled Recipe',
      imageUrl: (json['strMealThumb'] as String?)?.trim().isNotEmpty == true
          ? json['strMealThumb']
          : placeholderImage,
      instructions: (json['strInstructions'] as String?)?.trim().isNotEmpty == true
          ? json['strInstructions']
          : 'Detailed instructions will be available soon. In the meantime, follow your cooking instincts!',
      ingredients: ingredientsList.isEmpty ? ['Love', 'Creativity', 'Fresh produce'] : ingredientsList,
      videoUrl: json['strYoutube'] as String?,
    );
  }
}
