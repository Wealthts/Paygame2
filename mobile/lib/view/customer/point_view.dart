import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/core/app_colors.dart';
import 'package:mobile/core/formatter.dart';
import 'package:mobile/model/point_model.dart';
import 'package:mobile/service/point_service.dart';
import 'package:mobile/view/customer/coupon_view.dart';

class CustomerPointView extends StatefulWidget {
  const CustomerPointView({super.key});

  @override
  State<CustomerPointView> createState() => _CustomerPointViewState();
}

class _CustomerPointViewState extends State<CustomerPointView> {
  late Future<_PointPageData> _pointsFuture;

  @override
  void initState() {
    super.initState();
    _pointsFuture = _fetchPoints();
  }

  Future<_PointPageData> _fetchPoints() async {
    final service = context.read<PointService>();
    final results = await Future.wait([
      service.getMyPoints(),
      service.getMyPointHistory(),
    ]);
    return _PointPageData(
      totalPoints: results[0] as int,
      history: results[1] as List<PointModel>,
    );
  }

  Future<void> _refresh() async {
    final future = _fetchPoints();
    setState(() => _pointsFuture = future);
    try {
      await future;
    } catch (_) {
      // The FutureBuilder displays the current error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('แต้มสะสมของฉัน')),
      body: FutureBuilder<_PointPageData>(
        future: _pointsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const _LoadingPoints();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _ErrorPoints(onRetry: _refresh);
          }

          final data = snapshot.data!;
          final earned = data.history
              .where((item) => item.pointsDelta > 0)
              .fold<int>(0, (sum, item) => sum + item.pointsDelta);
          final spent = data.history
              .where((item) => item.pointsDelta < 0)
              .fold<int>(0, (sum, item) => sum + item.pointsDelta.abs());

          return RefreshIndicator(
            color: AppColors.red,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
              children: [
                _PointsBalanceCard(points: data.totalPoints),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'ได้รับทั้งหมด',
                        value: '+${AppFormatter.formatPoints(earned)}',
                        icon: Icons.trending_up_rounded,
                        color: AppColors.success,
                        background: AppColors.successBg,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'ใช้ไปทั้งหมด',
                        value: '-${AppFormatter.formatPoints(spent)}',
                        icon: Icons.trending_down_rounded,
                        color: AppColors.danger,
                        background: AppColors.dangerBg,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_offer_outlined,
                          color: AppColors.goldText,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'คูปองของฉัน',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'ตรวจสอบคูปองที่ได้รับและเงื่อนไขการใช้งาน',
                                style: TextStyle(
                                  color: AppColors.inkMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'เปิดคูปอง',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const CustomerCouponView(),
                            ),
                          ),
                          icon: const Icon(
                            Icons.chevron_right,
                            color: AppColors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'ประวัติแต้มสะสม',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                        ),
                      ),
                    ),
                    Text(
                      '${data.history.length} รายการ',
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (data.history.isEmpty)
                  const _EmptyPointHistory()
                else
                  ...data.history.map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PointHistoryTile(point: point),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PointsBalanceCard extends StatelessWidget {
  final int points;

  const _PointsBalanceCard({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.red, AppColors.redDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.stars_rounded, color: AppColors.goldLight, size: 26),
              SizedBox(width: 9),
              Text(
                'แต้มสะสมคงเหลือ',
                style: TextStyle(color: AppColors.white, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            AppFormatter.formatPoints(points),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 40,
              height: 1.05,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'POINTS',
            style: TextStyle(
              color: AppColors.goldLight,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: background,
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointHistoryTile extends StatelessWidget {
  final PointModel point;

  const _PointHistoryTile({required this.point});

  @override
  Widget build(BuildContext context) {
    final isEarned = point.pointsDelta > 0;
    final color = isEarned ? AppColors.success : AppColors.danger;
    final label = isEarned
        ? 'ได้รับแต้ม'
        : point.pointsDelta < 0
        ? 'ใช้แต้ม'
        : (point.type.isEmpty ? 'รายการแต้ม' : point.type);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: isEarned
                  ? AppColors.successBg
                  : AppColors.dangerBg,
              child: Icon(
                isEarned ? Icons.add_rounded : Icons.remove_rounded,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    point.orderId == null
                        ? 'รายการแต้มทั่วไป'
                        : 'Order #${point.orderId}',
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    AppFormatter.formatDateTime(point.createdAt),
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              point.pointsDelta > 0
                  ? '+${AppFormatter.formatPoints(point.pointsDelta)}'
                  : AppFormatter.formatPoints(point.pointsDelta),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPointHistory extends StatelessWidget {
  const _EmptyPointHistory();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(
              Icons.stars_outlined,
              color: AppColors.goldText,
              size: 52,
            ),
            const SizedBox(height: 12),
            const Text(
              'ยังไม่มีประวัติแต้มสะสม',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'เมื่อคุณได้รับหรือใช้แต้ม รายการจะแสดงที่หน้านี้',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingPoints extends StatelessWidget {
  const _LoadingPoints();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text('กำลังโหลดข้อมูลแต้มสะสม...'),
        ],
      ),
    );
  }
}

class _ErrorPoints extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorPoints({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 52,
              color: AppColors.danger,
            ),
            const SizedBox(height: 12),
            const Text(
              'ไม่สามารถโหลดข้อมูลแต้มสะสมได้',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointPageData {
  final int totalPoints;
  final List<PointModel> history;

  const _PointPageData({required this.totalPoints, required this.history});
}
