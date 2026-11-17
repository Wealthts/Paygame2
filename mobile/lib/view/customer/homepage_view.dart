import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/controller/auth_controller.dart';
import 'package:mobile/core/app_colors.dart';
import 'package:mobile/core/formatter.dart';
import 'package:mobile/model/game_model.dart';
import 'package:mobile/service/customer/customer_game_service.dart';
import 'package:mobile/service/point_service.dart';
import 'package:mobile/view/customer/coupon_view.dart';
import 'package:mobile/view/customer/order_history_view.dart';
import 'package:mobile/view/customer/package_view.dart';
import 'package:mobile/view/customer/point_view.dart';
import 'package:mobile/view/customer/user_view.dart';

class HomePageView extends StatefulWidget {
  const HomePageView({super.key});

  @override
  State<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<HomePageView> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<GameModel>> _gamesFuture;
  late Future<int> _pointsFuture;
  String _selectedCategory = 'ทั้งหมด';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    _gamesFuture = context.read<CustomerGameService>().getActiveGames();
    _pointsFuture = context.read<PointService>().getMyPoints();
  }

  Future<void> _refresh() async {
    final gamesFuture = context.read<CustomerGameService>().getActiveGames();
    final pointsFuture = context.read<PointService>().getMyPoints();
    setState(() {
      _gamesFuture = gamesFuture;
      _pointsFuture = pointsFuture;
    });
    await Future.wait(
      [gamesFuture, pointsFuture].map((future) async {
        try {
          await future;
        } catch (_) {
          // The relevant FutureBuilder displays the error state.
        }
      }),
    );
  }

  Future<void> _openDestination(int index) async {
    Widget? page;
    switch (index) {
      case 1:
        page = const OrderHistoryView();
        break;
      case 2:
        page = const CustomerPointView();
        break;
      case 3:
        page = const CustomerProfileView();
        break;
      default:
        return;
    }

    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page!));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.username ?? 'ผู้ใช้งาน');

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        titleSpacing: 18,
        title: const Row(
          children: [
            Icon(Icons.sports_esports_rounded, size: 25),
            SizedBox(width: 9),
            Text('PAYGAME'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'คูปองของฉัน',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CustomerCouponView(),
              ),
            ),
            icon: const Icon(Icons.confirmation_number_outlined),
          ),
          IconButton(
            tooltip: 'ออกจากระบบ',
            onPressed: () => context.read<AuthController>().logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<GameModel>>(
          future: _gamesFuture,
          builder: (context, snapshot) {
            final games = snapshot.data ?? const <GameModel>[];
            final categories = <String>{
              'ทั้งหมด',
              ...games
                  .map((game) => game.category.trim())
                  .where((category) => category.isNotEmpty),
            }.toList();

            final visibleGames = games.where((game) {
              final matchesCategory =
                  _selectedCategory == 'ทั้งหมด' ||
                  game.category.trim() == _selectedCategory;
              final query = _searchQuery.toLowerCase();
              final matchesSearch =
                  query.isEmpty ||
                  game.gameName.toLowerCase().contains(query) ||
                  game.category.toLowerCase().contains(query);
              return matchesCategory && matchesSearch;
            }).toList();

            return RefreshIndicator(
              color: AppColors.red,
              onRefresh: _refresh,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxContentWidth = constraints.maxWidth > 1180
                      ? 1120.0
                      : constraints.maxWidth;
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 26),
                    children: [
                      Center(
                        child: SizedBox(
                          width: maxContentWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _WelcomeHeader(displayName: displayName),
                              const SizedBox(height: 18),
                              _PointsCard(pointsFuture: _pointsFuture),
                              const SizedBox(height: 18),
                              const _PromoBanner(),
                              const SizedBox(height: 26),
                              Text(
                                'เลือกเกมที่ต้องการเติม',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _searchController,
                                onChanged: (value) =>
                                    setState(() => _searchQuery = value.trim()),
                                decoration: InputDecoration(
                                  hintText: 'ค้นหาชื่อเกม',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: _searchQuery.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: 'ล้างคำค้นหา',
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                          icon: const Icon(Icons.close),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (snapshot.hasData && games.isNotEmpty)
                                SizedBox(
                                  height: 42,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: categories.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, index) {
                                      final category = categories[index];
                                      final selected =
                                          category == _selectedCategory;
                                      return ChoiceChip(
                                        label: Text(category),
                                        selected: selected,
                                        onSelected: (_) => setState(
                                          () => _selectedCategory = category,
                                        ),
                                        selectedColor: AppColors.red,
                                        backgroundColor: AppColors.white,
                                        labelStyle: TextStyle(
                                          color: selected
                                              ? AppColors.white
                                              : AppColors.inkMuted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        side: BorderSide(
                                          color: selected
                                              ? AppColors.red
                                              : AppColors.border,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'เกมทั้งหมด',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: AppColors.ink,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  if (snapshot.hasData)
                                    Text(
                                      '${visibleGames.length} เกม',
                                      style: const TextStyle(
                                        color: AppColors.inkMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (snapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  !snapshot.hasData)
                                const _LoadingState()
                              else if (snapshot.hasError)
                                _ErrorState(
                                  onRetry: () {
                                    setState(_loadData);
                                  },
                                )
                              else if (visibleGames.isEmpty)
                                _EmptyGames(hasGames: games.isNotEmpty)
                              else
                                _buildGameGrid(
                                  visibleGames,
                                  constraints.maxWidth,
                                ),
                              const SizedBox(height: 28),
                              const Center(
                                child: Text(
                                  'PayGame • เติมเกมง่ายในที่เดียว',
                                  style: TextStyle(
                                    color: AppColors.inkMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: _openDestination,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'หน้าหลัก',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'ประวัติ',
          ),
          NavigationDestination(
            icon: Icon(Icons.stars_outlined),
            selectedIcon: Icon(Icons.stars_rounded),
            label: 'แต้มสะสม',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }

  Widget _buildGameGrid(List<GameModel> games, double width) {
    final crossAxisCount = width >= 1000
        ? 4
        : width >= 680
        ? 3
        : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: games.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 13,
        mainAxisSpacing: 13,
        childAspectRatio: width < 380 ? 0.78 : 0.88,
      ),
      itemBuilder: (context, index) {
        final game = games[index];
        return _GameCard(
          game: game,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CustomerPackageView(game: game),
            ),
          ),
        );
      },
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  final String displayName;

  const _WelcomeHeader({required this.displayName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.peach,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: AppColors.red, size: 27),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'สวัสดี, ยินดีต้อนรับ',
                style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PointsCard extends StatelessWidget {
  final Future<int> pointsFuture;

  const _PointsCard({required this.pointsFuture});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.red, AppColors.redDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.red.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: AppColors.goldLight, size: 38),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'แต้มสะสมของคุณ',
                  style: TextStyle(color: AppColors.white, fontSize: 13),
                ),
                const SizedBox(height: 3),
                FutureBuilder<int>(
                  future: pointsFuture,
                  builder: (context, snapshot) {
                    final label = snapshot.hasData
                        ? AppFormatter.formatPoints(snapshot.data!)
                        : snapshot.hasError
                        ? '—'
                        : 'กำลังโหลด';
                    return Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Text(
            'POINTS',
            style: TextStyle(
              color: AppColors.goldLight,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.peach,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flash_on_rounded, color: AppColors.white),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'เติมเกมได้สะดวกในที่เดียว',
                  style: TextStyle(
                    color: AppColors.goldInk,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'เลือกเกม เลือกแพ็กเกจ แล้วทำรายการได้ทันที',
                  style: TextStyle(color: AppColors.goldText, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final GameModel game;
  final VoidCallback onTap;

  const _GameCard({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _GameImage(url: game.imageUrl)),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.gameName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    game.category.isEmpty ? 'เกมออนไลน์' : game.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Icon(
                        game.requiresServer
                            ? Icons.dns_outlined
                            : Icons.check_circle_outline,
                        size: 14,
                        color: game.requiresServer
                            ? AppColors.goldText
                            : AppColors.success,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          game.requiresServer
                              ? 'ต้องระบุเซิร์ฟเวอร์'
                              : 'พร้อมให้บริการ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: game.requiresServer
                                ? AppColors.goldText
                                : AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameImage extends StatelessWidget {
  final String url;

  const _GameImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url.trim());
    final valid =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;

    if (!valid) return _placeholder();

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.creamDeep,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      },
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.creamDeep,
      alignment: Alignment.center,
      child: const Icon(
        Icons.sports_esports_rounded,
        size: 42,
        color: AppColors.red,
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 52),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text('กำลังโหลดรายการเกม...'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 52,
            color: AppColors.danger,
          ),
          const SizedBox(height: 12),
          const Text(
            'ไม่สามารถโหลดรายการเกมได้',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'ตรวจสอบ Node server แล้วลองอีกครั้ง',
            style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('ลองอีกครั้ง'),
          ),
        ],
      ),
    );
  }
}

class _EmptyGames extends StatelessWidget {
  final bool hasGames;

  const _EmptyGames({required this.hasGames});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 38),
      child: Column(
        children: [
          const Icon(
            Icons.sports_esports_outlined,
            size: 54,
            color: AppColors.goldText,
          ),
          const SizedBox(height: 12),
          Text(
            hasGames
                ? 'ไม่พบเกมที่ตรงกับการค้นหา'
                : 'ยังไม่มีเกมที่เปิดให้บริการ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'ลองเปลี่ยนคำค้นหาหรือตรวจสอบอีกครั้งภายหลัง',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
