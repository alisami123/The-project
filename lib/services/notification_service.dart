import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/medication.dart';

/// Service responsible for managing local push notifications.
/// 
/// This service handles:
/// - Initializing the notification plugin
/// - Scheduling medication reminders at specific times
/// - Canceling notifications when medications are deleted or modified
/// - Displaying notifications with medication details and images
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Channel ID for medication reminders
  static const String _channelId = 'medication_reminders';
  
  /// Channel name displayed to users in system settings
  static const String _channelName = 'Medication Reminders';
  
  /// Channel description
  static const String _channelDescription =
      'Notifications for scheduled medication reminders';

  /// Initializes the notification service.
  /// 
  /// Must be called before scheduling any notifications.
  /// Requests notification permissions on both iOS and Android.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: true, // For critical health reminders
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions
      await _requestPermissions();

      _isInitialized = true;
    } catch (e) {
      print('Error initializing notification service: $e');
      rethrow;
    }
  }

  /// Requests notification permissions from the user.
  Future<void> _requestPermissions() async {
    try {
      // Android 13+ requires explicit permission request
      final androidInfo = await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidInfo != null) {
        await androidInfo.requestNotificationsPermission();
      }

      // iOS permissions
      final iosInfo = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosInfo != null) {
        await iosInfo.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true,
        );
      }
    } catch (e) {
      print('Error requesting permissions: $e');
    }
  }

  /// Handles notification tap events.
  void _onNotificationTapped(NotificationResponse response) {
    // Can be extended to navigate to specific medication screen
    print('Notification tapped: ${response.payload}');
  }

  /// Schedules a notification for a medication at a specific time.
  /// 
  /// [medication] The medication to remind about
  /// [scheduleElement] The specific schedule element (time) for this reminder
  /// [notificationId] Unique ID for this notification
  /// 
  /// Uses timezone-aware scheduling to ensure reminders fire at the correct
  /// local time regardless of device timezone changes.
  Future<void> scheduleMedicationReminder({
    required Medication medication,
    required ScheduleElement scheduleElement,
    required int notificationId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Calculate the next occurrence of this time
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        scheduleElement.hour,
        scheduleElement.minute,
      );

      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Create Android-specific notification details
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        autoCancel: false,
        ongoing: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: medication.imageUrl != null &&
                File(medication.imageUrl!).existsSync()
            ? FilePathAndroidBitmap(medication.imageUrl!)
            : null,
        styleInformation: BigTextStyleInformation(
          '${medication.title}\nTake ${medication.pillCount} pill(s)',
          contentTitle: medication.title,
          summaryText: 'Medication Reminder',
        ),
      );

      // Create iOS-specific notification details
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule the notification
      await _notifications.zonedSchedule(
        notificationId,
        'Time to take ${medication.title}',
        'Take ${medication.pillCount} pill(s) of ${medication.title}',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      print('Scheduled notification $notificationId for ${scheduledDate.toLocal()}');
    } catch (e) {
      print('Error scheduling notification: $e');
      rethrow;
    }
  }

  /// Schedules all reminders for a medication based on its frequency.
  /// 
  /// Creates separate notifications for each scheduled time element.
  Future<void> scheduleAllMedicationReminders(Medication medication) async {
    if (!medication.isActive) return;

    for (int i = 0; i < medication.scheduleElements.length; i++) {
      final element = medication.scheduleElements[i];
      final notificationId = _generateNotificationId(medication.id, i);
      
      await scheduleMedicationReminder(
        medication: medication,
        scheduleElement: element,
        notificationId: notificationId,
      );
    }
  }

  /// Cancels a specific notification.
  Future<void> cancelNotification(int notificationId) async {
    try {
      await _notifications.cancel(notificationId);
      print('Cancelled notification $notificationId');
    } catch (e) {
      print('Error cancelling notification: $e');
    }
  }

  /// Cancels all notifications for a specific medication.
  Future<void> cancelMedicationNotifications(String medicationId) async {
    try {
      // Cancel up to 10 possible notifications per medication
      // (covers frequency 1-3 with some buffer)
      for (int i = 0; i < 10; i++) {
        final notificationId = _generateNotificationId(medicationId, i);
        await cancelNotification(notificationId);
      }
    } catch (e) {
      print('Error cancelling medication notifications: $e');
    }
  }

  /// Cancels all pending notifications.
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('Cancelled all notifications');
    } catch (e) {
      print('Error cancelling all notifications: $e');
    }
  }

  /// Generates a unique notification ID based on medication ID and index.
  /// 
  /// Uses hash code to ensure uniqueness while keeping IDs manageable.
  int _generateNotificationId(String medicationId, int index) {
    return medicationId.hashCode.abs() + index;
  }

  /// Shows an immediate notification (for testing or urgent reminders).
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
    String? imageUrl,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: imageUrl != null && File(imageUrl).existsSync()
            ? FilePathAndroidBitmap(imageUrl)
            : null,
      );

      final iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      print('Error showing immediate notification: $e');
      rethrow;
    }
  }
}
