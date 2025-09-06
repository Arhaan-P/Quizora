import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/theme_provider.dart';
import 'categories_screen.dart';
import 'add_flashcard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;

  List<Widget> get _screens => [
    const CategoriesScreen(),
    AddFlashcardScreen(
      onBackPressed: () {
        // Navigate to Categories tab when back button is pressed
        setState(() {
          _selectedIndex = 0;
        });
      },
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Load flashcards when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashcardProvider>().loadFlashcards();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                    const Color(0xFF334155),
                  ]
                : [
                    const Color(0xFFFAFAFA),
                    const Color(0xFFF8FAFC),
                    const Color(0xFFF1F5F9),
                  ],
          ),
        ),
        child: IndexedStack(index: _selectedIndex, children: _screens),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                    : [Colors.white, Colors.grey.shade50],
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
                _animationController.forward().then((_) {
                  _animationController.reverse();
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: isDark
                  ? const Color(0xFF818CF8)
                  : const Color(0xFF6366F1),
              unselectedItemColor: Colors.grey,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(_selectedIndex == 0 ? 8 : 4),
                    decoration: _selectedIndex == 0
                        ? BoxDecoration(
                            color:
                                (isDark
                                        ? const Color(0xFF818CF8)
                                        : const Color(0xFF6366F1))
                                    .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          )
                        : null,
                    child: Icon(
                      _selectedIndex == 0
                          ? Icons.apps_rounded
                          : Icons.apps_outlined,
                      size: 24,
                    ),
                  ),
                  label: 'Categories',
                ),
                BottomNavigationBarItem(
                  icon: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(_selectedIndex == 1 ? 8 : 4),
                    decoration: _selectedIndex == 1
                        ? BoxDecoration(
                            color:
                                (isDark
                                        ? const Color(0xFF818CF8)
                                        : const Color(0xFF6366F1))
                                    .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          )
                        : null,
                    child: Icon(
                      _selectedIndex == 1
                          ? Icons.add_circle_rounded
                          : Icons.add_circle_outline_rounded,
                      size: 24,
                    ),
                  ),
                  label: 'Add Card',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
