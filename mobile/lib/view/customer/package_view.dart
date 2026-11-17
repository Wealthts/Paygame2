import 'package:material_ui/material_ui.dart';
import 'package:mobile/core/app_colors.dart';
import 'package:provider/provider.dart';

import 'package:mobile/model/game_model.dart';
import 'package:mobile/model/package_model.dart';
import 'package:mobile/service/customer/customer_package_service.dart';
import 'package:mobile/view/customer/order_view.dart';

class CustomerPackageView extends StatefulWidget {
  final GameModel game;

  const CustomerPackageView({required this.game, super.key});

  @override
  State<CustomerPackageView> createState() => _CustomerPackageViewState();
}

class _CustomerPackageViewState extends State<CustomerPackageView> {
  late Future<List<PackageModel>> _packagesFuture;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  // ========================================
  // Load Packages
  // ========================================
  void _loadPackages() {
    _packagesFuture = context.read<CustomerPackageService>().getPackagesByGame(
      widget.game.gameId,
    );
  }

  // ========================================
  // Refresh Packages
  // ========================================
  Future<void> _refreshPackages() async {
    final future = context.read<CustomerPackageService>().getPackagesByGame(
      widget.game.gameId,
    );

    setState(() {
      _packagesFuture = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder แสดง Error ให้เอง
    }
  }

  // ========================================
  // Retry
  // ========================================
  void _retryLoading() {
    setState(_loadPackages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,

      appBar: AppBar(
        foregroundColor: AppColors.white,
        title: Text(
          widget.game.gameName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),

      body: SafeArea(
        child: FutureBuilder<List<PackageModel>>(
          future: _packagesFuture,
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
                      'กำลังโหลดแพ็กเกจ...',
                      style: TextStyle(color: AppColors.inkMuted),
                    ),
                  ],
                ),
              );
            }

            // Error
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off,
                        color: AppColors.inkMuted,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ไม่สามารถโหลดแพ็กเกจได้',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
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

            final packages = snapshot.data ?? [];

            return RefreshIndicator(
              onRefresh: _refreshPackages,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _buildGameHeader(),

                  const SizedBox(height: 26),

                  const Text(
                    'เลือกแพ็กเกจที่ต้องการ',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'พบ ${packages.length} แพ็กเกจ',
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (packages.isEmpty)
                    _buildEmptyPackages()
                  else
                    ...packages.map(
                      (package) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PackageCard(
                          package: package,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => CustomerOrderView(
                                  game: widget.game,
                                  package: package,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ========================================
  // Game Header
  // ========================================
  Widget _buildGameHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGameImage(),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.game.gameName,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (widget.game.category.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.game.category,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 13,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      widget.game.requiresServer
                          ? 'เกมนี้ต้องระบุเซิร์ฟเวอร์'
                          : 'เกมนี้ไม่ต้องระบุเซิร์ฟเวอร์',
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // Game Image
  // ========================================
  Widget _buildGameImage() {
    final imageUrl = widget.game.imageUrl.trim();
    final uri = Uri.tryParse(imageUrl);

    final isValidUrl =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;

    if (!isValidUrl) {
      return _gameImagePlaceholder();
    }

    return Image.network(
      imageUrl,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _gameImagePlaceholder();
      },
    );
  }

  Widget _gameImagePlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      color: AppColors.creamDeep,
      child: const Center(
        child: Icon(Icons.sports_esports, size: 65, color: AppColors.red),
      ),
    );
  }

  // ========================================
  // Empty Packages
  // ========================================
  Widget _buildEmptyPackages() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, color: AppColors.inkMuted, size: 55),
          SizedBox(height: 14),
          Text(
            'ยังไม่มีแพ็กเกจสำหรับเกมนี้',
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'กรุณากลับมาตรวจสอบอีกครั้งภายหลัง',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// PACKAGE CARD
// ==========================================
class _PackageCard extends StatelessWidget {
  final PackageModel package;
  final VoidCallback onTap;

  const _PackageCard({required this.package, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.redDark,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.diamond, color: Colors.white, size: 27),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.packageName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    package.gameName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '฿${package.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.goldText,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.inkMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
