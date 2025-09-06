import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../models/category.dart';
import '../services/database_service.dart';

class FlashcardProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<Flashcard> _flashcards = [];
  List<Flashcard> _currentDeck = [];
  List<Category> _categories = [];
  String? _selectedCategory;
  int _currentIndex = 0;
  bool _showAnswer = false;

  List<Flashcard> get flashcards => _flashcards;
  List<Flashcard> get currentDeck => _currentDeck;
  List<Category> get categories => _categories;
  String? get selectedCategory => _selectedCategory;
  int get currentIndex => _currentIndex;
  bool get showAnswer => _showAnswer;

  Flashcard? get currentCard =>
      _currentDeck.isNotEmpty && _currentIndex < _currentDeck.length
      ? _currentDeck[_currentIndex]
      : null;

  int get totalCards => _currentDeck.length;
  int get cardNumber => _currentIndex + 1;

  Future<void> loadFlashcards([String? category]) async {
    if (category != null) {
      _flashcards = await _databaseService.getFlashcardsByCategory(category);
      _selectedCategory = category;
    } else {
      _flashcards = await _databaseService.getAllFlashcards();
      _selectedCategory = null;
    }

    _currentDeck = _flashcards.where((card) => !card.isLearned).toList();
    _currentIndex = 0;
    _showAnswer = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _categories = await getCategories();
    notifyListeners();
  }

  Future<void> addFlashcard(Flashcard flashcard) async {
    await _databaseService.insertFlashcard(flashcard);
    await loadFlashcards(_selectedCategory);
    await loadCategories(); // Refresh categories after adding a card
  }

  Future<void> updateFlashcard(Flashcard flashcard) async {
    await _databaseService.updateFlashcard(flashcard);
    await loadFlashcards(_selectedCategory);
    await loadCategories(); // Refresh categories after updating a card
  }

  Future<void> deleteFlashcard(int id) async {
    await _databaseService.deleteFlashcard(id);
    await loadFlashcards(_selectedCategory);
    await loadCategories(); // Refresh categories after deleting a card
  }

  Future<void> markAsLearned(int id) async {
    final flashcard = _flashcards.firstWhere((card) => card.id == id);
    final updatedCard = flashcard.copyWith(isLearned: true);
    await updateFlashcard(updatedCard);
  }

  void flipCard() {
    _showAnswer = !_showAnswer;
    notifyListeners();
  }

  void nextCard() {
    if (_currentIndex < _currentDeck.length - 1) {
      _currentIndex++;
      _showAnswer = false;
      notifyListeners();
    }
  }

  void previousCard() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _showAnswer = false;
      notifyListeners();
    }
  }

  void goToCard(int index) {
    if (index >= 0 && index < _currentDeck.length) {
      _currentIndex = index;
      _showAnswer = false;
      notifyListeners();
    }
  }

  Future<List<Category>> getCategories() async {
    final categoryNames = await _databaseService.getAllCategories();
    List<Category> categories = [];

    for (String name in categoryNames) {
      final stats = await _databaseService.getCategoryStats(name);
      categories.add(
        Category(
          name: name,
          icon: _getIconForCategory(name),
          totalCards: stats['total']!,
          learnedCards: stats['learned']!,
        ),
      );
    }

    return categories;
  }

  String _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'math':
        return '📐';
      case 'science':
        return '🔬';
      case 'history':
        return '📚';
      case 'geography':
        return '🌍';
      case 'language':
        return '💬';
      case 'art':
        return '🎨';
      default:
        return '📝';
    }
  }

  void resetProgress() {
    _currentIndex = 0;
    _showAnswer = false;
    notifyListeners();
  }
}
