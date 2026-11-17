import 'package:material_ui/material_ui.dart';
import 'package:mobile/model/order_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/order_service.dart';

class OrderController extends ChangeNotifier {
  final OrderService _orderService;

  OrderController(this._orderService);

  List<OrderModel> _orders = [];

  bool _isLoading = false;
  int? _busyOrderId;
  String? _errorMessage;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  int? get busyOrderId => _busyOrderId;
  String? get errorMessage => _errorMessage;

  Future<void> loadOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _orders = await _orderService.getAllOrders();
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsCompleted(int orderId) async {
    await _performAction(orderId, () {
      return _orderService.updateOrderStatus(
        orderId: orderId,
        status: 'Completed',
      );
    });
  }

  Future<void> cancelOrder(int orderId) async {
    await _performAction(orderId, () {
      return _orderService.cancelOrder(orderId);
    });
  }

  Future<void> _performAction(
    int orderId,
    Future<void> Function() action,
  ) async {
    if (_busyOrderId != null) return;

    _busyOrderId = orderId;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      _orders = await _orderService.getAllOrders();
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
    } finally {
      _busyOrderId = null;
      notifyListeners();
    }
  }

  String _getErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    if (error is FormatException) {
      return error.message;
    }

    return 'เกิดข้อผิดพลาด กรุณาลองอีกครั้ง';
  }
}
