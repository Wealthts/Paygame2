class GameModel {
  final int gameId;
  final String gameName;
  final String category;
  final String uidPattern;
  final bool requiresServer;
  final String imageUrl;
  final bool isActive;

  const GameModel({
    required this.gameId,
    required this.gameName,
    required this.category,
    required this.uidPattern,
    required this.requiresServer,
    required this.imageUrl,
    required this.isActive,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;

      final text = value?.toString().toLowerCase();

      return text == '1' || text == 'true';
    }

    return GameModel(
      gameId: parseInt(json['game_id']),
      gameName: json['game_name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      uidPattern: json['uid_pattern']?.toString() ?? '',
      requiresServer: parseBool(json['requires_server']),
      imageUrl: json['image_url']?.toString() ?? '',
      isActive: parseBool(json['is_active']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'game_id': gameId,
      'game_name': gameName,
      'category': category,
      'uid_pattern': uidPattern,
      'requires_server': requiresServer ? 1 : 0,
      'image_url': imageUrl,
      'is_active': isActive ? 1 : 0,
    };
  }
}
