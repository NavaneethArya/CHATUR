import 'package:chatur_frontend/Events/models/event_model.dart';
import 'package:chatur_frontend/Events/screens/add_event_with_location.dart';
import 'package:chatur_frontend/Events/screens/all_events.dart';
import 'package:chatur_frontend/Events/screens/bookmarked_events_screen.dart';
import 'package:chatur_frontend/Events/screens/notifications_screen.dart';
import 'package:chatur_frontend/Events/screens/panchayat_login_screen.dart';
import 'package:chatur_frontend/Events/services/event_firebase_service.dart';
import 'package:chatur_frontend/Events/services/notification_service.dart';
import 'package:chatur_frontend/Events/services/panchayat_auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// ============================================
// COLORS & CONSTANTS
// ============================================
class EventColors {
  static const primary = Color(0xFF6C5CE7);
  static const secondary = Color(0xFFFF6B9D);
  static const accent = Color(0xFF00D4FF);
  static const success = Color(0xFF00C896);
  static const background = Color(0xFFF8F9FE);

  static const gradient1 = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradient2 = LinearGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFFFD79A8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradient3 = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF0984E3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const appBarGradient = LinearGradient(
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardShadow = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 8)),
  ];
}

// ============================================
// SHIMMER LOADING WIDGET
// ============================================
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  _ShimmerLoadingState createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.grey[300]!, Colors.grey[200]!, Colors.grey[300]!],
              stops:
                  [
                    _animation.value - 0.3,
                    _animation.value,
                    _animation.value + 0.3,
                  ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

// ============================================
// MAIN EVENT SCREEN
// ============================================
class MainEventScreen extends StatefulWidget {
  const MainEventScreen({super.key});

  @override
  _MainEventScreenState createState() => _MainEventScreenState();
}

class _MainEventScreenState extends State<MainEventScreen>
    with TickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isPanchayatMember = false;
  List<EventModel> _events = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Set<String> _bookmarkedEventIds = {};
  String? _userPhotoUrl;
  String? _userName;
  bool _isLoadingProfile = true;

  late AnimationController _fabController;
  late AnimationController _headerController;
  late AnimationController _fabMenuController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _fabRotation;
  bool _isFabMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkPanchayatStatus();
    _loadEvents();
    _loadBookmarks();
    _loadUserProfile(); // Add this line
  }

  void _loadBookmarks() {
    if (currentUser == null) return;

    EventFirebaseService.getBookmarkedEvents(currentUser!.uid).listen((
      bookmarks,
    ) {
      if (mounted) {
        setState(() {
          _bookmarkedEventIds =
              bookmarks.map((b) => b['eventId'] as String).toSet();
        });
      }
    });
  }

  Future<void> _loadUserProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoadingProfile = false);
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('Profile')
              .doc('main')
              .get();

      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          _userName = data?['name'] ?? currentUser?.displayName ?? 'User';
          _userPhotoUrl = data?['photoUrl'] ?? currentUser?.photoURL;
          _isLoadingProfile = false;
        });
      } else {
        setState(() {
          _userName = currentUser?.displayName ?? 'User';
          _userPhotoUrl = currentUser?.photoURL;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      setState(() {
        _userName = currentUser?.displayName ?? 'User';
        _userPhotoUrl = currentUser?.photoURL;
        _isLoadingProfile = false;
      });
    }
  }

  void _initAnimations() {
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fabMenuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fabScaleAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    );

    _fabRotation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _fabMenuController, curve: Curves.easeInOut),
    );

    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _fabController.forward();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    _headerController.dispose();
    _fabMenuController.dispose();
    super.dispose();
  }

  void _toggleFabMenu() {
    setState(() {
      _isFabMenuOpen = !_isFabMenuOpen;
      if (_isFabMenuOpen) {
        _fabMenuController.forward();
      } else {
        _fabMenuController.reverse();
      }
    });
  }

  Future<void> _checkPanchayatStatus() async {
    if (currentUser?.email != null) {
      final isPanchayat = await PanchayatAuthService.isPanchayatMember(
        currentUser!.email!,
      );
      if (mounted) setState(() => _isPanchayatMember = isPanchayat);
    }
  }

  Future<void> _loadEvents({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    if (mounted) {
      setState(() => forceRefresh ? _isRefreshing = true : _isLoading = true);
    }

    try {
      final events = await EventFirebaseService.getRecentEvents(
        daysBefore: 7,
        daysAfter: 21,
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
        _showSnackBar('Error loading events', isError: true);
      }
    }
  }

  void _updateEventLike(String eventId, String userEmail, bool isLiked) {
    setState(() {
      final eventIndex = _events.indexWhere((e) => e.id == eventId);
      if (eventIndex != -1) {
        final event = _events[eventIndex];
        final updatedLikedBy = List<String>.from(event.likedBy);

        if (isLiked) {
          if (!updatedLikedBy.contains(userEmail)) {
            updatedLikedBy.add(userEmail);
          }
        } else {
          updatedLikedBy.remove(userEmail);
        }

        _events[eventIndex] = EventModel(
          id: event.id,
          heading: event.heading,
          description: event.description,
          imageUrl: event.imageUrl,
          createdBy: event.createdBy,
          createdByEmail: event.createdByEmail,
          eventDate: event.eventDate,
          location: event.location,
          locationName: event.locationName,
          createdAt: event.createdAt,
          likes: updatedLikedBy.length,
          likedBy: updatedLikedBy,
          comments: event.comments,
        );
      }
    });
  }

  void _toggleBookmark(EventModel event, bool isBookmarked) {
    if (currentUser == null) return;

    setState(() {
      if (isBookmarked) {
        _bookmarkedEventIds.add(event.id);
      } else {
        _bookmarkedEventIds.remove(event.id);
      }
    });

    // Fire Firebase call in background
    EventFirebaseService.toggleBookmark(
      currentUser!.uid,
      event.eventDate,
      event.id,
      event.heading,
      event.imageUrl ?? '',
      event.createdBy,
    ).catchError((e) {
      // Revert on error
      setState(() {
        if (isBookmarked) {
          _bookmarkedEventIds.remove(event.id);
        } else {
          _bookmarkedEventIds.add(event.id);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update bookmark'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _navigateToAddEvent() async {
    if (_isPanchayatMember) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddEventWithLocationPage()),
      );
      if (result == true) _loadEvents(forceRefresh: true);
    } else {
      final memberData = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(builder: (_) => PanchayatLoginScreen()),
      );

      if (memberData != null) {
        setState(() => _isPanchayatMember = true);
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEventWithLocationPage(panchayatData: memberData),
          ),
        );
        if (result == true) _loadEvents(forceRefresh: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: EventColors.background,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Container(
        child:
            _isLoading
                ? _buildLoadingShimmer()
                : _events.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                  onRefresh: () => _loadEvents(forceRefresh: true),
                  color: EventColors.primary,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    itemCount: _events.length,
                    itemBuilder:
                        (context, index) => _buildAnimatedEventCard(index),
                  ),
                ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSize _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: BoxDecoration(
          gradient: EventColors.appBarGradient,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          title: Text(
            'Community Events',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          actions: [_buildBookmarkButton(), _buildNotificationButton()],
        ),
      ),
    );
  }

  Widget _buildAppBarButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 24),
      onPressed: onPressed,
    );
  }

  Widget _buildBookmarkButton() {
    return StreamBuilder<int>(
      stream:
          currentUser != null
              ? EventFirebaseService.getBookmarkedEvents(
                currentUser!.uid,
              ).map((list) => list.length)
              : Stream.value(0),
      builder: (context, snapshot) {
        final bookmarkCount = snapshot.data ?? _bookmarkedEventIds.length;
        return Stack(
          children: [
            IconButton(
              icon: Icon(Icons.bookmark_rounded, color: Colors.white, size: 24),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BookmarkedEventsScreen()),
                );
              },
            ),
            if (bookmarkCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    bookmarkCount > 99 ? '99+' : '$bookmarkCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationButton() {
    return _isRefreshing
        ? Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        )
        : StreamBuilder<int>(
          stream: NotificationService.getUnreadCountStream(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;
            return Stack(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NotificationsScreen()),
                    );
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, EventColors.background],
          ),
        ),
        child: Column(
          children: [
            _buildDrawerHeader(),
            Divider(height: 1),
            Expanded(child: _buildDrawerItems()),
            _buildDrawerFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    final userName = _userName ?? 'User';
    final userEmail = currentUser?.email ?? 'user@example.com';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: BoxDecoration(
        gradient: EventColors.appBarGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              gradient: LinearGradient(
                colors: [Colors.white, Colors.white.withOpacity(0.9)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child:
                  _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: _userPhotoUrl!,
                        fit: BoxFit.cover,
                        placeholder:
                            (_, __) => CircularProgressIndicator(
                              strokeWidth: 2,
                              color: EventColors.primary,
                            ),
                        errorWidget:
                            (_, __, ___) => Icon(
                              Icons.person,
                              size: 45,
                              color: EventColors.primary,
                            ),
                      )
                      : Icon(
                        Icons.person,
                        size: 45,
                        color: EventColors.primary,
                      ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            userName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.email_outlined, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    userEmail,
                    style: TextStyle(fontSize: 12, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (_isPanchayatMember) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFf39c12), Color(0xFFe67e22)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Panchayat Member',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrawerItems() {
    final items = [
      {
        'icon': Icons.calendar_month_rounded,
        'title': 'Calendar View',
        'subtitle': 'View all events',
        'gradient': EventColors.gradient1,
        'action': () async {
          Navigator.pop(context);
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AllEventsPage()),
          );
          if (result == true) _loadEvents(forceRefresh: true);
        },
      },
      {
        'icon': Icons.add_circle_outline_rounded,
        'title': 'Add Event',
        'subtitle': 'Create new event',
        'gradient': EventColors.gradient2,
        'action': () {
          Navigator.pop(context);
          _navigateToAddEvent();
        },
      },
      {
        'icon': Icons.notifications_active_rounded,
        'title': 'Notifications',
        'subtitle': 'View notifications',
        'gradient': EventColors.gradient3,
        'action': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NotificationsScreen()),
          );
        },
      },
      {
        'icon': Icons.refresh_rounded,
        'title': 'Refresh Events',
        'subtitle': 'Reload latest',
        'gradient': LinearGradient(
          colors: [Color(0xFF00C896), Color(0xFF00B894)],
        ),
        'action': () {
          Navigator.pop(context);
          _loadEvents(forceRefresh: true);
        },
      },
    ];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SizedBox(height: 8),
        ...items.map(
          (item) => _buildDrawerItem(
            icon: item['icon'] as IconData,
            title: item['title'] as String,
            subtitle: item['subtitle'] as String,
            gradient: item['gradient'] as Gradient,
            onTap: item['action'] as VoidCallback,
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (gradient as LinearGradient).colors.first.withOpacity(
                  0.3,
                ),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildDrawerFooter() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: EventColors.gradient1,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.info_outline, size: 18, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text(
                'Chatur v1.0',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Community Help & Technology for Uplifting Ruralities',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedEventCard(int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: EventCard(
        key: ValueKey(_events[index].id),
        event: _events[index],
        currentUserEmail: currentUser?.email ?? '',
        isPanchayatMember: _isPanchayatMember,
        isBookmarked: _bookmarkedEventIds.contains(_events[index].id),
        onEventChanged: () => _loadEvents(forceRefresh: true),
        onLikeToggled:
            (eventId, userEmail, isLiked) =>
                _updateEventLike(eventId, userEmail, isLiked),
        onBookmarkToggled: (eventId, isBookmarked) {
          _toggleBookmark(_events[index], isBookmarked);
        },
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: EventColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShimmerLoading(
                    width: 48,
                    height: 48,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerLoading(
                          width: 150,
                          height: 16,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        SizedBox(height: 8),
                        ShimmerLoading(
                          width: 100,
                          height: 12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ShimmerLoading(
                width: double.infinity,
                height: 200,
                borderRadius: BorderRadius.circular(16),
              ),
              SizedBox(height: 16),
              ShimmerLoading(
                width: double.infinity,
                height: 16,
                borderRadius: BorderRadius.circular(8),
              ),
              SizedBox(height: 8),
              ShimmerLoading(
                width: 250,
                height: 16,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(50),
              decoration: BoxDecoration(
                gradient: EventColors.gradient1,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: EventColors.primary.withOpacity(0.3),
                    blurRadius: 30,
                    offset: Offset(0, 15),
                  ),
                ],
              ),
              child: Icon(
                Icons.event_busy_rounded,
                size: 90,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 32),
            Text(
              'No Events Yet',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Be the first to create a\ncommunity event',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: EventColors.gradient1,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: EventColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _loadEvents(forceRefresh: true),
                icon: Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  'Refresh',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        if (_isFabMenuOpen)
          GestureDetector(
            onTap: _toggleFabMenu,
            child: Container(
              color: Colors.black.withOpacity(0.3),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
          ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_isFabMenuOpen) ...[
              _buildFabMenuItem(
                icon: Icons.calendar_month_rounded,
                label: 'View Calendar',
                gradient: EventColors.gradient1,
                onTap: () async {
                  _toggleFabMenu();
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AllEventsPage()),
                  );
                  if (result == true) _loadEvents(forceRefresh: true);
                },
                delay: 0,
              ),
              SizedBox(height: 12),
              _buildFabMenuItem(
                icon: Icons.refresh_rounded,
                label: 'Refresh',
                gradient: EventColors.gradient3,
                onTap: () {
                  _toggleFabMenu();
                  _loadEvents(forceRefresh: true);
                },
                delay: 50,
              ),
              SizedBox(height: 16),
            ],
            ScaleTransition(
              scale: _fabScaleAnimation,
              child: RotationTransition(
                turns: _fabRotation,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: EventColors.gradient2,
                    boxShadow: [
                      BoxShadow(
                        color: EventColors.secondary.withOpacity(0.4),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
                    onPressed:
                        _isFabMenuOpen ? _toggleFabMenu : _navigateToAddEvent,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    icon: Icon(
                      _isFabMenuOpen ? Icons.close_rounded : Icons.add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    label: Text(
                      _isFabMenuOpen ? 'Close' : 'Add Event',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFabMenuItem({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
    required int delay,
  }) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 200 + delay),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutBack,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (gradient as LinearGradient).colors.first.withOpacity(
                  0.4,
                ),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// EVENT CARD
// ============================================
class EventCard extends StatefulWidget {
  final EventModel event;
  final String currentUserEmail;
  final bool isPanchayatMember;
  final bool isBookmarked;
  final VoidCallback onEventChanged;
  final Function(String eventId, String userEmail, bool isLiked)? onLikeToggled;
  final Function(String eventId, bool isBookmarked)? onBookmarkToggled;

  const EventCard({
    super.key,
    required this.event,
    required this.currentUserEmail,
    required this.isPanchayatMember,
    this.isBookmarked = false,
    required this.onEventChanged,
    this.onLikeToggled,
    this.onBookmarkToggled,
  });

  @override
  _EventCardState createState() => _EventCardState();
}

class _EventCardState extends State<EventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeController;
  late Animation<double> _likeAnimation;

  bool get isLiked => widget.event.likedBy.contains(widget.currentUserEmail);

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _likeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _likeController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  Future<void> _toggleBookmark() async {
    if (widget.onBookmarkToggled == null) return;

    final wasBookmarked = widget.isBookmarked;
    final newBookmarkState = !wasBookmarked;

    // Optimistic update
    widget.onBookmarkToggled!(widget.event.id, newBookmarkState);
  }

  Future<void> _toggleLike() async {
    // Optimistic update - update UI immediately
    final wasLiked = isLiked;
    final newLikedState = !wasLiked;

    // Update local state immediately via callback
    if (widget.onLikeToggled != null) {
      widget.onLikeToggled!(
        widget.event.id,
        widget.currentUserEmail,
        newLikedState,
      );
    }

    // Play animation without blocking
    _likeController.forward().then((_) => _likeController.reverse());

    // Fire Firebase call in background without waiting
    EventFirebaseService.toggleLike(
      widget.event.eventDate,
      widget.event.id,
      widget.currentUserEmail,
    ).catchError((e) {
      // Revert on error
      if (widget.onLikeToggled != null) {
        widget.onLikeToggled!(
          widget.event.id,
          widget.currentUserEmail,
          wasLiked,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update like'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => CommentBottomSheet(
            event: widget.event,
            currentUserEmail: widget.currentUserEmail,
            onCommentAdded: widget.onEventChanged,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (widget.event.imageUrl != null) _buildImage(),
          _buildActionButtons(),
          if (widget.event.likes > 0) _buildLikesCount(),
          _buildEventDetails(),
          if (widget.event.comments.isNotEmpty) _buildCommentsPreview(),
          _buildDateLocation(),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: EventColors.gradient1,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: EventColors.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 24,
              child: Icon(Icons.account_balance, color: Colors.white, size: 24),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.createdBy,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Container(
                  margin: EdgeInsets.only(top: 4),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFf39c12), Color(0xFFe67e22)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Panchayat Member',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.isPanchayatMember)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: Colors.grey[700]),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => AddEventWithLocationPage(
                              existingEvent: widget.event,
                            ),
                      ),
                    ).then((result) {
                      if (result == true) widget.onEventChanged();
                    });
                  } else if (value == 'delete') {
                    _deleteEvent();
                  }
                },
                itemBuilder:
                    (context) => [
                      _buildPopupItem(
                        'edit',
                        Icons.edit,
                        'Edit Event',
                        Colors.blue,
                      ),
                      _buildPopupItem(
                        'delete',
                        Icons.delete,
                        'Delete Event',
                        Colors.red,
                      ),
                    ],
              ),
            ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    String value,
    IconData icon,
    String text,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  color == Colors.blue
                      ? Colors.blue.shade50
                      : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return GestureDetector(
      onDoubleTap: _toggleLike,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(0),
            child: CachedNetworkImage(
              imageUrl: widget.event.imageUrl!,
              width: double.infinity,
              height: 400,
              fit: BoxFit.cover,
              placeholder:
                  (_, __) => Container(
                    height: 400,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey[200]!, Colors.grey[300]!],
                      ),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          EventColors.primary,
                        ),
                      ),
                    ),
                  ),
              errorWidget:
                  (_, __, ___) => Container(
                    height: 400,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey[200]!, Colors.grey[300]!],
                      ),
                    ),
                    child: Icon(Icons.error, size: 50, color: Colors.red),
                  ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          ScaleTransition(
            scale: _likeAnimation,
            child: _buildActionButton(
              isLiked ? Icons.favorite : Icons.favorite_border,
              isLiked ? Colors.red : Colors.grey[700]!,
              _toggleLike,
              isLiked ? Colors.red[50]! : Colors.grey[100]!,
            ),
          ),
          SizedBox(width: 8),
          _buildActionButton(
            Icons.comment_rounded,
            Colors.grey[700]!,
            _showComments,
            Colors.grey[100]!,
          ),
          SizedBox(width: 8),
          _buildActionButton(Icons.share_rounded, Colors.grey[700]!, () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Share feature coming soon!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }, Colors.grey[100]!),
          Spacer(),
          _buildActionButton(
            widget.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            widget.isBookmarked ? EventColors.primary : Colors.grey[700]!,
            _toggleBookmark,
            widget.isBookmarked
                ? EventColors.primary.withOpacity(0.1)
                : Colors.grey[100]!,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    Color iconColor,
    VoidCallback onPressed,
    Color bgColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor, size: 26),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildLikesCount() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.favorite, color: Colors.red, size: 16),
          SizedBox(width: 6),
          Text(
            '${widget.event.likes} ${widget.event.likes == 1 ? "like" : "likes"}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetails() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.event.heading,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
              letterSpacing: 0.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),
          Text(
            widget.event.description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsPreview() {
    final displayComments = widget.event.comments.take(2).toList();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...displayComments.map(
            (comment) => Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black87, fontSize: 14),
                  children: [
                    TextSpan(
                      text: '${comment.userName} ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: comment.text),
                  ],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (widget.event.comments.length > 2)
            GestureDetector(
              onTap: _showComments,
              child: Container(
                margin: EdgeInsets.only(top: 4),
                child: Text(
                  'View all ${widget.event.comments.length} comments',
                  style: TextStyle(
                    color: EventColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateLocation() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  EventColors.primary.withOpacity(0.1),
                  EventColors.accent.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: EventColors.gradient1,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat(
                      'EEEE, MMM dd, yyyy',
                    ).format(widget.event.eventDate),
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.event.locationName != null) ...[
            SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showLocationMap(),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red[50]!, Colors.orange[50]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red[400]!, Colors.orange[400]!],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.event.locationName!,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.red[400],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showLocationMap() {
    if (widget.event.location != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => EventLocationMapScreen(
                location: widget.event.location!,
                locationName: widget.event.locationName ?? 'Event Location',
              ),
        ),
      );
    }
  }

  void _deleteEvent() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 28,
                  ),
                ),
                SizedBox(width: 12),
                Text('Delete Event?'),
              ],
            ),
            content: Text(
              'Are you sure you want to delete "${widget.event.heading}"? This action cannot be undone.',
              style: TextStyle(fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red, Colors.red[700]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await EventFirebaseService.deleteEvent(
                        widget.event.eventDate,
                        widget.event.id,
                      );
                      Navigator.pop(context);
                      widget.onEventChanged();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 10),
                              Text('Event deleted successfully'),
                            ],
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete event'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: Text('Delete', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
    );
  }
}

// ============================================
// COMMENT BOTTOM SHEET
// ============================================
class CommentBottomSheet extends StatefulWidget {
  final EventModel event;
  final String currentUserEmail;
  final VoidCallback onCommentAdded;

  const CommentBottomSheet({
    super.key,
    required this.event,
    required this.currentUserEmail,
    required this.onCommentAdded,
  });

  @override
  _CommentBottomSheetState createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final _commentController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;
    setState(() => _isPosting = true);

    try {
      final userName =
          FirebaseAuth.instance.currentUser?.displayName ??
          widget.currentUserEmail.split('@')[0];
      await EventFirebaseService.addComment(
        widget.event.eventDate,
        widget.event.id,
        userName,
        widget.currentUserEmail,
        _commentController.text.trim(),
      );

      _commentController.clear();
      FocusScope.of(context).unfocus();
      widget.onCommentAdded();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Comment added!'),
            ],
          ),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add comment'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return DateFormat('MMM dd, yyyy').format(timestamp);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: EventColors.gradient1,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.comment,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Comments',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1),
              Expanded(
                child:
                    widget.event.comments.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  gradient: EventColors.gradient1,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.comment_outlined,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'No comments yet',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Be the first to comment!',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          controller: scrollController,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          itemCount: widget.event.comments.length,
                          itemBuilder: (context, index) {
                            final comment =
                                widget.event.comments.reversed.toList()[index];
                            return Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: EventColors.gradient3,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: EventColors.accent.withOpacity(
                                            0.3,
                                          ),
                                          blurRadius: 8,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      backgroundColor: Colors.transparent,
                                      radius: 20,
                                      child: Text(
                                        comment.userName.isNotEmpty
                                            ? comment.userName[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.grey[50]!,
                                                Colors.grey[100]!,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.03,
                                                ),
                                                blurRadius: 5,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                comment.userName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: EventColors.primary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 6),
                                              Text(
                                                comment.text,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                  height: 1.4,
                                                ),
                                                maxLines: 10,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Padding(
                                          padding: EdgeInsets.only(left: 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 12,
                                                color: Colors.grey[500],
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                _formatTimestamp(
                                                  comment.timestamp,
                                                ),
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            maxLines: null,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          gradient: EventColors.gradient1,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: EventColors.primary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          radius: 24,
                          child:
                              _isPosting
                                  ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : IconButton(
                                    icon: Icon(
                                      Icons.send,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: _postComment,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================
// EVENT LOCATION MAP SCREEN
// ============================================
class EventLocationMapScreen extends StatelessWidget {
  final GeoPoint location;
  final String locationName;

  const EventLocationMapScreen({
    super.key,
    required this.location,
    required this.locationName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, color: Colors.red[400], size: 20),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Event Location',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(location.latitude, location.longitude),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.chatur.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(location.latitude, location.longitude),
                    width: 150,
                    height: 100,
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: EventColors.gradient1,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            locationName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.4),
                                blurRadius: 15,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 50,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: EventColors.gradient2,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.place_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              locationName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: EventColors.gradient1,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: EventColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.white),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Navigation feature coming soon!',
                                  ),
                                ),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: EventColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.directions_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      label: Text(
                        'Get Directions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
