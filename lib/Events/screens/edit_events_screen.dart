import 'package:chatur_frontend/Events/models/event_model.dart';
import 'package:chatur_frontend/Events/screens/add_event_with_location.dart';
import 'package:chatur_frontend/Events/screens/panchayat_login_screen.dart';
import 'package:chatur_frontend/Events/services/event_firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditEventsScreen extends StatefulWidget {
  const EditEventsScreen({super.key});

  @override
  _EditEventsScreenState createState() => _EditEventsScreenState();
}

class _EditEventsScreenState extends State<EditEventsScreen> {
  bool _isPanchayatMember = false;
  Map<String, dynamic>? _panchayatData;
  List<EventModel> _allEvents = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _checkPanchayatLogin();
  }

  Future<void> _checkPanchayatLogin() async {
    // Check if user is already logged in as panchayat member
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.email != null) {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('panchayat_members')
            .where('email', isEqualTo: currentUser!.email!)
            .limit(1)
            .get();
        
        if (querySnapshot.docs.isNotEmpty) {
          setState(() {
            _isPanchayatMember = true;
            _panchayatData = querySnapshot.docs.first.data();
          });
          _loadAllEvents();
          return;
        }
      } catch (e) {
        print('Error checking panchayat login: $e');
      }
    }

    // If not logged in, show login screen
    _showLoginDialog();
  }

  Future<void> _showLoginDialog() async {
    final memberData = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => PanchayatLoginScreen()),
    );

    if (memberData != null) {
      setState(() {
        _isPanchayatMember = true;
        _panchayatData = memberData;
      });
      _loadAllEvents();
    } else {
      // User cancelled login, go back
      Navigator.pop(context);
    }
  }

  Future<void> _loadAllEvents() async {
    setState(() => _isLoading = true);
    try {
      // Fetch all events from Firebase
      final events = await EventFirebaseService.getRecentEvents(
        daysBefore: 365, // Load events from past year
        daysAfter: 365, // Load events for next year
        forceRefresh: true,
      );
      
      setState(() {
        _allEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading events: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load events: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  List<EventModel> get _filteredEvents {
    if (_searchQuery.isEmpty) {
      return _allEvents;
    }
    final query = _searchQuery.toLowerCase();
    return _allEvents.where((event) {
      return event.heading.toLowerCase().contains(query) ||
          event.description.toLowerCase().contains(query) ||
          (event.locationName != null && event.locationName!.toLowerCase().contains(query));
    }).toList();
  }

  Future<void> _editEvent(EventModel event) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEventWithLocationPage(
          existingEvent: event,
          panchayatData: _panchayatData,
        ),
      ),
    );
    
    if (result == true) {
      _hasChanges = true;
      _loadAllEvents();
    }
  }

  Future<void> _deleteEvent(EventModel event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Delete Event'),
          ],
        ),
        content: Text('Are you sure you want to delete "${event.heading}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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

    if (confirm == true) {
      try {
        await EventFirebaseService.deleteEvent(event.eventDate, event.id);

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

        _hasChanges = true;
        _loadAllEvents();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete event: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPanchayatMember) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          Navigator.pop(context, true);
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Color(0xFFF8F9FE),
        appBar: AppBar(
          title: Text(
            'Edit Events',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF6C5CE7)),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded),
              onPressed: _loadAllEvents,
              tooltip: 'Refresh',
            ),
          ],
        ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF6C5CE7)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF6C5CE7), width: 2),
                ),
                filled: true,
                fillColor: Color(0xFFF8F9FE),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Events List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy_rounded,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No events found'
                                  : 'No events match your search',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAllEvents,
                        color: Color(0xFF6C5CE7),
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _filteredEvents.length,
                          itemBuilder: (context, index) {
                            final event = _filteredEvents[index];
                            return _buildEventCard(event);
                          },
                        ),
                      ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image
          if (event.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              child: CachedNetworkImage(
                imageUrl: event.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Icon(Icons.image_not_supported, size: 50),
                ),
              ),
            ),

          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Title
                Text(
                  event.heading,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),

                // Event Description
                Text(
                  event.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),

                // Event Date & Location
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF6C5CE7)),
                    SizedBox(width: 6),
                    Text(
                      dateFormat.format(event.eventDate),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF6C5CE7)),
                    SizedBox(width: 6),
                    Text(
                      timeFormat.format(event.eventDate),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (event.locationName != null) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF6C5CE7)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.locationName!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _editEvent(event),
                        icon: Icon(Icons.edit_rounded, size: 18),
                        label: Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF6C5CE7),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _deleteEvent(event),
                        icon: Icon(Icons.delete_rounded, size: 18),
                        label: Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

