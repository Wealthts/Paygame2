import 'package:material_ui/material_ui.dart';
import 'package:mobile/core/app_colors.dart';
import 'package:provider/provider.dart';

import 'package:mobile/model/user_model.dart';
import 'package:mobile/service/customer/customer_profile_service.dart';

class CustomerProfileView extends StatefulWidget {
  const CustomerProfileView({super.key});

  @override
  State<CustomerProfileView> createState() => _CustomerProfileViewState();
}

class _CustomerProfileViewState extends State<CustomerProfileView> {
  late Future<UserModel> _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ========================================
  // Load Profile
  // ========================================
  void _loadProfile() {
    _profileFuture = context.read<CustomerProfileService>().getMyProfile();
  }

  // ========================================
  // Refresh Profile
  // ========================================
  Future<void> _refreshProfile() async {
    final future = context.read<CustomerProfileService>().getMyProfile();

    setState(() {
      _profileFuture = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder จะแสดง Error ให้เอง
    }
  }

  // ========================================
  // Retry
  // ========================================
  void _retryLoading() {
    setState(_loadProfile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        foregroundColor: AppColors.white,
        title: const Text('ข้อมูลส่วนตัว'),
      ),
      body: SafeArea(
        child: FutureBuilder<UserModel>(
          future: _profileFuture,
          builder: (context, snapshot) {
            // Loading
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.red),
                    SizedBox(height: 16),
                    Text(
                      'กำลังโหลดข้อมูลโปรไฟล์...',
                      style: TextStyle(color: AppColors.inkMuted),
                    ),
                  ],
                ),
              );
            }

            // Error
            if (snapshot.hasError || !snapshot.hasData) {
              return _buildError();
            }

            final user = snapshot.data!;

            return RefreshIndicator(
              onRefresh: _refreshProfile,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _buildProfileHeader(user),

                  const SizedBox(height: 24),

                  const Text(
                    'รายละเอียดบัญชี',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  _buildInformationCard(user),

                  const SizedBox(height: 20),

                  _buildAccountNotice(),

                  const SizedBox(height: 24),

                  const Center(
                    child: Text(
                      'PAYGAME ACCOUNT',
                      style: TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
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

  // ========================================
  // Profile Header
  // ========================================
  Widget _buildProfileHeader(UserModel user) {
    final name = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : user.username;

    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.redDark, AppColors.redDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: AppColors.red,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '@${user.username}',
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 14),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.isAdmin ? 'ADMIN' : 'CUSTOMER',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // Information Card
  // ========================================
  Widget _buildInformationCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _profileRow(
            icon: Icons.badge_outlined,
            label: 'User ID',
            value: user.userId.toString(),
          ),

          const Divider(color: AppColors.divider, height: 26),

          _profileRow(
            icon: Icons.person_outline,
            label: 'Username',
            value: user.username,
          ),

          const Divider(color: AppColors.divider, height: 26),

          _profileRow(
            icon: Icons.account_circle_outlined,
            label: 'Display Name',
            value: user.displayName ?? '-',
          ),

          const Divider(color: AppColors.divider, height: 26),

          _profileRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email ?? '-',
          ),

          const Divider(color: AppColors.divider, height: 26),

          _profileRow(
            icon: Icons.admin_panel_settings_outlined,
            label: 'Account Role',
            value: user.role,
          ),
        ],
      ),
    );
  }

  // ========================================
  // Profile Row
  // ========================================
  Widget _profileRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.goldText, size: 21),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
              ),

              const SizedBox(height: 5),

              Text(
                value.isEmpty ? '-' : value,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========================================
  // Account Notice
  // ========================================
  Widget _buildAccountNotice() {
    return Container(
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
              'ข้อมูลนี้ดึงมาจากบัญชีที่คุณเข้าสู่ระบบ '
              'หากต้องการแก้ไขข้อมูลส่วนตัว '
              'ระบบยังไม่ได้เปิด API สำหรับให้ลูกค้าแก้ไขโปรไฟล์',
              style: TextStyle(
                color: AppColors.inkMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // Error
  // ========================================
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 60, color: AppColors.inkMuted),

            const SizedBox(height: 16),

            const Text(
              'ไม่สามารถโหลดข้อมูลโปรไฟล์ได้',
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
}
