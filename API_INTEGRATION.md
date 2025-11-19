# Recipe API Integration

## API Used: TheMealDB

**Website:** https://www.themealdb.com/  
**API Documentation:** https://www.themealdb.com/api.php

### Why TheMealDB?
- ✅ **Completely FREE** - No API key required
- ✅ **No rate limits** on the free tier
- ✅ **Rich database** - 1000+ recipes with images
- ✅ **Comprehensive data** - Ingredients, instructions, images, videos
- ✅ **Multiple endpoints** - Search, filter by category, area, ingredient

## Available Features

### 1. Random Recipes
- Fetches random recipes from the database
- Used on app launch for discovery

### 2. Search Recipes
- Search by recipe name
- Search by keywords (chicken, pasta, etc.)

### 3. Browse by Category
- Beef, Chicken, Dessert, Lamb, Pasta, Pork, Seafood, Side, Starter, Vegan, Vegetarian, Breakfast, Goat, and more

### 4. Browse by Cuisine/Area
- American, British, Canadian, Chinese, Croatian, Dutch, Egyptian, French, Greek, Indian, Irish, Italian, Jamaican, Japanese, Kenyan, Malaysian, Mexican, Moroccan, Polish, Portuguese, Russian, Spanish, Thai, Tunisian, Turkish, Vietnamese, and more

### 5. Recipe Details
- Full ingredient list with measurements
- Step-by-step instructions
- Recipe images
- YouTube video links (when available)

## API Endpoints Used

```dart
// Base URL
https://www.themealdb.com/api/json/v1/1

// Random recipe
/random.php

// Random selection (multiple)
/randomselection.php

// Latest recipes
/latest.php

// Search by name
/search.php?s={query}

// Recipe details by ID
/lookup.php?i={id}

// Filter by category
/filter.php?c={category}

// Filter by area/cuisine
/filter.php?a={area}

// List all categories
/categories.php

// List all areas
/list.php?a=list
```

## Implementation Details

### RecipeService Class
Located in `lib/services/recipe_service.dart`

**Key Methods:**
- `getRandomRecipes()` - Get random recipes for discovery
- `getDiscoveryFeed()` - Get diverse mix from multiple sources
- `searchRecipes()` - Search by name or keywords
- `getRecipeDetails()` - Get full recipe information
- `getRecipesByCategory()` - Filter by category
- `getRecipesByArea()` - Filter by cuisine
- `getAllCategories()` - List all available categories
- `getAllAreas()` - List all available cuisines
- `getAllRecipes()` - Comprehensive collection from all categories

### Recipe Model
Located in `lib/models/recipe.dart`

**Fields:**
- `id` - Unique recipe identifier
- `name` - Recipe name
- `imageUrl` - Recipe image
- `instructions` - Cooking instructions
- `ingredients` - List of ingredients with measurements
- `videoUrl` - YouTube video link (optional)

## Usage in App

### Home Screen
- Displays 20 random recipes on load
- Search functionality
- Refresh button to get new random recipes
- "Load All Recipes" button to fetch comprehensive collection

### Categories Screen
- Browse all available categories
- Browse all available cuisines
- Tap to view recipes in each category/cuisine

### Recipe Detail Screen
- Full recipe information
- Ingredients list
- Cooking instructions
- Recipe image

## No API Key Required!

TheMealDB's free tier doesn't require any API key or authentication. Simply make HTTP GET requests to the endpoints and parse the JSON response.

## Future Enhancements

Potential improvements:
- Add favorites/bookmarks (local storage)
- Offline caching of recipes
- Filter by ingredients
- Advanced search options
- Recipe ratings and reviews (would need custom backend)
