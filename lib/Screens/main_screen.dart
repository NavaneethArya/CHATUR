import 'package:chatur_frontend/Events/screens/main_event_screen.dart';
import 'package:chatur_frontend/My_Store/MainStorePage.dart';
import 'package:chatur_frontend/Schemes/state/allSchemeDetailState.dart';
import 'package:chatur_frontend/Skills/skills_screen.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _rippleController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;

  final List<Widget> _screens = [
    HomeScreen(),
    SchemeDetailPage(),
    SkillsScreen(),
    MainEventScreen(),
    MainStorePage(),
  ];

  final List<NavItem> _navItems = [
    NavItem(icon: Icons.home_rounded, label: 'Home', color: Color(0xFF6366F1)),
    NavItem(
      icon: Icons.account_balance_rounded,
      label: 'Schemes',
      color: Color.fromARGB(255, 72, 143, 236),
    ),
    NavItem(
      icon: Icons.handyman_rounded,
      label: 'Skills',
      color: Color(0xFF10B981),
    ),
    NavItem(
      icon: Icons.event_rounded,
      label: 'Events',
      color: Color(0xFFF59E0B),
    ),
    NavItem(
      icon: Icons.store_rounded,
      label: 'Store',
      color: Color.fromARGB(255, 200, 92, 246),
    ),
  ];

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOutCubic,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _rippleAnimation = CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    );

    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      _slideController.forward(from: 0);
      _scaleController.forward(from: 0);
      _rippleController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [Expanded(child: _screens[_currentIndex])]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, -4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: Container(
            height: 68,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_navItems.length, (index) {
                return Expanded(child: _buildNavItem(index));
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final navItem = _navItems[index];
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: AnimatedBuilder(
          animation: Listenable.merge([_scaleAnimation, _slideAnimation]),
          builder: (context, child) {
            final scale = isActive ? 1.0 + (0.08 * _scaleAnimation.value) : 1.0;

            return Transform.scale(
              scale: scale,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Pulsing background circle for active item
                      if (isActive)
                        TweenAnimationBuilder<double>(
                          key: ValueKey('pulse_$index'),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 1000),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: 1 + (value * 0.4),
                              child: Opacity(
                                opacity: (1 - value) * 0.3,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: navItem.color.withOpacity(0.2),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      // Icon background circle with color
                      AnimatedContainer(
                        duration: Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isActive
                                  ? navItem.color
                                  : Colors.grey.withOpacity(0.1),
                          boxShadow:
                              isActive
                                  ? [
                                    BoxShadow(
                                      color: navItem.color.withOpacity(0.4),
                                      blurRadius: 10,
                                      spreadRadius: 0,
                                    ),
                                  ]
                                  : [],
                        ),
                        child: AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: RotationTransition(
                                turns: Tween<double>(
                                  begin: 0.8,
                                  end: 1.0,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Icon(
                            navItem.icon,
                            key: ValueKey('$index-$isActive'),
                            color: isActive ? Colors.white : Colors.grey[600],
                            size: isActive ? 24 : 21,
                          ),
                        ),
                      ),
                      // Sparkle effect
                      if (isActive)
                        Positioned(
                          top: -1,
                          right: -1,
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey('sparkle_$index'),
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 600),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: navItem.color.withOpacity(0.8),
                                        blurRadius: 5,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    style: TextStyle(
                      fontSize: isActive ? 12 : 11,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      color: isActive ? navItem.color : Colors.grey[600],
                      letterSpacing: 0.2,
                      height: 1.1,
                    ),
                    child: Text(
                      navItem.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final String label;
  final Color color;

  NavItem({required this.icon, required this.label, required this.color});
}
