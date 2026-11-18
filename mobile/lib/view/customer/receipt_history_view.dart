import 'package:material_ui/material_ui.dart';
import 'package:mobile/core/app_colors.dart';
import 'package:provider/provider.dart';

import 'package:mobile/model/receipt_model.dart';
import 'package:mobile/service/receipt_service.dart';
import 'package:mobile/view/customer/receipt_details_view.dart';

class CustomerReceiptHistoryView extends StatefulWidget {
  const CustomerReceiptHistoryView({super.key});

  @override
  State<CustomerReceiptHistoryView> createState() =>
      _CustomerReceiptHistoryViewState();
}

class _CustomerReceiptHistoryViewState
    extends State<CustomerReceiptHistoryView> {
  late Future<List<ReceiptModel>> _receiptsFuture;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  void _loadReceipts() {
    _receiptsFuture = context.read<ReceiptService>().getMyReceipts();
  }

  Future<void> _refreshReceipts() async {
    final future = context.read<ReceiptService>().getMyReceipts();

    setState(() {
      _receiptsFuture = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder จะแสดงข้อผิดพลาด
    }
  }

  void _retryLoading() {
    setState(_loadReceipts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        foregroundColor: AppColors.white,
        title: const Text('ประวัติใบเสร็จ'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<ReceiptModel>>(
          future: _receiptsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.red),
              );
            }

            if (snapshot.hasError) {
              return _buildError();
            }

            final receipts = snapshot.data ?? [];

            if (receipts.isEmpty) {
              return _buildEmpty();
            }

            final totalAmount = receipts.fold<double>(
              0,
              (sum, receipt) => sum + (receipt.totalAmount ?? 0),
            );

            return RefreshIndicator(
              onRefresh: _refreshReceipts,
              color: AppColors.red,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSummary(receipts.length, totalAmount),

                  const SizedBox(height: 22),

                  const Text(
                    'ใบเสร็จทั้งหมด',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  ...receipts.map(
                    (receipt) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ReceiptCard(
                        receipt: receipt,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CustomerReceiptDetailsView(receipt: receipt),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Center(
                    child: Text(
                      'ข้อมูลใบเสร็จจากระบบ PayGame',
                      style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummary(int count, double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.redSoft, AppColors.redNormal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: AppColors.goldLight, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'จำนวนใบเสร็จ',
                  style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count รายการ',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'ยอดรวม',
                style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
              ),
              const SizedBox(height: 5),
              Text(
                '฿${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: AppColors.inkMuted, size: 60),
            const SizedBox(height: 16),
            const Text(
              'ไม่สามารถโหลดประวัติใบเสร็จได้',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _retryLoading,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return RefreshIndicator(
      onRefresh: _refreshReceipts,
      color: AppColors.red,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Icon(
            Icons.receipt_long_outlined,
            color: AppColors.inkMuted,
            size: 72,
          ),
          SizedBox(height: 18),
          Text(
            'ยังไม่มีใบเสร็จ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'ใบเสร็จจะแสดงที่หน้านี้เมื่อระบบออกใบเสร็จให้แล้ว',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final ReceiptModel receipt;
  final VoidCallback onTap;

  const _ReceiptCard({required this.receipt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.white,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.receipt,
                    color: AppColors.goldText,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      receipt.receiptNumber,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.inkMuted),
                ],
              ),

              const Divider(color: AppColors.divider, height: 24),

              _infoRow('Order ID', '#${receipt.orderId}'),

              const SizedBox(height: 9),

              _infoRow('เกม', receipt.gameName ?? '-'),

              const SizedBox(height: 9),

              _infoRow('แพ็กเกจ', receipt.packageName ?? '-'),

              const SizedBox(height: 9),

              _infoRow('วันที่ออกใบเสร็จ', _formatDate(receipt.issuedAt)),

              const Divider(color: AppColors.divider, height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ยอดชำระ',
                    style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
                  ),
                  Text(
                    '฿${(receipt.totalAmount ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.goldText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'แตะเพื่อดูรายละเอียด',
                  style: TextStyle(color: AppColors.inkMuted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 115,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.end,
            style: const TextStyle(color: AppColors.ink, fontSize: 12),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';

    final value = date.toLocal();

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}
