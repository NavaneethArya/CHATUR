import 'package:flutter/material.dart';
import 'package:chatur_frontend/Events/models/notification_model.dart';
import 'package:chatur_frontend/Events/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all as read when screen opens (optional)
    Future.delayed(Duration(seconds: 2), () {
      NotificationService.markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        title: Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: Colors.white),
            onPressed: () {
              NotificationService.markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('All notifications marked as read'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Mark all as read',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'clear_old') {
                _clearOldNotifications();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear_old',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Clear old notifications'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: NotificationService.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return _buildNotificationCard(notifications[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    Color typeColor;
    IconData typeIcon;

    switch (notification.type) {
      case NotificationType.eventCreated:
        typeColor = Colors.green;
        typeIcon = Icons.add_circle;
        break;
      case NotificationType.eventUpdated:
        typeColor = Colors.blue;
        typeIcon = Icons.edit;
        break;
      case NotificationType.eventDeleted:
        typeColor = Colors.red;
        typeIcon = Icons.delete;
        break;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        NotificationService.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification deleted'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.blue[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey[300]!
                : Colors.blue[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (!notification.isRead) {
                NotificationService.markAsRead(notification.id);
              }
              // TODO: Navigate to event details if needed
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon or Image
                  notification.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: notification.imageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(typeIcon, color: typeColor, size: 30),
                            ),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(typeIcon, color: typeColor, size: 30),
                        ),
                  SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              notification.iconEmoji,
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 14, color: Colors.grey[500]),
                            SizedBox(width: 4),
                            Text(
                              _formatTimestamp(notification.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            SizedBox(width: 16),
                            Icon(Icons.calendar_today,
                                size: 14, color: Colors.grey[500]),
                            SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd').format(notification.eventDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
              Icons.notifications_off_outlined,
              size: 80,
              color: Colors.deepPurple[300],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
          SizedBox(height: 16),
          Text(
            'Error loading notifications',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(timestamp);
    }
  }

  void _clearOldNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.delete_sweep, color: Colors.orange),
            SizedBox(width: 10),
            Text('Clear Old Notifications?'),
          ],
        ),
        content: Text(
            'This will delete notifications older than 30 days. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await NotificationService.deleteOldNotifications();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Old notifications cleared')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}