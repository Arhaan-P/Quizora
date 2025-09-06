import 'package:flutter/material.dart';
import '../models/flashcard.dart';

class FlashcardDeck extends StatelessWidget {
  final List<Flashcard> flashcards;
  final int currentIndex;
  final bool showAnswer;
  final VoidCallback? onTap;
  final double? height;
  final double? width;

  const FlashcardDeck({
    super.key,
    required this.flashcards,
    this.currentIndex = 0,
    this.showAnswer = false,
    this.onTap,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = width ?? screenWidth - 40;
    final cardHeight = height ?? 280;

    if (flashcards.isEmpty) {
      return Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No flashcards available',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    if (currentIndex >= flashcards.length) {
      return Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No more cards',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    final currentCard = flashcards[currentIndex];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D44) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header with question/answer label
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: showAnswer
                          ? (isDark ? Colors.green[800] : Colors.green[100])
                          : (isDark ? Colors.blue[800] : Colors.blue[100]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      showAnswer ? 'Answer' : 'Question',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: showAnswer
                            ? (isDark ? Colors.green[200] : Colors.green[700])
                            : (isDark ? Colors.blue[200] : Colors.blue[700]),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.grey[700] : Colors.grey[100])
                          ?.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${currentIndex + 1} / ${flashcards.length}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Content
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (currentCard.imagePath != null && !showAnswer) ...[
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: AssetImage(currentCard.imagePath!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        showAnswer ? currentCard.answer : currentCard.question,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.grey[800],
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tap hint
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.grey[700] : Colors.grey[100])
                      ?.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 14,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      showAnswer ? 'Tap for question' : 'Tap for answer',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
