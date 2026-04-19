import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Notification IDs
  static const int _budgetWarningId    = 1001;
  static const int _budgetExceededId   = 1002;
  static const int _dailyReminderIds   = 2001;
  static const int _goalReachedBase    = 3000;
  static const int _weeklyReportId     = 4001;
  static const int _transactionId      = 5001;

  // ── Initialize ────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle tap — payload can be used to navigate
    debugPrint('Notification tapped: ${response.payload}');
  }

  // ── Request Permissions ───────────────────────────────────────
  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    bool granted = false;

    if (android != null) {
      granted = await android.requestNotificationsPermission() ?? false;
    }
    if (ios != null) {
      granted = await ios.requestPermissions(
            alert: true, badge: true, sound: true) ??
          false;
    }

    return granted;
  }

  // ── Notification Details ──────────────────────────────────────
  NotificationDetails _details({
    String channelId = 'budget_alerts',
    String channelName = 'Budget Alerts',
    String channelDesc = 'Notifications for budget and spending alerts',
    Importance importance = Importance.high,
    Priority priority = Priority.high,
    Color? color,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: importance,
        priority: priority,
        color: color ?? const Color(0xFF1BA589),
        icon: '@mipmap/ic_launcher',
        styleInformation: const BigTextStyleInformation(''),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // ── 1. Budget Warning (80% used) ──────────────────────────────
  Future<void> showBudgetWarning({
    required double spent,
    required double budget,
  }) async {
    await initialize();
    final pct = ((spent / budget) * 100).toStringAsFixed(0);
    await _plugin.show(
      _budgetWarningId,
      '⚠️ Budget Alert',
      'You\'ve used $pct% of your monthly budget. \$${(budget - spent).toStringAsFixed(2)} remaining.',
      _details(
        channelId: 'budget_alerts',
        channelName: 'Budget Alerts',
        color: const Color(0xFFF59E0B),
      ),
      payload: 'budget_warning',
    );
  }

  // ── 2. Budget Exceeded ────────────────────────────────────────
  Future<void> showBudgetExceeded({
    required double spent,
    required double budget,
  }) async {
    await initialize();
    final over = (spent - budget).toStringAsFixed(2);
    await _plugin.show(
      _budgetExceededId,
      '🚨 Budget Exceeded!',
      'You\'ve gone \$$over over your monthly budget of \$${budget.toStringAsFixed(2)}.',
      _details(
        channelId: 'budget_alerts',
        channelName: 'Budget Alerts',
        color: const Color(0xFFE05252),
      ),
      payload: 'budget_exceeded',
    );
  }

  // ── 3. Transaction Saved Confirmation ─────────────────────────
  Future<void> showTransactionSaved({
    required String type,     // 'Income' or 'Expense'
    required double amount,
    required String category,
  }) async {
    await initialize();
    final emoji = type == 'Income' ? '💰' : '💸';
    await _plugin.show(
      _transactionId,
      '$emoji $type Added',
      '\$${amount.toStringAsFixed(2)} in $category recorded successfully.',
      _details(
        channelId: 'transactions',
        channelName: 'Transaction Updates',
        channelDesc: 'Confirmations when transactions are saved',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      payload: 'transaction_saved',
    );
  }

  // ── 4. Savings Goal Reached ───────────────────────────────────
  Future<void> showGoalReached({
    required String goalTitle,
    required double targetAmount,
    required int goalIndex,
  }) async {
    await initialize();
    await _plugin.show(
      _goalReachedBase + goalIndex,
      '🎉 Goal Reached!',
      'Congratulations! You\'ve reached your "$goalTitle" goal of \$${targetAmount.toStringAsFixed(2)}!',
      _details(
        channelId: 'goals',
        channelName: 'Savings Goals',
        channelDesc: 'Notifications about your savings goals',
        color: const Color(0xFF1BA589),
      ),
      payload: 'goal_reached_$goalIndex',
    );
  }

  // ── 5. Savings Goal Progress ──────────────────────────────────
  Future<void> showGoalProgress({
    required String goalTitle,
    required double progress,    // 0.0 to 1.0
    required double saved,
    required double target,
  }) async {
    await initialize();
    final pct = (progress * 100).toStringAsFixed(0);
    await _plugin.show(
      _goalReachedBase,
      '🎯 Goal Progress Update',
      '"$goalTitle" is now $pct% complete! \$${saved.toStringAsFixed(2)} of \$${target.toStringAsFixed(2)} saved.',
      _details(
        channelId: 'goals',
        channelName: 'Savings Goals',
        channelDesc: 'Notifications about your savings goals',
      ),
      payload: 'goal_progress',
    );
  }

  // ── 6. Daily Spending Reminder (Scheduled) ────────────────────
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await initialize();
    await _plugin.zonedSchedule(
      _dailyReminderIds,
      '📊 Daily Check-in',
      'Don\'t forget to log today\'s expenses. Stay on top of your budget!',
      _nextInstanceOf(hour, minute),
      _details(
        channelId: 'reminders',
        channelName: 'Daily Reminders',
        channelDesc: 'Daily spending log reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );
  }

  // ── 7. Weekly Summary Reminder ────────────────────────────────
  Future<void> scheduleWeeklySummary() async {
    await initialize();
    await _plugin.zonedSchedule(
      _weeklyReportId,
      '📈 Weekly Summary Ready',
      'Your weekly spending report is ready. Check how you did this week!',
      _nextInstanceOf(9, 0, weekday: DateTime.sunday),
      _details(
        channelId: 'reminders',
        channelName: 'Daily Reminders',
        channelDesc: 'Daily spending log reminders',
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekly_summary',
    );
  }

  // ── 8. Cancel Notifications ───────────────────────────────────
  Future<void> cancelDailyReminder() async =>
      _plugin.cancel(_dailyReminderIds);

  Future<void> cancelWeeklySummary() async =>
      _plugin.cancel(_weeklyReportId);

  Future<void> cancelAll() async => _plugin.cancelAll();

  // ── Helper: next scheduled time ───────────────────────────────
  tz.TZDateTime _nextInstanceOf(int hour, int minute, {int? weekday}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);

    if (weekday != null) {
      while (scheduled.weekday != weekday) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    }

    if (scheduled.isBefore(now)) {
      scheduled = weekday != null
          ? scheduled.add(const Duration(days: 7))
          : scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}
