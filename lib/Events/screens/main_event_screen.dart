import 'package:chatur_frontend/Events/events_screen.dart';
import 'package:chatur_frontend/Events/models/event_model.dart';
import 'package:chatur_frontend/Events/models/notification_model.dart';
import 'package:chatur_frontend/Events/screens/add_event_with_location.dart';
import 'package:chatur_frontend/Events/screens/all_events.dart';
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

// Modern Color Palette - ADD THIS AFTER IMPORTS
class EventColors {
  static const primary = Color(0xFF6C5CE7);
  static const primaryDark = Color(0xFF5F3DC4);
  static const secondary = Color(0xFFFF6B9D);
  static const accent = Color(0xFF00D4FF);
  static const success = Color(0xFF00C896);
  static const warning = Color(0xFFFD79A8);
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
}

class MainEventScreen extends StatefulWidget {
  @override
  _MainEventScreenState createState() => _MainEventScreenState();
}

// REPLACE THE EXISTING STATE VARIABLES WITH THESE
class _MainEventScreenState extends State<MainEventScreen> with TickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isPanchayatMember = false;
  List<EventModel> _events = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // ADD THESE NEW ANIMATION CONTROLLERS
  late AnimationController _fabController;
  late AnimationController _headerController;
  late Animation<double> _fabScale;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    
    // ADD THESE ANIMATION INITIALIZATIONS
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fabScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic));
    
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _fabController.forward();
    });
    
    _checkPanchayatStatus();
    _loadEvents();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _checkPanchayatStatus() async {
    if (currentUser != null && currentUser!.email != null) {
      final isPanchayat =
          await PanchayatAuthService.isPanchayatMember(currentUser!.email!);
      if (mounted) {
        setState(() => _isPanchayatMember = isPanchayat);
      }
    }
  }

  Future<void> _loadEvents({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    if (mounted) {
      setState(() {
        if (forceRefresh) {
          _isRefreshing = true;
        } else {
          _isLoading = true;
        }
      });
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
      print('❌ Error loading events: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Error loading events')),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _navigateToAddEvent() async {
    if (_isPanchayatMember) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddEventWithLocationPage()),
      );

      if (result == true) {
        _loadEvents(forceRefresh: true);
      }
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
            builder: (_) =>
                AddEventWithLocationPage(panchayatData: memberData),
          ),
        );

        if (result == true) {
          _loadEvents(forceRefresh: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      
      // ============================================
      // APP BAR WITH DRAWER & NOTIFICATIONS
      // ============================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, color: Colors.black87, size: 28),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Row(
          children: [
            Icon(Icons.event, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text(
              'Community Events',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          // Loading indicator when refreshing
          if (_isRefreshing)
            Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            // UPDATED: Notification bell with real-time badge
            StreamBuilder<int>(
              stream: NotificationService.getUnreadCountStream(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                
                return Stack(
                  children: [
                    IconButton(
                      icon: Icon(Icons.notifications_outlined,
                          color: Colors.black87, size: 28),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotificationsScreen(),
                          ),
                        );
                      },
                      tooltip: 'Notifications',
                    ),
                    // Badge showing unread count
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
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
            ),
        ],
      ),

      // ============================================
      // DRAWER WITH PROFILE & MENU
      // ============================================
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Profile Header
              _buildDrawerHeader(),
              
              Divider(height: 1),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(
                      icon: Icons.calendar_month_rounded,
                      title: 'Calendar View',
                      subtitle: 'View all events in calendar',
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AllEventsPage()),
                        );
                        if (result == true) {
                          _loadEvents(forceRefresh: true);
                        }
                      },
                    ),
                    
                    _buildDrawerItem(
                      icon: Icons.add_circle_outline_rounded,
                      title: 'Add Event',
                      subtitle: 'Create a new community event',
                      color: Colors.deepPurple,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToAddEvent();
                      },
                    ),

                    Divider(),

                    // NEW: Notifications menu item
                    _buildDrawerItem(
                      icon: Icons.notifications_rounded,
                      title: 'Notifications',
                      subtitle: 'View all event notifications',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => NotificationsScreen()),
                        );
                      },
                    ),

                    _buildDrawerItem(
                      icon: Icons.refresh_rounded,
                      title: 'Refresh Events',
                      subtitle: 'Reload latest events',
                      onTap: () {
                        Navigator.pop(context);
                        _loadEvents(forceRefresh: true);
                      },
                    ),

                    Divider(),

                    _buildDrawerItem(
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      subtitle: 'App preferences',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Settings coming soon!')),
                        );
                      },
                    ),

                    _buildDrawerItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      subtitle: 'Get help using Chatur',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Help section coming soon!')),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Footer
              _buildDrawerFooter(),
            ],
          ),
        ),
      ),

      // ============================================
      // BODY - EVENTS LIST
      // ============================================
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading events...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : _events.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => _loadEvents(forceRefresh: true),
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      return EventCard(
                        key: ValueKey(_events[index].id),
                        event: _events[index],
                        currentUserEmail: currentUser?.email ?? '',
                        isPanchayatMember: _isPanchayatMember,
                        onEventChanged: () => _loadEvents(forceRefresh: true),
                      );
                    },
                  ),
                ),

      // ============================================
      // FAB - ADD EVENT
      // ============================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddEvent,
        backgroundColor: Colors.deepPurple,
        icon: Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Event',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 6,
      ),
    );
  }

  // ============================================
  // DRAWER HEADER WITH PROFILE
  // ============================================
  Widget _buildDrawerHeader() {
    final userName = currentUser?.displayName ?? 'User';
    final userEmail = currentUser?.email ?? 'user@example.com';
    final userPhone = currentUser?.phoneNumber ?? 'Not provided';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple,
            Colors.deepPurple[300]!,
            Colors.purple[200]!,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: currentUser?.photoURL != null
                  ? CachedNetworkImage(
                      imageUrl: currentUser!.photoURL!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.deepPurple,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.deepPurple,
                    ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            userName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.email_outlined, size: 14, color: Colors.white70),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  userEmail,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 14, color: Colors.white70),
              SizedBox(width: 6),
              Text(
                userPhone,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          if (_isPanchayatMember) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Panchayat Member',
                    style: TextStyle(
                      fontSize: 12,
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

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? Colors.deepPurple).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: color ?? Colors.deepPurple,
          size: 24,
        ),
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
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Widget _buildDrawerFooter() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text(
                'Chatur v1.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Community Help & Technology for Uplifting Ruralities',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
              padding: EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.deepPurple[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_rounded,
                size: 80,
                color: Colors.deepPurple[300],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No Events Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Be the first to create a community event',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadEvents(forceRefresh: true),
              icon: Icon(Icons.refresh, color: Colors.white),
              label: Text('Refresh', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// EVENT CARD - Instagram Post Style
// ============================================

class EventCard extends StatefulWidget {
  final EventModel event;
  final String currentUserEmail;
  final bool isPanchayatMember;
  final VoidCallback onEventChanged;

  const EventCard({
    Key? key,
    required this.event,
    required this.currentUserEmail,
    required this.isPanchayatMember,
    required this.onEventChanged,
  }) : super(key: key);

  @override
  _EventCardState createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _showAllComments = false;

  bool get isLiked => widget.event.likedBy.contains(widget.currentUserEmail);

  Future<void> _toggleLike() async {
    try {
      await EventFirebaseService.toggleLike(
        widget.event.eventDate,
        widget.event.id,
        widget.currentUserEmail,
      );
      
      // Trigger refresh to show updated like count
      widget.onEventChanged();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update like')),
      );
    }
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentBottomSheet(
        event: widget.event,
        currentUserEmail: widget.currentUserEmail,
        onCommentAdded: widget.onEventChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
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
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.deepPurple[100],
            child: Icon(Icons.account_balance, color: Colors.deepPurple),
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
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Panchayat Member',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (widget.isPanchayatMember)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEventWithLocationPage(
                        existingEvent: widget.event,
                      ),
                    ),
                  ).then((result) {
                    if (result == true) {
                      widget.onEventChanged();
                    }
                  });
                } else if (value == 'delete') {
                  _deleteEvent();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 10),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return GestureDetector(
      onDoubleTap: _toggleLike,
      child: CachedNetworkImage(
        imageUrl: widget.event.imageUrl!,
        width: double.infinity,
        height: 400,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 400,
          color: Colors.grey[200],
          child: Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          height: 400,
          color: Colors.grey[200],
          child: Icon(Icons.error, size: 50, color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : Colors.black87,
              size: 28,
            ),
            onPressed: _toggleLike,
          ),
          IconButton(
            icon: Icon(Icons.comment_rounded, color: Colors.black87, size: 28),
            onPressed: _showComments,
          ),
          Spacer(),
          IconButton(
            icon: Icon(Icons.bookmark_border, color: Colors.black87, size: 28),
            onPressed: () {
              // TODO: Bookmark functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Bookmark feature coming soon!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLikesCount() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        '${widget.event.likes} ${widget.event.likes == 1 ? "like" : "likes"}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildEventDetails() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.black87, fontSize: 14),
              children: [
                TextSpan(
                  text: widget.event.heading,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextSpan(text: '\n${widget.event.description}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsPreview() {
    final displayComments = _showAllComments
        ? widget.event.comments
        : widget.event.comments.take(2).toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...displayComments.map((comment) => Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.black87, fontSize: 14),
                    children: [
                      TextSpan(
                        text: comment.userName + ' ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: comment.text),
                    ],
                  ),
                ),
              )),
          if (widget.event.comments.length > 2 && !_showAllComments)
            GestureDetector(
              onTap: _showComments,
              child: Text(
                'View all ${widget.event.comments.length} comments',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              SizedBox(width: 6),
              Text(
                DateFormat('EEEE, MMM dd, yyyy')
                    .format(widget.event.eventDate),
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (widget.event.locationName != null) ...[
            SizedBox(height: 4),
            GestureDetector(
              onTap: () => _showLocationMap(),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.red[400]),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.event.locationName!,
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
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

  void _showLocationMap() {
    if (widget.event.location != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventLocationMapScreen(
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('Delete Event?'),
          ],
        ),
        content:
            Text('Are you sure you want to delete "${widget.event.heading}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await EventFirebaseService.deleteEvent(
                  widget.event.eventDate,
                  widget.event.id,
                );
                Navigator.pop(context);

                widget.onEventChanged();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Event deleted successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete event')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
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
    Key? key,
    required this.event,
    required this.currentUserEmail,
    required this.onCommentAdded,
  }) : super(key: key);

  @override
  _CommentBottomSheetState createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isPosting = false;

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isPosting = true);

    try {
      final userName = FirebaseAuth.instance.currentUser?.displayName ??
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
          content: Text('Comment added!'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
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
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(),
              Expanded(
                child: widget.event.comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.comment_outlined,
                                size: 60, color: Colors.grey[300]),
                            SizedBox(height: 16),
                            Text(
                              'No comments yet',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Be the first to comment!',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: widget.event.comments.length,
                        itemBuilder: (context, index) {
                          final comment =
                              widget.event.comments.reversed.toList()[index];
                          return _buildCommentItem(comment);
                        },
                      ),
              ),
              Container(
                padding: EdgeInsets.all(12),
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
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                          ),
                          maxLines: null,
                        ),
                      ),
                      SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        child: _isPosting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton(
                                icon: Icon(Icons.send, color: Colors.white),
                                onPressed: _postComment,
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

  Widget _buildCommentItem(Comment comment) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Text(
              comment.userName.isNotEmpty
                  ? comment.userName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.userName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        comment.text,
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _formatTimestamp(comment.timestamp),
                  style: TextStyle(
                    color: Colors.grey[600],
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
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ============================================
// EVENT LOCATION MAP SCREEN (FIXED)
// ============================================

class EventLocationMapScreen extends StatelessWidget {
  final GeoPoint location;
  final String locationName;

  const EventLocationMapScreen({
    Key? key,
    required this.location,
    required this.locationName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Location'),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FlutterMap(
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
                width: 80,
                height: 80,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        locationName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 4),
                    Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Open in maps app (future feature)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Navigation feature coming soon!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: Icon(Icons.directions, color: Colors.white),
        label: Text('Navigate', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}