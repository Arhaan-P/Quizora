import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/quiz.dart';
import '../models/flashcard.dart';

class GeminiService {
  static String? get _apiKey {
    try {
      // Check if dotenv is properly initialized
      if (!dotenv.isInitialized) {
        print('Dotenv not initialized. Loading .env file...');
        return null;
      }

      final key = dotenv.env['GEMINI_API_KEY'];
      if (key == null || key.isEmpty) {
        print('GEMINI_API_KEY not found in .env file');
        return null;
      }

      print('Gemini API key loaded successfully');
      return key;
    } catch (e) {
      print('Error accessing .env file: $e');
      return null;
    }
  }

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  static Future<List<QuizQuestion>> generateQuizFromFlashcards(
    List<Flashcard> flashcards,
  ) async {
    // Always use fallback if no flashcards or insufficient flashcards
    if (flashcards.isEmpty) {
      return [];
    }

    final apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      // Fallback to manually created questions if no API key
      return _generateFallbackQuiz(flashcards);
    }

    try {
      // Take a random sample of flashcards for the quiz
      final shuffled = List<Flashcard>.from(flashcards)..shuffle();
      final selectedCards = shuffled.take(min(5, flashcards.length)).toList();

      List<QuizQuestion> questions = [];

      for (final card in selectedCards) {
        final prompt =
            '''
Generate a multiple choice question based on this flashcard:
Question: ${card.question}
Answer: ${card.answer}

Create a JSON response with exactly this format:
{
  "question": "A clear question based on the flashcard content",
  "options": ["Option A", "Option B", "Option C", "Option D"],
  "correctAnswer": 0,
  "explanation": "Brief explanation of why this is correct"
}

Make sure the correct answer is included in the options array and the correctAnswer index points to it.
''';

        final response = await _makeGeminiRequest(prompt);
        if (response != null) {
          questions.add(response);
        }
      }

      return questions.isNotEmpty
          ? questions
          : _generateFallbackQuiz(flashcards);
    } catch (e) {
      print('Error generating quiz: $e');
      return _generateFallbackQuiz(flashcards);
    }
  }

  static Future<QuizQuestion?> _makeGeminiRequest(String prompt) async {
    final apiKey = _apiKey;
    if (apiKey == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (text != null) {
          // Try to extract JSON from the response
          final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
          if (jsonMatch != null) {
            final jsonStr = jsonMatch.group(0)!;
            final questionData = jsonDecode(jsonStr);
            return QuizQuestion.fromJson(questionData);
          }
        }
      }
    } catch (e) {
      print('Error making Gemini request: $e');
    }
    return null;
  }

  static List<QuizQuestion> _generateFallbackQuiz(List<Flashcard> flashcards) {
    if (flashcards.isEmpty) {
      return [];
    }

    final shuffled = List<Flashcard>.from(flashcards)..shuffle();
    final selectedCards = shuffled.take(min(5, flashcards.length)).toList();

    return selectedCards.map((card) {
      // Create intelligent quiz questions from flashcards
      final wrongAnswers = _generateSmartWrongAnswers(
        card.answer,
        flashcards,
        card.category,
      );
      final allOptions = [card.answer, ...wrongAnswers]..shuffle();
      final correctIndex = allOptions.indexOf(card.answer);

      return QuizQuestion(
        question: _enhanceQuestion(card.question),
        options: allOptions,
        correctAnswer: correctIndex,
        explanation: _generateExplanation(
          card.question,
          card.answer,
          card.category,
        ),
      );
    }).toList();
  }

  static String _enhanceQuestion(String originalQuestion) {
    // Make the question more quiz-like if it's not already
    if (originalQuestion.endsWith('?')) {
      return originalQuestion;
    }

    // Add "What is" or "Which of the following" style prefixes
    final questionStarters = [
      'What is the answer to: ',
      'Which of the following is correct for: ',
      'Select the correct answer for: ',
    ];

    return questionStarters[Random().nextInt(questionStarters.length)] +
        originalQuestion +
        '?';
  }

  static String _generateExplanation(
    String question,
    String answer,
    String category,
  ) {
    final explanations = [
      'The correct answer is "$answer". This is fundamental knowledge in $category.',
      'Based on the question "$question", the answer "$answer" is correct.',
      'In $category, "$answer" is the accurate response to this question.',
      'The answer "$answer" correctly addresses this $category concept.',
    ];

    return explanations[Random().nextInt(explanations.length)];
  }

  static List<String> _generateSmartWrongAnswers(
    String correctAnswer,
    List<Flashcard> allCards,
    String category,
  ) {
    // Get wrong answers from the same category first (more challenging)
    final sameCategoryWrong =
        allCards
            .where(
              (card) =>
                  card.category == category && card.answer != correctAnswer,
            )
            .map((card) => card.answer)
            .toSet()
            .toList()
          ..shuffle();

    // Get wrong answers from other categories as backup
    final otherWrongAnswers =
        allCards
            .where(
              (card) =>
                  card.answer != correctAnswer &&
                  !sameCategoryWrong.contains(card.answer),
            )
            .map((card) => card.answer)
            .toSet()
            .toList()
          ..shuffle();

    final result = <String>[];

    // Prioritize same-category wrong answers (more realistic)
    result.addAll(sameCategoryWrong.take(2));

    // Add other wrong answers if needed
    if (result.length < 3) {
      result.addAll(otherWrongAnswers.take(3 - result.length));
    }

    // Generate plausible wrong options if we still don't have enough
    while (result.length < 3) {
      final plausibleOptions = _generatePlausibleOptions(
        correctAnswer,
        category,
      );
      for (final option in plausibleOptions) {
        if (!result.contains(option) && option != correctAnswer) {
          result.add(option);
          if (result.length >= 3) break;
        }
      }
      break; // Prevent infinite loop
    }

    return result.take(3).toList();
  }

  static List<String> _generatePlausibleOptions(
    String correctAnswer,
    String category,
  ) {
    // Generate more realistic wrong answers based on category
    switch (category.toLowerCase()) {
      case 'math':
        return _generateMathOptions(correctAnswer);
      case 'science':
        return _generateScienceOptions(correctAnswer);
      case 'history':
        return _generateHistoryOptions(correctAnswer);
      case 'geography':
        return _generateGeographyOptions(correctAnswer);
      default:
        return _generateGenericOptions(correctAnswer);
    }
  }

  static List<String> _generateMathOptions(String correct) {
    final options = <String>[];
    if (RegExp(r'^\d+$').hasMatch(correct)) {
      final num = int.tryParse(correct);
      if (num != null) {
        options.addAll(['${num + 1}', '${num - 1}', '${num * 2}']);
      }
    } else {
      options.addAll(['False', 'True', 'Undefined', 'Infinite']);
    }
    return options;
  }

  static List<String> _generateScienceOptions(String correct) {
    return [
      'Hydrogen',
      'Oxygen',
      'Carbon',
      'Nitrogen',
      'Photosynthesis',
      'Respiration',
      'DNA',
      'RNA',
    ].where((option) => option != correct).toList();
  }

  static List<String> _generateHistoryOptions(String correct) {
    return [
      '1776',
      '1492',
      '1914',
      '1945',
      'Napoleon',
      'Churchill',
      'Lincoln',
      'Washington',
    ].where((option) => option != correct).toList();
  }

  static List<String> _generateGeographyOptions(String correct) {
    return [
      'Europe',
      'Asia',
      'Africa',
      'Pacific Ocean',
      'Atlantic Ocean',
      'Mount Everest',
      'Amazon River',
      'Sahara Desert',
    ].where((option) => option != correct).toList();
  }

  static List<String> _generateGenericOptions(String correct) {
    return [
      'Option A',
      'Alternative Answer',
      'Different Choice',
      'Other Response',
    ].where((option) => option != correct).toList();
  }
}
