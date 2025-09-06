import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/flashcard.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'flashcards.db');

    return await openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE flashcards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        imagePath TEXT,
        category TEXT NOT NULL,
        isLearned INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertFlashcard(Flashcard flashcard) async {
    final db = await database;
    return await db.insert('flashcards', flashcard.toMap());
  }

  Future<List<Flashcard>> getAllFlashcards() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('flashcards');
    return List.generate(maps.length, (i) => Flashcard.fromMap(maps[i]));
  }

  Future<List<Flashcard>> getFlashcardsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'flashcards',
      where: 'category = ?',
      whereArgs: [category],
    );
    return List.generate(maps.length, (i) => Flashcard.fromMap(maps[i]));
  }

  Future<List<Flashcard>> getUnlearnedFlashcards(String? category) async {
    final db = await database;
    String where = 'isLearned = 0';
    List<dynamic> whereArgs = [];

    if (category != null) {
      where += ' AND category = ?';
      whereArgs.add(category);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'flashcards',
      where: where,
      whereArgs: whereArgs,
    );
    return List.generate(maps.length, (i) => Flashcard.fromMap(maps[i]));
  }

  Future<int> updateFlashcard(Flashcard flashcard) async {
    final db = await database;
    return await db.update(
      'flashcards',
      flashcard.toMap(),
      where: 'id = ?',
      whereArgs: [flashcard.id],
    );
  }

  Future<int> deleteFlashcard(int id) async {
    final db = await database;
    return await db.delete('flashcards', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, int>> getCategoryStats(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN isLearned = 1 THEN 1 ELSE 0 END) as learned
      FROM flashcards 
      WHERE category = ?
    ''',
      [category],
    );

    return {
      'total': result.first['total'] ?? 0,
      'learned': result.first['learned'] ?? 0,
    };
  }

  Future<List<String>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT DISTINCT category FROM flashcards ORDER BY category
    ''');

    return result.map((map) => map['category'] as String).toList();
  }
}
