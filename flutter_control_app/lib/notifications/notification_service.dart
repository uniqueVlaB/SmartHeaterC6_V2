/// Notification service placeholder.
///
/// This class is designed to be extended in the future with push notification
/// support (e.g., via firebase_messaging or flutter_local_notifications).
/// Use [NotificationService.instance] to access the singleton.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  bool _initialized = false;

  /// Call once at app start.  
  /// Add initialization logic here when implementing notifications.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    // TODO: initialize firebase_messaging / flutter_local_notifications
  }

  /// Show a local notification with [title] and [body].
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    // TODO: implement local notification
  }

  /// Send a fault alert notification.
  Future<void> notifyFault({required String code, String? details}) async {
    await showNotification(
      title: 'Heater Fault: $code',
      body: details ?? 'Check your device.',
    );
  }

  /// Send a temperature alert when water temp exceeds [threshold].
  Future<void> notifyHighTemp(double tempC) async {
    await showNotification(
      title: 'High Temperature Alert',
      body: 'Water temperature reached ${tempC.toStringAsFixed(1)}°C.',
    );
  }
}
