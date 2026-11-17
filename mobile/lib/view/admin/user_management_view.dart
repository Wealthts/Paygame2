import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/controller/admin/user_management_controller.dart';
import 'package:mobile/model/admin/user_admin_model.dart';
import 'package:mobile/service/admin/user_management_service.dart';
import 'package:mobile/view/admin/user_details_view.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  late final UserManagementController controller;

  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'all';
  String _selectedRole = 'all';

  @override
  void initState() {
    super.initState();

    controller = UserManagementController(
      context.read<UserManagementService>(),
    );

    controller.loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    controller.dispose();
    super.dispose();
  }

  // กรองรายชื่อสมาชิกตามคำค้นหา สถานะ และ Role
  List<AdminUserModel> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();

    return controller.users.where((user) {
      final role = user.role.toLowerCase();
      final roleLabel = _roleLabel(user.role).toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          user.userId.toString().contains(query) ||
          user.username.toLowerCase().contains(query) ||
          user.displayName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          role.contains(query) ||
          roleLabel.contains(query) ||
          _formatDate(user.createdAt).toLowerCase().contains(query);

      final matchesStatus = switch (_selectedStatus) {
        'active' => user.isActive,
        'inactive' => !user.isActive,
        _ => true,
      };

      final matchesRole = switch (_selectedRole) {
        'user' => role == 'user',
        'admin' => role == 'admin',
        _ => true,
      };

      return matchesSearch && matchesStatus && matchesRole;
    }).toList();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _confirmStatusChange(AdminUserModel user, bool newStatus) async {
    // Backend อนุญาตให้เปลี่ยนสถานะเฉพาะบัญชีสมาชิก
    if (user.role.toLowerCase() != 'user') {
      _showMessage('ไม่สามารถเปลี่ยนสถานะบัญชีผู้ดูแลระบบได้', isError: true);
      return;
    }

    final action = newStatus ? 'เปิดใช้งาน' : 'ปิดใช้งาน';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('$actionบัญชีสมาชิก'),
          content: Text(
            'คุณต้องการ$actionบัญชีของ '
            '${user.displayName} (@${user.username}) หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: newStatus ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(action),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await controller.updateUserStatus(
        userId: user.userId,
        isActive: newStatus,
      );

      _showMessage(
        newStatus
            ? 'เปิดใช้งานบัญชีเรียบร้อยแล้ว'
            : 'ปิดใช้งานบัญชีเรียบร้อยแล้ว',
      );
    } catch (e) {
      _showMessage('เปลี่ยนสถานะบัญชีไม่สำเร็จ: $e', isError: true);
    }
  }

  String _formatDate(String value) {
    if (value.isEmpty) return '-';

    return value.replaceFirst('T', ' ').split('.').first;
  }

  String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'ผู้ดูแลระบบ';
      case 'user':
        return 'สมาชิก';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการผู้ใช้งาน'),
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            onPressed: controller.isLoading
                ? null
                : () => controller.loadUsers(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final filteredUsers = _filteredUsers;

          return RefreshIndicator(
            onRefresh: () => controller.loadUsers(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // Summary
                _buildSummary(),

                const SizedBox(height: 20),

                // Search และ Filter จะแสดงตลอด
                _buildSearchAndFilters(),

                const SizedBox(height: 16),

                // Heading และจำนวนผลลัพธ์
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'รายชื่อสมาชิก',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${filteredUsers.length} / ${controller.users.length} บัญชี',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Loading
                if (controller.isLoading && controller.users.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),

                // Error กรณีไม่มีข้อมูล
                if (!controller.isLoading &&
                    controller.errorMessage != null &&
                    controller.users.isEmpty)
                  _buildErrorView(),

                // มีข้อมูลอยู่ระหว่างรีเฟรช
                if (controller.isLoading && controller.users.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(),
                  ),

                // ไม่มีสมาชิกในระบบ
                if (!controller.isLoading &&
                    controller.errorMessage == null &&
                    controller.users.isEmpty)
                  _buildEmptyView(
                    icon: Icons.people_outline,
                    message: 'ยังไม่มีสมาชิกในระบบ',
                  ),

                // มีสมาชิก แต่ไม่ตรงกับคำค้นหาหรือตัวกรอง
                if (controller.users.isNotEmpty && filteredUsers.isEmpty)
                  _buildEmptyView(
                    icon: Icons.search_off,
                    message: 'ไม่พบสมาชิกที่ตรงกับเงื่อนไข',
                  ),

                // รายชื่อสมาชิกที่ผ่านการกรอง
                ...filteredUsers.map(_buildUserCard),

                // Error กรณีโหลดข้อมูลใหม่ไม่สำเร็จ แต่ยังมีข้อมูลเก่า
                if (controller.errorMessage != null &&
                    controller.users.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'เกิดข้อผิดพลาด: ${controller.errorMessage}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --------------------------------------------------
  // Search & Filters
  // --------------------------------------------------

  Widget _buildSearchAndFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ค้นหาสมาชิก',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _searchController,
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'ค้นหา ID, Username, ชื่อ หรือ Email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'ล้างคำค้นหา',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Filter สถานะ
            const Text(
              'สถานะบัญชี',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip(
                  label: 'ทั้งหมด',
                  value: 'all',
                  selectedValue: _selectedStatus,
                  onSelected: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                ),
                _buildFilterChip(
                  label: 'กำลังใช้งาน',
                  value: 'active',
                  selectedValue: _selectedStatus,
                  onSelected: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                ),
                _buildFilterChip(
                  label: 'ปิดใช้งาน',
                  value: 'inactive',
                  selectedValue: _selectedStatus,
                  onSelected: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Filter Role
            const Text(
              'ประเภทผู้ใช้งาน',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip(
                  label: 'ทุกประเภท',
                  value: 'all',
                  selectedValue: _selectedRole,
                  onSelected: (value) {
                    setState(() {
                      _selectedRole = value;
                    });
                  },
                ),
                _buildFilterChip(
                  label: 'สมาชิก',
                  value: 'user',
                  selectedValue: _selectedRole,
                  onSelected: (value) {
                    setState(() {
                      _selectedRole = value;
                    });
                  },
                ),
                _buildFilterChip(
                  label: 'ผู้ดูแลระบบ',
                  value: 'admin',
                  selectedValue: _selectedRole,
                  onSelected: (value) {
                    setState(() {
                      _selectedRole = value;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _searchController.clear();

                  setState(() {
                    _selectedStatus = 'all';
                    _selectedRole = 'all';
                  });
                },
                icon: const Icon(Icons.restart_alt),
                label: const Text('ล้างตัวกรองทั้งหมด'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedValue == value,
      onSelected: (_) => onSelected(value),
    );
  }

  // --------------------------------------------------
  // Summary
  // --------------------------------------------------

  Widget _buildSummary() {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'สมาชิกทั้งหมด',
            value: controller.totalUsers.toString(),
            icon: Icons.people,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            title: 'ใช้งานอยู่',
            value: controller.activeUsers.toString(),
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            title: 'ปิดใช้งาน',
            value: controller.inactiveUsers.toString(),
            icon: Icons.block,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // User Card
  // --------------------------------------------------

  Widget _buildUserCard(AdminUserModel user) {
    final updating = controller.isUpdating(user.userId);
    final isMember = user.role.toLowerCase() == 'user';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: user.isActive
                      ? Colors.green.shade100
                      : Colors.grey.shade300,
                  child: Icon(
                    Icons.person,
                    color: user.isActive
                        ? Colors.green.shade800
                        : Colors.grey.shade700,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '@${user.username}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                Switch(
                  value: user.isActive,
                  onChanged: !isMember || updating
                      ? null
                      : (value) => _confirmStatusChange(user, value),
                ),
              ],
            ),

            const Divider(height: 24),

            // Email
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text(user.email)),
              ],
            ),

            const SizedBox(height: 8),

            // User ID
            Row(
              children: [
                const Icon(Icons.badge_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text('User ID: ${user.userId}'),
              ],
            ),

            const SizedBox(height: 8),

            // Role
            Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 18,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text('ประเภท: ${_roleLabel(user.role)}'),
              ],
            ),

            const SizedBox(height: 8),

            // Created At
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('สมัครเมื่อ: ${_formatDate(user.createdAt)}'),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Account Status
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                user.isActive ? 'บัญชีกำลังใช้งาน' : 'บัญชีถูกปิดใช้งาน',
                style: TextStyle(
                  color: user.isActive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // User Details
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserDetailsView(userId: user.userId),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility),
                label: const Text('ดูรายละเอียดและประวัติ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // Empty & Error States
  // --------------------------------------------------

  Widget _buildEmptyView({required IconData icon, required String message}) {
    return Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            controller.errorMessage ?? 'เกิดข้อผิดพลาด',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => controller.loadUsers(),
            icon: const Icon(Icons.refresh),
            label: const Text('ลองอีกครั้ง'),
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

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 25),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
