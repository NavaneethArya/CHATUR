import 'package:chatur_frontend/Events/models/event_model.dart';
import 'package:chatur_frontend/Events/screens/add_event_with_location.dart';
import 'package:chatur_frontend/Events/screens/panchayat_login_screen.dart';
import 'package:chatur_frontend/Events/screens/yearly_calendar_page.dart';
import 'package:chatur_frontend/Events/services/event_firebase_service.dart';
import 'package:chatur_frontend/Events/services/panchayat_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllEventsPage extends StatefulWidget {
  const AllEventsPage({super.key});

  @override
  _AllEventsPageState createState() => _AllEventsPageState();
}

class _AllEventsPageState extends State<AllEventsPage>
    with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isExpanded = false;
  bool _isDark = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // User info
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isPanchayatMember = false;
  bool _isCheckingPermissions = true;

  // Store events by date
  Map<DateTime, List<EventModel>> _eventsByDate = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    // Check user permissions
    _checkPanchayatStatus();

    // Load events for current month
    _loadEventsForMonth();
  }

  // ============================================
  // CHECK IF USER IS PANCHAYAT MEMBER
  // ============================================
  Future<void> _checkPanchayatStatus() async {
    if (currentUser != null && currentUser!.email != null) {
      try {
        final isPanchayat = await PanchayatAuthService.isPanchayatMember(
          currentUser!.email!,
        );
        if (mounted) {
          setState(() {
            _isPanchayatMember = isPanchayat;
            _isCheckingPermissions = false;
          });
        }
      } catch (e) {
        print('Error checking panchayat status: $e');
        if (mounted) {
          setState(() {
            _isPanchayatMember = false;
            _isCheckingPermissions = false;
          });
        }
      }
    } else {
      setState(() {
        _isPanchayatMember = false;
        _isCheckingPermissions = false;
      });
    }
  }

  // ============================================
  // LOAD EVENTS FROM FIREBASE
  // ============================================
  Future<void> _loadEventsForMonth() async {
    setState(() => _isLoading = true);

    try {
      final events = await EventFirebaseService.getEventsForMonth(_focusedDay);

      if (mounted) {
        setState(() {
          _eventsByDate = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading events: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Get events for a specific day
  List<EventModel> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _eventsByDate[normalizedDay] ?? [];
  }

  // ============================================
  // ADD/EDIT EVENT - PANCHAYAT ONLY
  // ============================================
  Future<void> _openAddEvent({
    EventModel? eventToUpdate,
    DateTime? date,
  }) async {
    // Check if user is panchayat member
    if (!_isPanchayatMember) {
      // Show login dialog
      final memberData = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(builder: (_) => PanchayatLoginScreen()),
      );

      if (memberData != null) {
        // User successfully logged in as panchayat
        setState(() => _isPanchayatMember = true);

        // Now proceed to add event
        _navigateToAddEvent(
          eventToUpdate: eventToUpdate,
          memberData: memberData,
        );
      }
    } else {
      // Already panchayat member, fetch data and proceed
      Map<String, dynamic>? panchayatData;
      if (currentUser?.email != null) {
        try {
          final querySnapshot = await FirebaseFirestore.instance
              .collection('panchayat_members')
              .where('email', isEqualTo: currentUser!.email!)
              .limit(1)
              .get();
          
          if (querySnapshot.docs.isNotEmpty) {
            panchayatData = querySnapshot.docs.first.data();
          }
        } catch (e) {
          print('Error fetching panchayat data: $e');
        }
      }
      _navigateToAddEvent(
        eventToUpdate: eventToUpdate,
        memberData: panchayatData,
      );
    }
  }

  Future<void> _navigateToAddEvent({
    EventModel? eventToUpdate,
    Map<String, dynamic>? memberData,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AddEventWithLocationPage(
              existingEvent: eventToUpdate,
              panchayatData: memberData,
            ),
      ),
    );

    if (result == true) {
      _loadEventsForMonth();
    }
  }

  // ============================================
  // DELETE EVENT - PANCHAYAT ONLY
  // ============================================
  void _deleteEvent(DateTime date, EventModel event) {
    if (!_isPanchayatMember) {
      _showPermissionDenied();
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: _isDark ? Colors.grey[900] : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 28,
                ),
                SizedBox(width: 10),
                Text(
                  'Delete Event?',
                  style: TextStyle(
                    color: _isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to delete "${event.heading}"?',
              style: TextStyle(
                color: _isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await EventFirebaseService.deleteEvent(
                      event.eventDate,
                      event.id,
                    );
                    Navigator.pop(context);
                    _loadEventsForMonth();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 10),
                            Text('Event deleted successfully'),
                          ],
                        ),
                        backgroundColor: Colors.green[700],
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete event'),
                        backgroundColor: Colors.red[700],
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  // ============================================
  // SHOW PERMISSION DENIED MESSAGE
  // ============================================
  void _showPermissionDenied() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.lock_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 10),
                Text('Permission Required'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Only Panchayat members can add, edit, or delete events.'),
                SizedBox(height: 16),
                Text(
                  'Would you like to login as a Panchayat member?',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  // Show login dialog
                  final memberData = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(builder: (_) => PanchayatLoginScreen()),
                  );

                  if (memberData != null) {
                    setState(() => _isPanchayatMember = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Logged in as Panchayat member'),
                        backgroundColor: Colors.green[700],
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
                child: Text('Login', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  // ============================================
  // VIEW EVENT DETAILS - EVERYONE CAN VIEW
  // ============================================
  void _viewEventDetails(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => EventDetailsBottomSheet(
            event: event,
            isPanchayatMember: _isPanchayatMember,
            onEdit: () {
              Navigator.pop(context);
              _openAddEvent(eventToUpdate: event);
            },
            onDelete: () {
              Navigator.pop(context);
              _deleteEvent(event.eventDate, event);
            },
          ),
    );
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedDay = DateTime(
        _focusedDay.year,
        _focusedDay.month - 1,
        _focusedDay.day,
      );
    });
    _loadEventsForMonth();
  }

  void _goToNextMonth() {
    setState(() {
      _focusedDay = DateTime(
        _focusedDay.year,
        _focusedDay.month + 1,
        _focusedDay.day,
      );
    });
    _loadEventsForMonth();
  }

  void _navigateToYearlyCalendar() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => YearlyCalendarPage(initialYear: _focusedDay.year),
      ),
    );
    if (result != null && result is DateTime) {
      setState(() {
        _focusedDay = result;
        _selectedDay = result;
      });
      _loadEventsForMonth();
    }
  }

  void _goToToday() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = DateTime.now();
    });
    _loadEventsForMonth();
  }

  void _toggleTheme() {
    setState(() {
      _isDark = !_isDark;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents =
        _selectedDay == null ? <EventModel>[] : _getEventsForDay(_selectedDay!);

    final backgroundColor = _isDark ? Colors.black : Colors.grey[50];
    final appBarColor = _isDark ? Colors.grey[900] : Colors.blue[700];
    final cardColor = _isDark ? Colors.grey[900] : Colors.white;
    final textColor = _isDark ? Colors.white : Colors.black87;
    final subtextColor = _isDark ? Colors.white70 : Colors.grey[600];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: appBarColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(_focusedDay),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            // Show user role
            if (!_isCheckingPermissions)
              Text(
                _isPanchayatMember ? 'Panchayat Member' : 'Viewer',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isDark ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: _toggleTheme,
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: Icon(Icons.today_rounded, color: Colors.white),
            onPressed: _goToToday,
            tooltip: 'Today',
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadEventsForMonth,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: Colors.white),
            color: _isDark ? Colors.grey[800] : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            onSelected: (value) {
              if (value == 'year') {
                _navigateToYearlyCalendar();
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'year',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_view_month, color: Colors.blue),
                        SizedBox(width: 10),
                        Text(
                          'Year View',
                          style: TextStyle(
                            color: _isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading events...',
                      style: TextStyle(color: textColor),
                    ),
                  ],
                ),
              )
              : ScaleTransition(
                scale: _scaleAnimation,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 10),

                      // Quick Date Navigation
                      _buildQuickNavigation(cardColor!, textColor),

                      SizedBox(height: 10),

                      // Calendar Container
                      _buildCalendarSection(cardColor, textColor),

                      SizedBox(height: 16),

                      // Toggle View Button
                      _buildToggleButton(),

                      SizedBox(height: 10),

                      // Events List
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        child:
                            _isExpanded
                                ? _buildAllEventsList(
                                  cardColor,
                                  textColor,
                                  subtextColor,
                                )
                                : _buildSelectedEventsList(
                                  selectedEvents,
                                  cardColor,
                                  textColor,
                                  subtextColor,
                                ),
                      ),

                      SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

      // FAB - Only show if Panchayat member OR show with lock icon
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_event',
        onPressed: () => _openAddEvent(date: _selectedDay),
        backgroundColor:
            _isPanchayatMember ? Colors.blue[700] : Colors.grey[400],
        icon: Icon(
          _isPanchayatMember ? Icons.add_rounded : Icons.lock_rounded,
          color: Colors.white,
        ),
        label: Text(
          _isPanchayatMember ? 'Add Event' : 'Login to Add',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 6,
      ),
    );
  }

  // ... Keep all the _build methods from previous code ...
  // (Calendar, navigation buttons, etc. - unchanged)

  Widget _buildQuickNavigation(Color cardColor, Color textColor) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                _isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: _isDark ? Colors.blue[300] : Colors.blue[700],
              size: 28,
            ),
            onPressed: _goToPreviousMonth,
          ),
          GestureDetector(
            onTap: _navigateToYearlyCalendar,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _isDark ? Colors.grey[800] : Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    color: _isDark ? Colors.blue[300] : Colors.blue[700],
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    _focusedDay.year.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isDark ? Colors.blue[300] : Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: _isDark ? Colors.blue[300] : Colors.blue[700],
              size: 28,
            ),
            onPressed: _goToNextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection(Color cardColor, Color textColor) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                _isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.blue.withOpacity(0.15),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: TableCalendar<EventModel>(
          firstDay: DateTime(2000),
          lastDay: DateTime(2100),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
              _isExpanded = false;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
            _loadEventsForMonth();
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          eventLoader: _getEventsForDay,
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.orange[400],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.4),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            markerDecoration: BoxDecoration(
              color: Colors.purple[400],
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
            defaultTextStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            weekendTextStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.red[400],
            ),
            todayTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            selectedTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            outsideTextStyle: TextStyle(
              color: _isDark ? Colors.grey[700] : Colors.grey[400],
            ),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonShowsNext: false,
            formatButtonDecoration: BoxDecoration(
              color: _isDark ? Colors.grey[800] : Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            formatButtonTextStyle: TextStyle(
              color: _isDark ? Colors.blue[300] : Colors.blue[700],
              fontWeight: FontWeight.w600,
            ),
            titleTextStyle: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
            leftChevronVisible: false,
            rightChevronVisible: false,
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isDark ? Colors.blue[300] : Colors.blue[700],
            ),
            weekendStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red[400],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[600]!, Colors.blue[400]!],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isExpanded ? Icons.view_day_rounded : Icons.view_agenda_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 10),
            Text(
              _isExpanded ? 'Show Selected Day' : 'Show All Events',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            SizedBox(width: 10),
            Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllEventsList(
    Color cardColor,
    Color textColor,
    Color? subtextColor,
  ) {
    final allDates =
        _eventsByDate.keys.toList()..sort((a, b) => a.compareTo(b));

    if (allDates.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_busy_rounded,
        title: 'No Events Yet',
        subtitle:
            _isPanchayatMember
                ? 'Tap the + button to create your first event'
                : 'No events scheduled this month',
        textColor: textColor,
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: allDates.length,
      itemBuilder: (context, index) {
        final date = allDates[index];
        final events = _eventsByDate[date]!;

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    _isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.08),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              childrenPadding: EdgeInsets.only(bottom: 10),
              leading: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isDark ? Colors.grey[800] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: _isDark ? Colors.blue[300] : Colors.blue[700],
                  size: 20,
                ),
              ),
              title: Text(
                DateFormat('EEEE, MMM dd, yyyy').format(date),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
              subtitle: Text(
                '${events.length} event${events.length > 1 ? "s" : ""}',
                style: TextStyle(color: subtextColor, fontSize: 13),
              ),
              children:
                  events
                      .map(
                        (ev) => _buildEventCard(
                          ev,
                          date,
                          cardColor,
                          textColor,
                          subtextColor,
                        ),
                      )
                      .toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedEventsList(
    List<EventModel> events,
    Color cardColor,
    Color textColor,
    Color? subtextColor,
  ) {
    if (events.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_note_rounded,
        title: 'No Events',
        subtitle:
            'No events scheduled for ${DateFormat('MMM dd').format(_selectedDay!)}',
        textColor: textColor,
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: events.length,
      itemBuilder:
          (context, i) => _buildEventCard(
            events[i],
            _selectedDay!,
            cardColor,
            textColor,
            subtextColor,
          ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
  }) {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: _isDark ? Colors.grey[800] : Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60,
              color: _isDark ? Colors.blue[300] : Colors.blue[300],
            ),
          ),
          SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // EVENT CARD - VIEW ONLY FOR NORMAL USERS
  // ============================================
  Widget _buildEventCard(
    EventModel ev,
    DateTime date,
    Color cardColor,
    Color textColor,
    Color? subtextColor,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDark ? Colors.grey[700]! : Colors.blue[100]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                _isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.blue.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _viewEventDetails(ev),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                // Image or Icon
                ev.imageUrl != null
                    ? GestureDetector(
                      onTap: () => _showImageDialog(ev.imageUrl!),
                      child: Hero(
                        tag: 'event_image_${ev.imageUrl}',
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: ev.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
                                    color: Colors.grey[300],
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    color: Colors.grey[300],
                                    child: Icon(Icons.error, color: Colors.red),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    )
                    : Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: _isDark ? Colors.grey[800] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.event,
                        color: _isDark ? Colors.blue[300] : Colors.blue[400],
                        size: 32,
                      ),
                    ),

                SizedBox(width: 16),

                // Event Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ev.heading,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        ev.description,
                        style: TextStyle(fontSize: 13, color: subtextColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (ev.locationName != null) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.red[400],
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ev.locationName!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Action Buttons - ONLY FOR PANCHAYAT MEMBERS
                if (_isPanchayatMember)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit_rounded,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        onPressed: () => _openAddEvent(eventToUpdate: ev),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_rounded,
                          color: Colors.red[400],
                          size: 20,
                        ),
                        onPressed: () => _deleteEvent(date, ev),
                        tooltip: 'Delete',
                      ),
                    ],
                  )
                else
                  // View details button for normal users
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey[600],
                      size: 16,
                    ),
                    onPressed: () => _viewEventDetails(ev),
                    tooltip: 'View Details',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                Center(
                  child: Hero(
                    tag: 'event_image_$imageUrl',
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

// ============================================
// EVENT DETAILS BOTTOM SHEET
// Shows full event details for viewing
// ============================================
class EventDetailsBottomSheet extends StatelessWidget {
  final EventModel event;
  final bool isPanchayatMember;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EventDetailsBottomSheet({
    super.key,
    required this.event,
    required this.isPanchayatMember,
    required this.onEdit,
    required this.onDelete,
  });


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
              // Handle bar
              Container(
                margin: EdgeInsets.symmetric(vertical: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Header with actions
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Event Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        if (isPanchayatMember) ...[
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: onEdit,
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: onDelete,
                            tooltip: 'Delete',
                          ),
                        ],
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Divider(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Image
                      if (event.imageUrl != null) ...[
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => Dialog(
                                backgroundColor: Colors.transparent,
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Hero(
                                        tag: 'event_detail_image_${event.imageUrl}',
                                        child: Container(
                                          constraints: BoxConstraints(
                                            maxHeight: MediaQuery.of(context).size.height * 0.8,
                                            maxWidth: MediaQuery.of(context).size.width * 0.9,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 20,
                                                offset: Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(20),
                                            child: CachedNetworkImage(
                                              imageUrl: event.imageUrl!,
                                              fit: BoxFit.contain,
                                              placeholder: (context, url) => Container(
                                                color: Colors.black54,
                                                child: Center(
                                                  child: CircularProgressIndicator(
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                color: Colors.black54,
                                                child: Center(
                                                  child: Icon(Icons.error, color: Colors.red, size: 50),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 20,
                                      right: 20,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: Icon(Icons.close, color: Colors.white, size: 28),
                                          onPressed: () => Navigator.of(dialogContext).pop(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Hero(
                            tag: 'event_detail_image_${event.imageUrl}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: event.imageUrl!,
                                width: double.infinity,
                                height: 250,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 250,
                                  color: Colors.grey[300],
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 250,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.error, color: Colors.red),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                      ],

                      // Event Title
                      Text(
                        event.heading,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Event Date
                      _buildInfoRow(
                        icon: Icons.calendar_today,
                        color: Colors.blue,
                        title: 'Date',
                        value: DateFormat(
                          'EEEE, MMMM dd, yyyy',
                        ).format(event.eventDate),
                      ),
                      SizedBox(height: 12),

                      // Location
                      if (event.locationName != null)
                        _buildInfoRow(
                          icon: Icons.location_on,
                          color: Colors.red,
                          title: 'Location',
                          value: event.locationName!,
                        ),
                      SizedBox(height: 12),

                      // Created By
                      _buildInfoRow(
                        icon: Icons.person,
                        color: Colors.purple,
                        title: 'Organized By',
                        value: event.createdBy,
                      ),
                      SizedBox(height: 20),

                      // Description
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event.description,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Likes and Comments
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.favorite,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '${event.likes} likes',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.comment,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '${event.comments.length} comments',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildInfoRow({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
