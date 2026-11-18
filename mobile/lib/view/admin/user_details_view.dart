import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/controller/admin/user_details_controller.dart';
import 'package:mobile/model/admin/user_details_model.dart';
import 'package:mobile/service/admin/user_management_service.dart';

class UserDetailsView extends StatefulWidget {
  final int userId;

  const UserDetailsView({super.key, required this.userId});

  @override
  State<UserDetailsView> createState() => _UserDetailsViewState();
}

class _UserDetailsViewState extends State<UserDetailsView> {
  late final UserDetailsController controller;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    controller = UserDetailsController(context.read<UserManagementService>());

    controller.loadDetails(widget.userId);
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) controller.loadDetails(widget.userId);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  String _text(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return '-';
    }

    return value.toString();
  }

  double _number(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(dynamic value) {
    return '฿${_number(value).toStringAsFixed(2)}';
  }

  String _date(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return '-';
    }

    return value.toString().replaceFirst('T', ' ').split('.').first;
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return SizedBox(
      width: 155,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(icon, size: 26),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required int count,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required Widget Function(Map<String, dynamic>) itemBuilder,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Chip(label: Text(count.toString())),
        children: [
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('ไม่มีประวัติรายการ'),
            ),

          ...items.map(itemBuilder),
        ],
      ),
    );
  }

  Widget _orderItem(Map<String, dynamic> item) {
    return ListTile(
      title: Text(
        'Order #${_text(item['order_id'])}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_text(item['game_name_snapshot'])} - '
            '${_text(item['package_name_snapshot'])}',
          ),
          Text('UID: ${_text(item['player_uid'])}'),
          Text('Server: ${_text(item['server_code'])}'),
          Text('วันที่: ${_date(item['created_at'])}'),
          Text('สถานะ: ${_text(item['status'])}'),
          if (item['coupon_code_snapshot'] != null)
            Text('Coupon: ${_text(item['coupon_code_snapshot'])}'),
          Text('ส่วนลด: ${_money(item['discount_amount'])}'),
        ],
      ),
      isThreeLine: true,
      trailing: Text(
        _money(item['total_amount']),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _paymentItem(Map<String, dynamic> item) {
    return ListTile(
      title: Text(
        'Payment #${_text(item['payment_id'])}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order: #${_text(item['order_id'])}'),
          Text(
            '${_text(item['game_name_snapshot'])} - '
            '${_text(item['package_name_snapshot'])}',
          ),
          Text('รายการ: ${_text(item['transaction_ref'])}'),
          Text('ช่องทาง: ${_text(item['method'])}'),
          Text('วันที่: ${_date(item['created_at'])}'),
          Text('สถานะ: ${_text(item['status'])}'),
          if (item['paid_at'] != null)
            Text('ชำระเมื่อ: ${_date(item['paid_at'])}'),
        ],
      ),
      isThreeLine: true,
      trailing: Text(
        _money(item['amount']),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _pointItem(Map<String, dynamic> item) {
    final delta = int.tryParse(item['points_delta']?.toString() ?? '') ?? 0;

    return ListTile(
      title: Text(
        _text(item['event_key']),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'ประเภท: ${_text(item['type'])}\n'
        'Order: ${_text(item['order_id'])}\n'
        'วันที่: ${_date(item['created_at'])}',
      ),
      isThreeLine: true,
      trailing: Text(
        '${delta > 0 ? '+' : ''}$delta แต้ม',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: delta >= 0 ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  Widget _receiptItem(Map<String, dynamic> item) {
    return ListTile(
      leading: const Icon(Icons.receipt_long),
      title: Text(
        _text(item['receipt_number']),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Order: #${_text(item['order_id'])}\n'
        '${_text(item['game_name_snapshot'])} - '
        '${_text(item['package_name_snapshot'])}\n'
        'ออกเมื่อ: ${_date(item['issued_at'])}',
      ),
      isThreeLine: true,
    );
  }

  Widget _couponItem(Map<String, dynamic> item) {
    final used = item['used_at'] != null;
    final type = item['discount_type']?.toString();

    final discount = type == 'percent'
        ? '${_number(item['discount_value']).toStringAsFixed(0)}%'
        : _money(item['discount_value']);

    return ListTile(
      leading: const Icon(Icons.confirmation_number),
      title: Text(
        _text(item['code']),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'ส่วนลด: $discount\n'
        'หมดอายุ: ${_date(item['end_date'])}\n'
        'มอบคูปอง ID: ${_text(item['user_coupon_id'])}',
      ),
      isThreeLine: true,
      trailing: Chip(
        label: Text(used ? 'ใช้แล้ว' : 'ยังไม่ได้ใช้'),
        backgroundColor: used ? Colors.grey.shade300 : Colors.green.shade100,
      ),
    );
  }

  Widget _buildProfile(UserDetailsModel data) {
    final user = data.user;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 35,
              child: Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 26),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user.displayName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text('@${user.username}'),
            Text(user.email),
            const SizedBox(height: 10),
            Chip(
              label: Text(user.isActive ? 'บัญชีเปิดใช้งาน' : 'บัญชีปิดใช้งาน'),
              backgroundColor: user.isActive
                  ? Colors.green.shade100
                  : Colors.red.shade100,
            ),
            Text('User ID: ${user.userId}'),
            Text('สมัครเมื่อ: ${_date(user.createdAt)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails(UserDetailsModel data) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildProfile(data),
        const SizedBox(height: 12),

        const Text(
          'ภาพรวมการใช้งาน',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _summaryCard(
              'คำสั่งซื้อ',
              data.orderCount.toString(),
              Icons.shopping_cart,
            ),
            _summaryCard(
              'ยอดชำระแล้ว',
              _money(data.paidAmount),
              Icons.payments,
            ),
            _summaryCard(
              'แต้มคงเหลือ',
              data.pointBalance.toString(),
              Icons.stars,
            ),
            _summaryCard(
              'การชำระเงิน',
              data.paymentCount.toString(),
              Icons.account_balance_wallet,
            ),
            _summaryCard(
              'ใบเสร็จ',
              data.receiptCount.toString(),
              Icons.receipt_long,
            ),
            _summaryCard(
              'คูปองที่ได้รับ',
              data.couponCount.toString(),
              Icons.confirmation_number,
            ),
          ],
        ),

        const SizedBox(height: 16),

        const Text(
          'ประวัติการใช้งาน',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        _section(
          title: 'คำสั่งซื้อ',
          count: data.orders.length,
          icon: Icons.shopping_bag,
          items: data.orders,
          itemBuilder: _orderItem,
        ),

        _section(
          title: 'การชำระเงิน',
          count: data.payments.length,
          icon: Icons.payments,
          items: data.payments,
          itemBuilder: _paymentItem,
        ),

        _section(
          title: 'ประวัติแต้ม',
          count: data.pointTransactions.length,
          icon: Icons.stars,
          items: data.pointTransactions,
          itemBuilder: _pointItem,
        ),

        _section(
          title: 'ใบเสร็จ',
          count: data.receipts.length,
          icon: Icons.receipt_long,
          items: data.receipts,
          itemBuilder: _receiptItem,
        ),

        _section(
          title: 'คูปองของสมาชิก',
          count: data.userCoupons.length,
          icon: Icons.confirmation_number,
          items: data.userCoupons,
          itemBuilder: _couponItem,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดสมาชิก'),
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            onPressed: () => controller.loadDetails(widget.userId),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(controller.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => controller.loadDetails(widget.userId),
                      child: const Text('ลองอีกครั้ง'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = controller.details;

          if (data == null) {
            return const Center(child: Text('ไม่พบข้อมูลสมาชิก'));
          }

          return _buildDetails(data);
        },
      ),
    );
  }
}
