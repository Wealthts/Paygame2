import 'package:material_ui/material_ui.dart';
import 'package:mobile/core/app_colors.dart';
import 'package:provider/provider.dart';

import '../../controller/package_controller.dart';
import '../../model/package_model.dart';
import '../../model/game_model.dart';
import '../../service/package_service.dart';
import '../../service/game_service.dart';

class PackageView extends StatelessWidget {
  const PackageView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PackageController(
        context.read<PackageService>(),
        context.read<GameService>(),
      )..loadData(),
      child: const _PackagePage(),
    );
  }
}

// ==========================================
// Package Page
// ==========================================
class _PackagePage extends StatelessWidget {
  const _PackagePage();

  Future<void> _openForm(BuildContext context, {PackageModel? package}) async {
    final controller = context.read<PackageController>();

    if (controller.games.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาสร้างเกมก่อนเพิ่มแพ็กเกจ')),
      );
      return;
    }

    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) =>
          _PackageFormDialog(games: controller.games, package: package),
    );

    if (data == null || !context.mounted) return;

    final success = package == null
        ? await controller.createPackage(data)
        : await controller.updatePackage(package.packageId, data);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? package == null
                    ? 'เพิ่มแพ็กเกจสำเร็จ'
                    : 'แก้ไขแพ็กเกจสำเร็จ'
              : controller.errorMessage ?? 'เกิดข้อผิดพลาด',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    PackageModel package,
    bool isActive,
  ) async {
    final controller = context.read<PackageController>();

    final success = await controller.updatePackageStatus(
      package.packageId,
      isActive,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'เปลี่ยนสถานะแพ็กเกจสำเร็จ'
              : controller.errorMessage ?? 'เปลี่ยนสถานะไม่สำเร็จ',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PackageController>();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        foregroundColor: AppColors.white,
        title: const Text('Package Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: controller.isLoading || controller.isSaving
                ? null
                : controller.loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(context, controller),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.isSaving ? null : () => _openForm(context),
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Package'),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PackageController controller) {
    if (controller.isLoading && controller.packages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage != null && controller.packages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                controller.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.inkMuted),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: controller.loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Packages (${controller.packages.length})',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (controller.isSaving)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),

          const SizedBox(height: 16),

          if (controller.games.isEmpty)
            const Card(
              color: AppColors.white,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'ยังไม่มีเกมในระบบ กรุณาเพิ่มเกมก่อน',
                  style: TextStyle(color: AppColors.inkMuted),
                ),
              ),
            ),

          if (controller.packages.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'ยังไม่มีข้อมูลแพ็กเกจ',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inkMuted),
              ),
            ),

          ...controller.packages.map(
            (package) => _PackageCard(
              package: package,
              enabled: !controller.isSaving,
              onEdit: () => _openForm(context, package: package),
              onStatusChanged: (value) =>
                  _changeStatus(context, package, value),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ==========================================
// Package Card
// ==========================================
class _PackageCard extends StatelessWidget {
  final PackageModel package;
  final bool enabled;
  final VoidCallback onEdit;
  final ValueChanged<bool> onStatusChanged;

  const _PackageCard({
    required this.package,
    required this.enabled,
    required this.onEdit,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.white,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.red,
                  size: 38,
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.packageName,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        package.gameName,
                        style: const TextStyle(color: AppColors.inkMuted),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        '฿${package.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.red,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  tooltip: 'Edit Package',
                  onPressed: enabled ? onEdit : null,
                  icon: const Icon(Icons.edit_outlined, color: AppColors.red),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Package ID: ${package.packageId}',
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 12,
                    ),
                  ),
                ),

                Text(
                  package.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: package.isActive
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(width: 8),

                Switch.adaptive(
                  value: package.isActive,
                  onChanged: enabled ? onStatusChanged : null,
                  activeThumbColor: AppColors.red,
                ),
              ],
            ),

            if (package.requiresServer)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Game requires server selection',
                  style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// Package Form Dialog
// ==========================================
class _PackageFormDialog extends StatefulWidget {
  final List<GameModel> games;
  final PackageModel? package;

  const _PackageFormDialog({required this.games, this.package});

  @override
  State<_PackageFormDialog> createState() => _PackageFormDialogState();
}

class _PackageFormDialogState extends State<_PackageFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;

  int? _selectedGameId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();

    final package = widget.package;

    _nameController = TextEditingController(text: package?.packageName ?? '');

    _priceController = TextEditingController(
      text: package?.price.toString() ?? '',
    );

    _selectedGameId = package?.gameId ?? widget.games.first.gameId;

    _isActive = package?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceController.text.trim());

    if (price == null || _selectedGameId == null) return;

    Navigator.of(context).pop({
      'game_id': _selectedGameId,
      'package_name': _nameController.text.trim(),
      'price': price,
      'is_active': _isActive ? 1 : 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.package != null;

    return AlertDialog(
      backgroundColor: AppColors.white,
      title: Text(
        isEditing ? 'Edit Package' : 'Add Package',
        style: const TextStyle(color: AppColors.ink),
      ),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _selectedGameId,
                  isExpanded: true,
                  dropdownColor: AppColors.creamDeep,
                  decoration: const InputDecoration(
                    labelText: 'Select Game',
                    labelStyle: TextStyle(color: AppColors.inkMuted),
                  ),
                  items: widget.games.map((game) {
                    return DropdownMenuItem<int>(
                      value: game.gameId,
                      child: Text(
                        game.isActive
                            ? game.gameName
                            : '${game.gameName} (Inactive)',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGameId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'กรุณาเลือกเกม';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _nameController,
                  maxLength: 100,
                  style: const TextStyle(color: AppColors.ink),
                  decoration: const InputDecoration(
                    labelText: 'Package Name',
                    labelStyle: TextStyle(color: AppColors.inkMuted),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกชื่อแพ็กเกจ';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: AppColors.ink),
                  decoration: const InputDecoration(
                    labelText: 'Price (Baht)',
                    labelStyle: TextStyle(color: AppColors.inkMuted),
                    prefixText: '฿ ',
                  ),
                  validator: (value) {
                    final price = double.tryParse(value?.trim() ?? '');

                    if (price == null ||
                        !price.isFinite ||
                        price <= 0 ||
                        price > 99999999.99) {
                      return 'กรุณากรอกราคาที่ถูกต้อง';
                    }

                    final scaledPrice = price * 100;
                    if ((scaledPrice - scaledPrice.round()).abs() > 0.000001) {
                      return 'รองรับทศนิยมไม่เกิน 2 ตำแหน่ง';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'Active',
                    style: TextStyle(color: AppColors.ink),
                  ),
                  value: _isActive,
                  activeColor: AppColors.red,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),

        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(isEditing ? 'Save Changes' : 'Create Package'),
        ),
      ],
    );
  }
}
