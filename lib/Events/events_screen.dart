// import 'package:chatur_frontend/Events/screens/event_store.dart';
// import 'package:flutter/material.dart';
// import 'package:table_calendar/table_calendar.dart';
// import 'package:intl/intl.dart';
// import 'package:chatur_frontend/Events/add_event.dart';
// import 'package:chatur_frontend/Events/screens/all_events.dart';
// import 'package:chatur_frontend/Events/screens/yearly_calendar_page.dart';

// class AllEventsPage extends StatefulWidget {
//   @override
//   _AllEventsPageState createState() => _AllEventsPageState();
// }

// class _AllEventsPageState extends State<AllEventsPage>
//     with SingleTickerProviderStateMixin {
//   DateTime _focusedDay = DateTime.now();
//   DateTime? _selectedDay;
//   bool _isExpanded = false;
//   bool _isDark = false; // Default: White mode
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;
//   CalendarFormat _calendarFormat = CalendarFormat.month;

//   @override
//   void initState() {
//     super.initState();
//     _selectedDay = _focusedDay;

//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );

//     _scaleAnimation = CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     );

//     _animationController.forward();
//   }

//   Future<void> _openAddEvent({Event? eventToUpdate, DateTime? date}) async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => AddEventPage(event: eventToUpdate, initialDate: date),
//       ),
//     );
//     if (result == true) {
//       setState(() {});
//     }
//   }

//   void _deleteEvent(DateTime date, Event event) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: _isDark ? Colors.grey[900] : Colors.white,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Row(
//           children: [
//             Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
//             SizedBox(width: 10),
//             Text(
//               'Delete Event?',
//               style: TextStyle(color: _isDark ? Colors.white : Colors.black87),
//             ),
//           ],
//         ),
//         content: Text(
//           'Are you sure you want to delete "${event.heading}"?',
//           style: TextStyle(color: _isDark ? Colors.white70 : Colors.black87),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               EventStore.instance.deleteEvent(date, event);
//               setState(() {});
//               Navigator.pop(context);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Row(
//                     children: [
//                       Icon(Icons.check_circle, color: Colors.white),
//                       SizedBox(width: 10),
//                       Text('Event deleted'),
//                     ],
//                   ),
//                   backgroundColor: Colors.green[700],
//                   behavior: SnackBarBehavior.floating,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//               );
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             child: Text('Delete'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _goToPreviousMonth() {
//     setState(() {
//       _focusedDay =
//           DateTime(_focusedDay.year, _focusedDay.month - 1, _focusedDay.day);
//     });
//   }

//   void _goToNextMonth() {
//     setState(() {
//       _focusedDay =
//           DateTime(_focusedDay.year, _focusedDay.month + 1, _focusedDay.day);
//     });
//   }

//   void _navigateToYearlyCalendar() async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => YearlyCalendarPage(initialYear: _focusedDay.year),
//       ),
//     );
//     if (result != null && result is DateTime) {
//       setState(() {
//         _focusedDay = result;
//         _selectedDay = result;
//       });
//     }
//   }

//   void _goToToday() {
//     setState(() {
//       _focusedDay = DateTime.now();
//       _selectedDay = DateTime.now();
//     });
//   }

//   void _toggleTheme() {
//     setState(() {
//       _isDark = !_isDark;
//     });
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final selectedEvents = _selectedDay == null
//         ? <Event>[]
//         : EventStore.instance.getEventsByDate(_selectedDay!);

//     final backgroundColor = _isDark ? Colors.black : Colors.grey[50];
//     final appBarColor = _isDark ? Colors.grey[900] : Colors.blue[700];
//     final cardColor = _isDark ? Colors.grey[900] : Colors.white;
//     final textColor = _isDark ? Colors.white : Colors.black87;
//     final subtextColor = _isDark ? Colors.white70 : Colors.grey[600];

//     return Scaffold(
//       backgroundColor: backgroundColor,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: appBarColor,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           DateFormat('MMMM yyyy').format(_focusedDay),
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//             color: Colors.white,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(
//               _isDark ? Icons.light_mode : Icons.dark_mode,
//               color: Colors.white,
//             ),
//             onPressed: _toggleTheme,
//             tooltip: 'Toggle Theme',
//           ),
//           IconButton(
//             icon: Icon(Icons.today_rounded, color: Colors.white),
//             onPressed: _goToToday,
//             tooltip: 'Today',
//           ),
//           PopupMenuButton<String>(
//             icon: Icon(Icons.more_vert_rounded, color: Colors.white),
//             color: _isDark ? Colors.grey[800] : Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(15),
//             ),
//             onSelected: (value) {
//               if (value == 'year') {
//                 _navigateToYearlyCalendar();
//               }
//             },
//             itemBuilder: (context) => [
//               PopupMenuItem(
//                 value: 'year',
//                 child: Row(
//                   children: [
//                     Icon(Icons.calendar_view_month, color: Colors.blue),
//                     SizedBox(width: 10),
//                     Text(
//                       'Year View',
//                       style: TextStyle(
//                           color: _isDark ? Colors.white : Colors.black87),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//       body: ScaleTransition(
//         scale: _scaleAnimation,
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               SizedBox(height: 10),

//               // Quick Date Navigation
//               _buildQuickNavigation(cardColor!, textColor),

//               SizedBox(height: 10),

//               // Calendar Container
//               _buildCalendarSection(cardColor, textColor),

//               SizedBox(height: 16),

//               // Toggle View Button
//               _buildToggleButton(),

//               SizedBox(height: 10),

//               // Events List
//               AnimatedSwitcher(
//                 duration: Duration(milliseconds: 300),
//                 child: _isExpanded
//                     ? _buildAllEventsList(cardColor, textColor, subtextColor)
//                     : _buildSelectedEventsList(
//                         selectedEvents, cardColor, textColor, subtextColor),
//               ),

//               SizedBox(height: 80), // Space for FAB
//             ],
//           ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         heroTag: 'add_event',
//         onPressed: () => _openAddEvent(date: _selectedDay),
//         backgroundColor: const Color.fromARGB(255, 80, 210, 250),
//         icon: Icon(Icons.add_rounded),
//         label: Text('Add Event', style: TextStyle(fontWeight: FontWeight.bold)),
//         elevation: 6,
//       ),
//     );
//   }

//   Widget _buildQuickNavigation(Color cardColor, Color textColor) {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 16),
//       padding: EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: cardColor,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: _isDark
//                 ? Colors.black.withOpacity(0.3)
//                 : Colors.blue.withOpacity(0.1),
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           IconButton(
//             icon: Icon(Icons.chevron_left,
//                 color: _isDark ? Colors.blue[300] : Colors.blue[700], size: 28),
//             onPressed: _goToPreviousMonth,
//           ),
//           GestureDetector(
//             onTap: _navigateToYearlyCalendar,
//             child: Container(
//               padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//               decoration: BoxDecoration(
//                 color: _isDark ? Colors.grey[800] : Colors.blue[50],
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.calendar_month,
//                       color: _isDark ? Colors.blue[300] : Colors.blue[700],
//                       size: 20),
//                   SizedBox(width: 8),
//                   Text(
//                     _focusedDay.year.toString(),
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: _isDark ? Colors.blue[300] : Colors.blue[700],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           IconButton(
//             icon: Icon(Icons.chevron_right,
//                 color: _isDark ? Colors.blue[300] : Colors.blue[700], size: 28),
//             onPressed: _goToNextMonth,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCalendarSection(Color cardColor, Color textColor) {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 16),
//       decoration: BoxDecoration(
//         color: cardColor,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: _isDark
//                 ? Colors.black.withOpacity(0.3)
//                 : Colors.blue.withOpacity(0.15),
//             blurRadius: 20,
//             offset: Offset(0, 10),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(20),
//         child: TableCalendar<Event>(
//           firstDay: DateTime(2000),
//           lastDay: DateTime(2100),
//           focusedDay: _focusedDay,
//           calendarFormat: _calendarFormat,
//           selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
//           onDaySelected: (selectedDay, focusedDay) {
//             setState(() {
//               _selectedDay = selectedDay;
//               _focusedDay = focusedDay;
//               _isExpanded = false;
//             });
//           },
//           onPageChanged: (focusedDay) {
//             setState(() {
//               _focusedDay = focusedDay;
//             });
//           },
//           onFormatChanged: (format) {
//             setState(() {
//               _calendarFormat = format;
//             });
//           },
//           eventLoader: (day) => EventStore.instance.getEventsByDate(day),
//           calendarStyle: CalendarStyle(
//             todayDecoration: BoxDecoration(
//               color: Colors.orange[400],
//               shape: BoxShape.circle,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.orange.withOpacity(0.4),
//                   blurRadius: 8,
//                   offset: Offset(0, 4),
//                 ),
//               ],
//             ),
//             selectedDecoration: BoxDecoration(
//               color: Colors.blue[700],
//               shape: BoxShape.circle,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.blue.withOpacity(0.4),
//                   blurRadius: 8,
//                   offset: Offset(0, 4),
//                 ),
//               ],
//             ),
//             markerDecoration: BoxDecoration(
//               color: Colors.purple[400],
//               shape: BoxShape.circle,
//             ),
//             markersMaxCount: 3,
//             defaultTextStyle: TextStyle(
//               fontWeight: FontWeight.w600,
//               color: textColor,
//             ),
//             weekendTextStyle: TextStyle(
//               fontWeight: FontWeight.w600,
//               color: Colors.red[400],
//             ),
//             todayTextStyle: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//             selectedTextStyle: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//             outsideTextStyle: TextStyle(
//               color: _isDark ? Colors.grey[700] : Colors.grey[400],
//             ),
//           ),
//           headerStyle: HeaderStyle(
//             formatButtonVisible: true,
//             titleCentered: true,
//             formatButtonShowsNext: false,
//             formatButtonDecoration: BoxDecoration(
//               color: _isDark ? Colors.grey[800] : Colors.blue[50],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             formatButtonTextStyle: TextStyle(
//               color: _isDark ? Colors.blue[300] : Colors.blue[700],
//               fontWeight: FontWeight.w600,
//             ),
//             titleTextStyle: TextStyle(
//               color: textColor,
//               fontWeight: FontWeight.bold,
//             ),
//             leftChevronVisible: false,
//             rightChevronVisible: false,
//           ),
//           daysOfWeekStyle: DaysOfWeekStyle(
//             weekdayStyle: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: _isDark ? Colors.blue[300] : Colors.blue[700],
//             ),
//             weekendStyle: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.red[400],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildToggleButton() {
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _isExpanded = !_isExpanded;
//         });
//       },
//       child: Container(
//         margin: EdgeInsets.symmetric(horizontal: 16),
//         padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.blue[600]!, Colors.blue[400]!],
//           ),
//           borderRadius: BorderRadius.circular(30),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.blue.withOpacity(0.3),
//               blurRadius: 12,
//               offset: Offset(0, 6),
//             ),
//           ],
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               _isExpanded ? Icons.view_day_rounded : Icons.view_agenda_rounded,
//               color: Colors.white,
//               size: 20,
//             ),
//             SizedBox(width: 10),
//             Text(
//               _isExpanded ? 'Show Selected Day' : 'Show All Events',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 15,
//               ),
//             ),
//             SizedBox(width: 10),
//             Icon(
//               _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
//               color: Colors.white,
//               size: 20,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAllEventsList(
//       Color cardColor, Color textColor, Color? subtextColor) {
//     final allDates = EventStore.instance.allEvents().keys.toList()
//       ..sort((a, b) => a.compareTo(b));

//     if (allDates.isEmpty) {
//       return _buildEmptyState(
//         icon: Icons.event_busy_rounded,
//         title: 'No Events Yet',
//         subtitle: 'Tap the + button to create your first event',
//         textColor: textColor,
//       );
//     }

//     return ListView.builder(
//       shrinkWrap: true,
//       physics: NeverScrollableScrollPhysics(),
//       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//       itemCount: allDates.length,
//       itemBuilder: (context, index) {
//         final date = allDates[index];
//         final events = EventStore.instance.getEventsByDate(date);

//         return Container(
//           margin: EdgeInsets.only(bottom: 12),
//           decoration: BoxDecoration(
//             color: cardColor,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 color: _isDark
//                     ? Colors.black.withOpacity(0.3)
//                     : Colors.blue.withOpacity(0.08),
//                 blurRadius: 10,
//                 offset: Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Theme(
//             data: Theme.of(context).copyWith(
//               dividerColor: Colors.transparent,
//             ),
//             child: ExpansionTile(
//               tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               childrenPadding: EdgeInsets.only(bottom: 10),
//               leading: Container(
//                 padding: EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: _isDark ? Colors.grey[800] : Colors.blue[50],
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(Icons.calendar_today,
//                     color: _isDark ? Colors.blue[300] : Colors.blue[700],
//                     size: 20),
//               ),
//               title: Text(
//                 DateFormat('EEEE, MMM dd, yyyy').format(date),
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                   color: textColor,
//                 ),
//               ),
//               subtitle: Text(
//                 '${events.length} event${events.length > 1 ? "s" : ""}',
//                 style: TextStyle(color: subtextColor, fontSize: 13),
//               ),
//               children: events
//                   .map((ev) => _buildEventCard(
//                       ev, date, cardColor, textColor, subtextColor))
//                   .toList(),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildSelectedEventsList(List<Event> events, Color cardColor,
//       Color textColor, Color? subtextColor) {
//     if (events.isEmpty) {
//       return _buildEmptyState(
//         icon: Icons.event_note_rounded,
//         title: 'No Events',
//         subtitle:
//             'No events scheduled for ${DateFormat('MMM dd').format(_selectedDay!)}',
//         textColor: textColor,
//       );
//     }

//     return ListView.builder(
//       shrinkWrap: true,
//       physics: NeverScrollableScrollPhysics(),
//       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//       itemCount: events.length,
//       itemBuilder: (context, i) => _buildEventCard(
//           events[i], _selectedDay!, cardColor, textColor, subtextColor),
//     );
//   }

//   Widget _buildEmptyState({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required Color textColor,
//   }) {
//     return Container(
//       padding: EdgeInsets.all(40),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: EdgeInsets.all(30),
//             decoration: BoxDecoration(
//               color: _isDark ? Colors.grey[800] : Colors.blue[50],
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon,
//                 size: 60, color: _isDark ? Colors.blue[300] : Colors.blue[300]),
//           ),
//           SizedBox(height: 20),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: textColor,
//             ),
//           ),
//           SizedBox(height: 8),
//           Text(
//             subtitle,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 14,
//               color: _isDark ? Colors.white70 : Colors.grey[600],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEventCard(Event ev, DateTime date, Color cardColor,
//       Color textColor, Color? subtextColor) {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: cardColor,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//             color: _isDark ? Colors.grey[700]! : Colors.blue[100]!, width: 1),
//         boxShadow: [
//           BoxShadow(
//             color: _isDark
//                 ? Colors.black.withOpacity(0.3)
//                 : Colors.blue.withOpacity(0.05),
//             blurRadius: 8,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(16),
//           onTap: () => _openAddEvent(eventToUpdate: ev, date: date),
//           child: Padding(
//             padding: EdgeInsets.all(12),
//             child: Row(
//               children: [
//                 // Image or Icon
//                 ev.imageUrl != null
//                     ? GestureDetector(
//                         onTap: () => _showImageDialog(ev.imageUrl!),
//                         child: Hero(
//                           tag: 'event_image_${ev.imageUrl}',
//                           child: Container(
//                             width: 70,
//                             height: 70,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(12),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.1),
//                                   blurRadius: 8,
//                                   offset: Offset(0, 4),
//                                 ),
//                               ],
//                             ),
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(12),
//                               child: Image.network(
//                                 ev.imageUrl!,
//                                 fit: BoxFit.cover,
//                               ),
//                             ),
//                           ),
//                         ),
//                       )
//                     : Container(
//                         width: 70,
//                         height: 70,
//                         decoration: BoxDecoration(
//                           color: _isDark ? Colors.grey[800] : Colors.blue[50],
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Icon(Icons.event,
//                             color:
//                                 _isDark ? Colors.blue[300] : Colors.blue[400],
//                             size: 32),
//                       ),

//                 SizedBox(width: 16),

//                 // Event Details
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         ev.heading,
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: textColor,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       SizedBox(height: 4),
//                       Text(
//                         ev.description,
//                         style: TextStyle(
//                           fontSize: 13,
//                           color: subtextColor,
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Action Buttons
//                 Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     IconButton(
//                       icon: Icon(Icons.edit_rounded,
//                           color: Colors.blue[600], size: 20),
//                       onPressed: () =>
//                           _openAddEvent(eventToUpdate: ev, date: date),
//                       tooltip: 'Edit',
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.delete_rounded,
//                           color: Colors.red[400], size: 20),
//                       onPressed: () => _deleteEvent(date, ev),
//                       tooltip: 'Delete',
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _showImageDialog(String imageUrl) {
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         backgroundColor: Colors.transparent,
//         child: Stack(
//           children: [
//             Center(
//               child: Hero(
//                 tag: 'event_image_$imageUrl',
//                 child: Container(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.3),
//                         blurRadius: 20,
//                         offset: Offset(0, 10),
//                       ),
//                     ],
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(20),
//                     child: Image.network(
//                       imageUrl,
//                       fit: BoxFit.contain,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             Positioned(
//               top: 20,
//               right: 20,
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.5),
//                   shape: BoxShape.circle,
//                 ),
//                 child: IconButton(
//                   icon: Icon(Icons.close, color: Colors.white, size: 28),
//                   onPressed: () => Navigator.of(context).pop(),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
