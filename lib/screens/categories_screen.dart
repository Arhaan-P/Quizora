import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/flashcard_provider.dart';
import '../models/category.dart';
import 'study_screen.dart';
import 'quiz_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with TickerProviderStateMixin {
  List<Category> categories = [];
  bool isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    loadCategories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh if we're not currently loading and the route is visible
    final route = ModalRoute.of(context);
    if (route != null &&
        route.isCurrent &&
        !isLoading &&
        categories.isNotEmpty) {
      // Refresh categories when returning to this screen or when flashcards change
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshCategories();
        }
      });
    } else if (route != null &&
        route.isCurrent &&
        categories.isEmpty &&
        !isLoading) {
      // Load categories if screen is visible and we have no data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          loadCategories();
        }
      });
    }
  }

  Future<void> _refreshCategories() async {
    await loadCategories();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadCategories() async {
    final flashcardProvider = context.read<FlashcardProvider>();
    await flashcardProvider.loadCategories();
    setState(() {
      categories = flashcardProvider.categories;
      isLoading = false;
    });
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Consumer<FlashcardProvider>(
      builder: (context, flashcardProvider, child) {
        // Auto-refresh categories when flashcard provider changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !isLoading) {
            loadCategories();
          }
        });

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  isLoading = true;
                });
                await loadCategories();
              },
              child: CustomScrollView(
                slivers: [
                  // Simple App Bar
                  SliverAppBar(
                    expandedHeight: 100,
                    floating: false,
                    pinned: true,
                    backgroundColor: isDark
                        ? const Color(0xFF1A1A2E)
                        : const Color(0xFFF8FAFC),
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        'Quizora',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 24,
                          color: isDark ? Colors.white : Colors.grey[800],
                        ),
                      ),
                      centerTitle: false,
                    ),
                    actions: [
                      Container(
                        margin: const EdgeInsets.only(
                          right: 16,
                          top: 8,
                          bottom: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                        ),
                        child: IconButton(
                          icon: Icon(
                            themeProvider.isDarkMode
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            color: isDark ? Colors.white : Colors.grey[700],
                          ),
                          onPressed: () => themeProvider.toggleTheme(),
                        ),
                      ),
                    ],
                  ),

                  // Content
                  isLoading
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: isDark
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading your study categories...',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : categories.isEmpty
                      ? SliverFillRemaining(child: _buildEmptyState())
                      : SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.8,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              return AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  final animationValue =
                                      Tween<double>(begin: 0.0, end: 1.0)
                                          .animate(
                                            CurvedAnimation(
                                              parent: _animationController,
                                              curve: Interval(
                                                (index * 0.1).clamp(0.0, 1.0),
                                                ((index * 0.1) + 0.3).clamp(
                                                  0.0,
                                                  1.0,
                                                ),
                                                curve: Curves.easeOut,
                                              ),
                                            ),
                                          )
                                          .value;

                                  return Transform.translate(
                                    offset: Offset(
                                      0,
                                      50 * (1 - animationValue),
                                    ),
                                    child: Opacity(
                                      opacity: animationValue,
                                      child: _buildCategoryCard(
                                        categories[index],
                                        index,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }, childCount: categories.length),
                          ),
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No flashcards yet!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first flashcard to get started',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Category category, int index) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF2D2D44) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF404040) : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.read<FlashcardProvider>().loadFlashcards(category.name);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudyScreen(category: category.name),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isDark
                            ? const Color(0xFF3D3D5C)
                            : Colors.grey[100],
                      ),
                      child: Text(
                        category.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Category name
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                ),

                const SizedBox(height: 8),
                const Spacer(),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: isDark ? Colors.blue[700] : Colors.blue[600],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              context.read<FlashcardProvider>().loadFlashcards(
                                category.name,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      StudyScreen(category: category.name),
                                ),
                              );
                            },
                            child: const Center(
                              child: Text(
                                'Study',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey[600]!
                                : Colors.grey[400]!,
                            width: 1,
                          ),
                          color: Colors.transparent,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      QuizScreen(category: category.name),
                                ),
                              );
                            },
                            child: Center(
                              child: Text(
                                'Quiz',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
