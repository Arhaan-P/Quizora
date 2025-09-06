class Category {
  final String name;
  final String icon;
  final int totalCards;
  final int learnedCards;

  Category({
    required this.name,
    required this.icon,
    this.totalCards = 0,
    this.learnedCards = 0,
  });

  double get progress => totalCards > 0 ? learnedCards / totalCards : 0.0;

  static List<Category> getDefaultCategories() {
    return [
      Category(name: 'Math', icon: '📐'),
      Category(name: 'Science', icon: '🔬'),
      Category(name: 'History', icon: '📚'),
      Category(name: 'Geography', icon: '🌍'),
      Category(name: 'Language', icon: '💬'),
      Category(name: 'Art', icon: '🎨'),
    ];
  }
}
