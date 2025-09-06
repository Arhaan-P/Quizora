class Flashcard {
  final int? id;
  final String question;
  final String answer;
  final String? imagePath;
  final String category;
  final bool isLearned;
  final DateTime createdAt;

  Flashcard({
    this.id,
    required this.question,
    required this.answer,
    this.imagePath,
    required this.category,
    this.isLearned = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'imagePath': imagePath,
      'category': category,
      'isLearned': isLearned ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id']?.toInt(),
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      imagePath: map['imagePath'],
      category: map['category'] ?? '',
      isLearned: (map['isLearned'] ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Flashcard copyWith({
    int? id,
    String? question,
    String? answer,
    String? imagePath,
    String? category,
    bool? isLearned,
    DateTime? createdAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      isLearned: isLearned ?? this.isLearned,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
