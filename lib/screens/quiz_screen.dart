import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/flashcard_provider.dart';
import '../models/quiz.dart';

class QuizScreen extends StatefulWidget {
  final String category;

  const QuizScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startQuiz();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startQuiz() async {
    final flashcardProvider = Provider.of<FlashcardProvider>(
      context,
      listen: false,
    );
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);

    // Load flashcards for the specified category
    await flashcardProvider.loadFlashcards(
      widget.category == 'All' ? null : widget.category,
    );
    final flashcards = flashcardProvider.flashcards;

    if (flashcards.isEmpty) {
      _showNoFlashcardsDialog();
      return;
    }

    await quizProvider.generateQuiz(flashcards);
    _animationController.forward();
  }

  void _showNoFlashcardsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Flashcards'),
        content: Text(
          'No flashcards found in the ${widget.category} category. Please add some flashcards first.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                    const Color(0xFF0F0F23),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFE2E8F0),
                    const Color(0xFFCBD5E1),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Consumer<QuizProvider>(
                  builder: (context, quizProvider, child) {
                    if (quizProvider.isLoading) {
                      return _buildLoadingView();
                    }

                    if (quizProvider.result != null) {
                      return _buildResultView(quizProvider.result!);
                    }

                    if (quizProvider.questions.isEmpty) {
                      return _buildErrorView();
                    }

                    return _buildQuizView(quizProvider);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF374151) : const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 14,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '${widget.category} Quiz',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.orange[400]!, Colors.red[400]!]
                    : [Colors.orange[500]!, Colors.red[500]!],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.psychology, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Quiz',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Generating your quiz...'),
          SizedBox(height: 8),
          Text('This may take a moment', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Unable to generate quiz'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _startQuiz, child: const Text('Try Again')),
        ],
      ),
    );
  }

  Widget _buildQuizView(QuizProvider quizProvider) {
    final currentQuestion = quizProvider.currentQuestion!;
    final progress =
        (quizProvider.currentQuestionIndex + 1) / quizProvider.questions.length;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress indicator
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${quizProvider.currentQuestionIndex + 1} of ${quizProvider.questions.length}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue[700]!,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Question card
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        currentQuestion.question,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),

                      // Options
                      Expanded(
                        child: ListView.builder(
                          itemCount: currentQuestion.options.length,
                          itemBuilder: (context, index) {
                            final isSelected =
                                quizProvider.userAnswers[quizProvider
                                    .currentQuestionIndex] ==
                                index;
                            final hasAnswered =
                                quizProvider.userAnswers[quizProvider
                                    .currentQuestionIndex] !=
                                null;
                            final isCorrect =
                                index == currentQuestion.correctAnswer;
                            final isSelectedWrong =
                                isSelected && !isCorrect && hasAnswered;

                            Color? borderColor;
                            Color? backgroundColor;
                            IconData? iconData;
                            Color? iconColor;

                            if (hasAnswered) {
                              if (isCorrect) {
                                borderColor = Colors.green;
                                backgroundColor = Colors.green.withOpacity(0.1);
                                iconData = Icons.check_circle;
                                iconColor = Colors.green;
                              } else if (isSelectedWrong) {
                                borderColor = Colors.red;
                                backgroundColor = Colors.red.withOpacity(0.1);
                                iconData = Icons.cancel;
                                iconColor = Colors.red;
                              } else {
                                borderColor = Colors.grey[300];
                                iconData = Icons.radio_button_unchecked;
                                iconColor = Colors.grey[400];
                              }
                            } else {
                              borderColor = isSelected
                                  ? Colors.blue[700]
                                  : Colors.grey[300];
                              backgroundColor = isSelected
                                  ? Colors.blue[50]
                                  : null;
                              iconData = isSelected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked;
                              iconColor = isSelected
                                  ? Colors.blue[700]
                                  : Colors.grey[400];
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: InkWell(
                                onTap: hasAnswered
                                    ? null
                                    : () {
                                        quizProvider.answerQuestion(index);
                                      },
                                child: Container(
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: borderColor!,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: backgroundColor,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        iconData,
                                        color: iconColor,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          currentQuestion.options[index],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                (isSelected ||
                                                    (hasAnswered && isCorrect))
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Navigation buttons
            const SizedBox(height: 16),
            Row(
              children: [
                if (quizProvider.currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        quizProvider.previousQuestion();
                      },
                      child: const Text('Previous'),
                    ),
                  ),
                if (quizProvider.currentQuestionIndex > 0)
                  const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        quizProvider.userAnswers[quizProvider
                                .currentQuestionIndex] !=
                            null
                        ? () {
                            if (quizProvider.currentQuestionIndex <
                                quizProvider.questions.length - 1) {
                              quizProvider.nextQuestion();
                              _animationController.reset();
                              _animationController.forward();
                            } else {
                              quizProvider
                                  .nextQuestion(); // This will finish the quiz
                            }
                          }
                        : null,
                    child: Text(
                      quizProvider.currentQuestionIndex <
                              quizProvider.questions.length - 1
                          ? 'Next'
                          : 'Finish Quiz',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView(QuizResult result) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Score circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getScoreColor(result.percentage),
              boxShadow: [
                BoxShadow(
                  color: _getScoreColor(result.percentage).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${result.percentage.round()}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    result.grade,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Results card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    'Quiz Complete!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Correct',
                        '${result.correctAnswers}',
                        Colors.green,
                      ),
                      _buildStatItem(
                        'Incorrect',
                        '${result.totalQuestions - result.correctAnswers}',
                        Colors.red,
                      ),
                      _buildStatItem(
                        'Total',
                        '${result.totalQuestions}',
                        Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Provider.of<QuizProvider>(
                      context,
                      listen: false,
                    ).resetQuiz();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Back to Categories'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _startQuiz,
                  child: const Text('Take Again'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }
}
