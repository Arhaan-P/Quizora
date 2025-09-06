import 'package:flutter/foundation.dart';
import '../models/quiz.dart';
import '../models/flashcard.dart';
import '../services/gemini_service.dart';

class QuizProvider extends ChangeNotifier {
  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  List<int?> _userAnswers = [];
  bool _isLoading = false;
  QuizResult? _result;

  List<QuizQuestion> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  QuizQuestion? get currentQuestion =>
      _questions.isNotEmpty ? _questions[_currentQuestionIndex] : null;
  List<int?> get userAnswers => _userAnswers;
  bool get isLoading => _isLoading;
  QuizResult? get result => _result;
  bool get isQuizCompleted => _currentQuestionIndex >= _questions.length;

  Future<void> generateQuiz(List<Flashcard> flashcards) async {
    _isLoading = true;
    _questions = [];
    _currentQuestionIndex = 0;
    _userAnswers = [];
    _result = null;
    notifyListeners();

    try {
      _questions = await GeminiService.generateQuizFromFlashcards(flashcards);
      _userAnswers = List.filled(_questions.length, null);
    } catch (e) {
      print('Error generating quiz: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void answerQuestion(int selectedOption) {
    if (_currentQuestionIndex < _questions.length) {
      _userAnswers[_currentQuestionIndex] = selectedOption;
      notifyListeners();
    }
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    } else {
      _finishQuiz();
    }
  }

  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  void _finishQuiz() {
    int correctAnswers = 0;
    List<bool> answers = [];

    for (int i = 0; i < _questions.length; i++) {
      final isCorrect = _userAnswers[i] == _questions[i].correctAnswer;
      answers.add(isCorrect);
      if (isCorrect) correctAnswers++;
    }

    _result = QuizResult(
      totalQuestions: _questions.length,
      correctAnswers: correctAnswers,
      answers: answers,
      completedAt: DateTime.now(),
    );

    notifyListeners();
  }

  void resetQuiz() {
    _questions = [];
    _currentQuestionIndex = 0;
    _userAnswers = [];
    _result = null;
    _isLoading = false;
    notifyListeners();
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }
}
