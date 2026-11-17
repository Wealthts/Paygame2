import 'package:material_ui/material_ui.dart';
import 'package:mobile/core/app_colors.dart';
import 'package:provider/provider.dart';

import '../../service/api_service.dart';
import '../../service/payment_service.dart';

class CustomerPaymentView extends StatefulWidget {
  final int orderId;
  final double amount;
  final String gameName;
  final String packageName;

  const CustomerPaymentView({
    super.key,
    required this.orderId,
    required this.amount,
    required this.gameName,
    required this.packageName,
  });

  @override
  State<CustomerPaymentView> createState() => _CustomerPaymentViewState();
}

class _CustomerPaymentViewState extends State<CustomerPaymentView> {
  final _formKey = GlobalKey<FormState>();

  final _transactionRefController = TextEditingController();
  final _methodController = TextEditingController();

  bool _isSubmitting = false;

  String? _errorMessage;

  int? _paymentId;
  String _paymentStatus = 'Pending';

  @override
  void dispose() {
    _transactionRefController.dispose();
    _methodController.dispose();
    super.dispose();
  }

  // ========================================
  // Submit Payment
  // ========================================
  Future<void> _submitPayment() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final response = await context.read<PaymentService>().createPayment(
        orderId: widget.orderId,
        transactionRef: _transactionRefController.text.trim(),
        method: _methodController.text.trim(),
      );

      final paymentId = int.tryParse(response['payment_id']?.toString() ?? '');

      if (paymentId == null || paymentId <= 0) {
        throw const FormatException('ไม่พบหมายเลขรายการชำระเงินจากเซิร์ฟเวอร์');
      }

      if (!mounted) return;

      setState(() {
        _paymentId = paymentId;
        _paymentStatus = response['status']?.toString() ?? 'Pending';
        _isSubmitting = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _errorMessage = _getErrorMessage(error);
      });
    }
  }

  // ========================================
  // Error Message
  // ========================================
  String _getErrorMessage(Object error) {
    if (error is ApiException) {
      switch (error.statusCode) {
        case 400:
          return 'กรุณาตรวจสอบเลขอ้างอิงและช่องทางชำระเงิน';

        case 401:
          return 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่';

        case 404:
          return 'ไม่พบคำสั่งซื้อของคุณ';

        case 409:
          return 'คำสั่งซื้อนี้มีรายการชำระเงินแล้ว '
              'หรือไม่อยู่ในสถานะที่สามารถชำระเงินได้';

        default:
          return error.message;
      }
    }

    if (error is FormatException) {
      return error.message;
    }

    return 'ไม่สามารถบันทึกข้อมูลการชำระเงินได้ '
        'กรุณาลองใหม่อีกครั้ง';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        foregroundColor: AppColors.white,
        title: Text(
          _paymentId == null ? 'แจ้งการชำระเงิน' : 'บันทึกการชำระเงินสำเร็จ',
        ),
      ),
      body: SafeArea(
        child: _paymentId == null ? _buildPaymentForm() : _buildSuccessView(),
      ),
    );
  }

  // ========================================
  // Payment Form
  // ========================================
  Widget _buildPaymentForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildOrderSummary(),

          const SizedBox(height: 26),

          const Text(
            'ข้อมูลการชำระเงิน',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'กรอกข้อมูลจากการชำระเงินจริงของคุณ',
            style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
          ),

          const SizedBox(height: 20),

          // Payment Method
          const Text(
            'ช่องทางการชำระเงิน',
            style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _methodController,
            maxLength: 100,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: AppColors.ink),
            decoration: _inputDecoration(
              hint: 'เช่น Bank Transfer หรือ PromptPay',
              icon: Icons.account_balance_outlined,
            ),
            validator: (value) {
              final method = value?.trim() ?? '';

              if (method.isEmpty) {
                return 'กรุณาระบุช่องทางการชำระเงิน';
              }

              if (method.length > 100) {
                return 'ช่องทางชำระเงินต้องไม่เกิน 100 ตัวอักษร';
              }

              return null;
            },
          ),

          const SizedBox(height: 18),

          // Transaction Reference
          const Text(
            'เลขอ้างอิงการชำระเงิน (Transaction Ref)',
            style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _transactionRefController,
            maxLength: 100,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            style: const TextStyle(color: AppColors.ink),
            decoration: _inputDecoration(
              hint: 'กรอกเลขอ้างอิงจากรายการโอนเงินจริง',
              icon: Icons.receipt_long_outlined,
            ),
            validator: (value) {
              final ref = value?.trim() ?? '';

              if (ref.isEmpty) {
                return 'กรุณากรอกเลขอ้างอิงการชำระเงิน';
              }

              if (ref.length > 100) {
                return 'เลขอ้างอิงต้องไม่เกิน 100 ตัวอักษร';
              }

              return null;
            },
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.peach,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.goldText),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'โปรดชำระเงินจริงผ่านช่องทางและบัญชีของร้านค้า '
                    'ที่ได้รับแจ้งจากผู้ให้บริการก่อน '
                    'จากนั้นจึงกรอกเลขอ้างอิงของรายการชำระเงิน '
                    'หน้านี้ยังไม่รองรับการอัปโหลดสลิป',
                    style: TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitPayment,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                _isSubmitting
                    ? 'กำลังบันทึกข้อมูล...'
                    : 'ยืนยันข้อมูลการชำระเงิน',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'ระบบจะบันทึกรายการเป็น Pending '
            'จนกว่าแอดมินจะตรวจสอบและยืนยันการรับเงิน',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ========================================
  // Order Summary
  // ========================================
  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สรุปคำสั่งซื้อ',
            style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
          ),

          const SizedBox(height: 12),

          _summaryRow('Order ID', '#${widget.orderId}'),

          const SizedBox(height: 10),

          _summaryRow('เกม', widget.gameName),

          const SizedBox(height: 10),

          _summaryRow('แพ็กเกจ', widget.packageName),

          const Divider(color: AppColors.divider, height: 28),

          _summaryRow(
            'ยอดที่ต้องชำระ',
            '฿${widget.amount.toStringAsFixed(2)}',
            valueColor: AppColors.goldText,
          ),
        ],
      ),
    );
  }

  // ========================================
  // Success View
  // ========================================
  Widget _buildSuccessView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 82),

            const SizedBox(height: 20),

            const Text(
              'บันทึกข้อมูลสำเร็จ',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'ระบบได้รับข้อมูลการแจ้งชำระเงินแล้ว',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkMuted, fontSize: 14),
            ),

            const SizedBox(height: 26),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _summaryRow('Payment ID', '#$_paymentId'),

                  const SizedBox(height: 12),

                  _summaryRow('Order ID', '#${widget.orderId}'),

                  const SizedBox(height: 12),

                  _summaryRow('ช่องทาง', _methodController.text.trim()),

                  const SizedBox(height: 12),

                  _summaryRow(
                    'ยอดชำระ',
                    '฿${widget.amount.toStringAsFixed(2)}',
                    valueColor: AppColors.goldText,
                  ),

                  const Divider(color: AppColors.divider, height: 28),

                  _summaryRow(
                    'สถานะ',
                    _paymentStatus,
                    valueColor: AppColors.gold,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'รายการยังรอการตรวจสอบจากแอดมิน '
              'การบันทึกข้อมูลนี้ไม่ได้ยืนยันว่าร้านค้าได้รับเงินจริงแล้ว',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.inkMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('กลับไปหน้าแรก'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // Summary Row
  // ========================================
  Widget _summaryRow(
    String label,
    String value, {
    Color valueColor = Colors.white,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ========================================
  // Input Decoration
  // ========================================
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.inkMuted),
      prefixIcon: Icon(icon, color: AppColors.inkMuted),
      filled: true,
      fillColor: AppColors.white,
      counterStyle: const TextStyle(color: AppColors.inkMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.red),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
