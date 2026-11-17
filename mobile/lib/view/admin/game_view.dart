import 'package:material_ui/material_ui.dart';
import 'package:mobile/core/app_colors.dart';
import 'package:provider/provider.dart';

import '../../controller/game_controller.dart';
import '../../model/game_model.dart';
import '../../service/game_service.dart';

class GameView extends StatelessWidget {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          GameController(context.read<GameService>())..loadGames(),
      child: const _GamePage(),
    );
  }
}

class _GamePage extends StatelessWidget {
  const _GamePage();

  Future<void> _openGameForm(BuildContext context, {GameModel? game}) async {
    final controller = context.read<GameController>();

    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _GameFormDialog(game: game),
    );

    if (data == null || !context.mounted) return;

    final success = game == null
        ? await controller.createGame(data)
        : await controller.updateGame(game.gameId, data);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? game == null
                    ? 'เพิ่มเกมสำเร็จ'
                    : 'แก้ไขเกมสำเร็จ'
              : controller.errorMessage ?? 'เกิดข้อผิดพลาด',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _changeGameStatus(
    BuildContext context,
    GameModel game,
    bool isActive,
  ) async {
    final controller = context.read<GameController>();

    final success = await controller.updateGameStatus(game.gameId, isActive);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'เปลี่ยนสถานะเกมสำเร็จ'
              : controller.errorMessage ?? 'เปลี่ยนสถานะไม่สำเร็จ',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        foregroundColor: AppColors.white,
        title: const Text('Game Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: controller.isLoading ? null : controller.loadGames,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Add Game',
            onPressed: controller.isSaving
                ? null
                : () => _openGameForm(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _buildBody(context, controller),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.isSaving ? null : () => _openGameForm(context),
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Game'),
      ),
    );
  }

  Widget _buildBody(BuildContext context, GameController controller) {
    if (controller.isLoading && controller.games.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage != null && controller.games.isEmpty) {
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
                onPressed: controller.loadGames,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadGames,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Games (${controller.games.length})',
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
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'ยังไม่มีข้อมูลเกม',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inkMuted),
              ),
            ),

          ...controller.games.map(
            (game) => _GameCard(
              game: game,
              enabled: !controller.isSaving,
              onEdit: () => _openGameForm(context, game: game),
              onStatusChanged: (value) =>
                  _changeGameStatus(context, game, value),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ==========================================
// Game Card
// ==========================================
class _GameCard extends StatelessWidget {
  final GameModel game;
  final bool enabled;
  final VoidCallback onEdit;
  final ValueChanged<bool> onStatusChanged;

  const _GameCard({
    required this.game,
    required this.enabled,
    required this.onEdit,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final imageUri = Uri.tryParse(game.imageUrl);

    final hasValidImage =
        imageUri != null &&
        (imageUri.scheme == 'http' || imageUri.scheme == 'https');

    return Card(
      color: AppColors.white,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: hasValidImage
                        ? Image.network(
                            game.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) {
                              return _imagePlaceholder();
                            },
                          )
                        : _imagePlaceholder(),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.gameName,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Category: ${game.category}',
                        style: const TextStyle(color: AppColors.inkMuted),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'UID: ${game.uidPattern}',
                        style: const TextStyle(color: AppColors.inkMuted),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        game.requiresServer
                            ? 'Requires Server: Yes'
                            : 'Requires Server: No',
                        style: const TextStyle(color: AppColors.inkMuted),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Icon(
                            game.isActive ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: game.isActive
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            game.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: game.isActive
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                IconButton(
                  tooltip: 'Edit Game',
                  onPressed: enabled ? onEdit : null,
                  icon: const Icon(Icons.edit_outlined, color: AppColors.red),
                ),
              ],
            ),

            const Divider(color: AppColors.divider),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Game Status',
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                ),

                Switch.adaptive(
                  value: game.isActive,
                  onChanged: enabled ? onStatusChanged : null,
                  activeThumbColor: AppColors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.creamDeep,
      child: const Icon(Icons.sports_esports, color: AppColors.red, size: 38),
    );
  }
}

// ==========================================
// Game Form Dialog
// ==========================================
class _GameFormDialog extends StatefulWidget {
  final GameModel? game;

  const _GameFormDialog({this.game});

  @override
  State<_GameFormDialog> createState() => _GameFormDialogState();
}

class _GameFormDialogState extends State<_GameFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _gameNameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _uidPatternController;
  late final TextEditingController _imageUrlController;

  late bool _requiresServer;
  late bool _isActive;

  @override
  void initState() {
    super.initState();

    final game = widget.game;
    _gameNameController = TextEditingController(text: game?.gameName ?? '');
    _categoryController = TextEditingController(text: game?.category ?? '');
    _uidPatternController = TextEditingController(text: game?.uidPattern ?? '');
    _imageUrlController = TextEditingController(text: game?.imageUrl ?? '');
    _requiresServer = game?.requiresServer ?? false;
    _isActive = game?.isActive ?? true;
  }

  @override
  void dispose() {
    _gameNameController.dispose();
    _categoryController.dispose();
    _uidPatternController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop({
      'game_name': _gameNameController.text.trim(),
      'category': _categoryController.text.trim(),
      'uid_pattern': _uidPatternController.text.trim(),
      'requires_server': _requiresServer ? 1 : 0,
      'image_url': _imageUrlController.text.trim(),
      'is_active': _isActive ? 1 : 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.game != null;

    return AlertDialog(
      backgroundColor: AppColors.white,
      title: Text(
        isEditing ? 'Edit Game' : 'Add Game',
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
                _field(
                  controller: _gameNameController,
                  label: 'Game Name',
                  maxLength: 100,
                ),

                _field(
                  controller: _categoryController,
                  label: 'Category',
                  maxLength: 100,
                ),

                _field(
                  controller: _uidPatternController,
                  label: 'UID Pattern',
                  maxLength: 100,
                ),

                _field(
                  controller: _imageUrlController,
                  label: 'Image URL (optional)',
                  maxLength: 255,
                  isRequired: false,
                  keyboardType: TextInputType.url,
                ),

                const SizedBox(height: 12),

                CheckboxListTile(
                  value: _requiresServer,
                  onChanged: (value) {
                    setState(() {
                      _requiresServer = value ?? false;
                    });
                  },
                  title: const Text(
                    'Requires Server',
                    style: TextStyle(color: AppColors.ink),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.red,
                ),

                CheckboxListTile(
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value ?? false;
                    });
                  },
                  title: const Text(
                    'Active',
                    style: TextStyle(color: AppColors.ink),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.red,
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
          child: Text(isEditing ? 'Save Changes' : 'Create Game'),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required int maxLength,
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLength: maxLength,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.ink),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.inkMuted),
          counterStyle: const TextStyle(color: AppColors.inkMuted),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.red),
          ),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return 'กรุณากรอก $label';
          }

          return null;
        },
      ),
    );
  }
}
