import 'dart:async';

/// Simple in-memory broadcaster for new orders so UI can react immediately.
class OrderService {
  static final StreamController<Map<String, dynamic>> _orderController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get orderStream => _orderController.stream;

  static void notifyNewOrder(Map<String, dynamic> order) {
    try {
      // Debug log to help trace notifications
      // ignore: avoid_print
      print('OrderService.notifyNewOrder -> ${order.toString()}');
      _orderController.add(order);
    } catch (e) {
      // ignore: avoid_print
      print('OrderService.notifyNewOrder error: $e');
    }
  }

  /// Close the controller if needed (not called by default).
  static Future<void> dispose() async {
    await _orderController.close();
  }
}
