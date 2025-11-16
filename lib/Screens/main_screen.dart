import 'package:chatur_frontend/Events/screens/main_event_screen.dart';
import 'package:chatur_frontend/My_Store/MainStorePage.dart';
import 'package:chatur_frontend/Schemes/state/allSchemeDetailState.dart';
import 'package:chatur_frontend/Skills/skills_screen.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<Widget> _screens = [
    HomeScreen(),
    SchemeDetailPage(),
    SkillsScreen(),
    MainEventScreen(),
    MainStorePage(),
  ];

  final List<NavItem> _navItems = [
    NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      color: Color(0xFF5D3FD3),
    ),
    NavItem(
      icon: Icons.account_balance_outlined,
      activeIcon: Icons.account_balance_rounded,
      label: 'Schemes',
      color: Color(0xFFE67E22),
    ),
    NavItem(
      icon: Icons.handyman_outlined,
      activeIcon: Icons.handyman_rounded,
      label: 'Skills',
      color: Color(0xFF27AE60),
    ),
    NavItem(
      icon: Icons.event_outlined,
      activeIcon: Icons.event_rounded,
      label: 'Events',
      color: Color(0xFF9B59B6),
    ),
    NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      color: Color(0xFF3498DB),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: _screens[_currentIndex],
    extendBody: false,  // ✅ Changed from true to false - this reserves space
    bottomNavigationBar: Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_navItems.length, (index) {
                  return _buildNavItem(index);
                }),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildNavItem(int index) {
    final navItem = _navItems[index];
    final isActive = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(12),
        splashColor: navItem.color.withOpacity(0.2),
        highlightColor: navItem.color.withOpacity(0.1),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color:
                isActive ? navItem.color.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      isActive ? navItem.activeIcon : navItem.icon,
                      key: ValueKey(isActive),
                      color: isActive ? navItem.color : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  if (isActive)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: FadeTransition(
                        opacity: _animation,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: navItem.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: navItem.color.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? navItem.color : Colors.grey[600],
                  letterSpacing: 0.3,
                ),
                child: Text(navItem.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}
