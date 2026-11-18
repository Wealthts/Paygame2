import 'package:material_ui/material_ui.dart';
import 'package:mobile/core/app_colors.dart';
import 'package:provider/provider.dart';

import 'package:mobile/controller/auth_controller.dart';
import 'package:mobile/view/admin/game_view.dart';
import 'package:mobile/view/admin/package_view.dart';
import 'package:mobile/view/admin/order_view.dart';
import 'package:mobile/view/admin/payment_view.dart';
import 'package:mobile/view/admin/point_view.dart';
import 'package:mobile/view/admin/receipt_view.dart';
import 'package:mobile/view/admin/coupon_view.dart';
import 'package:mobile/view/admin/user_coupon_view.dart';
import 'package:mobile/view/admin/user_management_view.dart';
import 'package:mobile/view/admin/report_view.dart';
import 'package:mobile/view/admin/admin_overview_view.dart';

class AdminHomePageView extends StatelessWidget {
  const AdminHomePageView({super.key});

  void _openPage(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        foregroundColor: AppColors.white,
        title: const Text(
          'PAYGAME ADMIN',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: auth.isLoading
                ? null
                : () => context.read<AuthController>().logout(),
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ยินดีต้อนรับ ${user?.displayName ?? user?.username ?? "Admin"}',
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 16,
                    ),
                  ),

                  // Overview is a full-width section, not a grid tile.
                  const SizedBox(height: 24),
                  const AdminOverviewSection(),

                  const SizedBox(height: 12),
                  const Text(
                    'จัดการระบบ',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width >= 900
                          ? 3
                          : width >= 600
                          ? 2
                          : 1;

                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.2,
                        children: [
                          _AdminMenuCard(
                            icon: Icons.sports_esports,
                            title: 'Games',
                            description: 'จัดการเกม',
                            onTap: () => _openPage(context, const GameView()),
                          ),
                          _AdminMenuCard(
                            icon: Icons.inventory_2_outlined,
                            title: 'Packages',
                            description: 'จัดการแพ็กเกจ',
                            onTap: () =>
                                _openPage(context, const PackageView()),
                          ),
                          _AdminMenuCard(
                            icon: Icons.receipt_long_outlined,
                            title: 'Orders',
                            description: 'จัดการคำสั่งซื้อ',
                            onTap: () => _openPage(context, const OrderView()),
                          ),
                          _AdminMenuCard(
                            icon: Icons.payments_outlined,
                            title: 'Payments',
                            description: 'ตรวจสอบการชำระเงิน',
                            onTap: () =>
                                _openPage(context, const PaymentView()),
                          ),
                          _AdminMenuCard(
                            icon: Icons.stars_outlined,
                            title: 'Points',
                            description: 'จัดการแต้มสะสม',
                            onTap: () => _openPage(context, const PointView()),
                          ),
                          _AdminMenuCard(
                            icon: Icons.receipt_long_outlined,
                            title: 'Receipts',
                            description: 'จัดการใบเสร็จรับเงิน',
                            onTap: () =>
                                _openPage(context, const ReceiptView()),
                          ),
                          _AdminMenuCard(
                            icon: Icons.confirmation_number_outlined,
                            title: 'Coupons',
                            description: 'จัดการคูปองส่วนลด',
                            onTap: () => _openPage(context, const CouponView()),
                          ),
                          _AdminMenuCard(
                            icon: Icons.card_giftcard,
                            title: 'User Coupons',
                            description: 'มอบคูปองและตรวจสอบคูปองของสมาชิก',
                            onTap: () =>
                                _openPage(context, const UserCouponView()),
                          ),
                          _AdminMenuCard(
                            icon: Icons.people_alt,
                            title: 'User Management',
                            description: 'ดูและจัดการบัญชีสมาชิก',
                            onTap: () =>
                                _openPage(context, const UserManagementView()),
                          ),
                          _AdminMenuCard(
                            icon: Icons.analytics_outlined,
                            title: 'Reports & Analytics',
                            description: 'รายงานยอดขายและสถิติของระบบ',
                            onTap: () => _openPage(context, const ReportView()),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'PayGame Administration',
                      style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
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
}

class _AdminMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _AdminMenuCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.white,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.red, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: AppColors.inkMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
