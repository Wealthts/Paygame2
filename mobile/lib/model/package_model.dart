class PackageModel {
  final int packageId;
  final int gameId;
  final String packageName;
  final String gameName;
  final double price;
  final bool isActive;
  final bool requiresServer;

  const PackageModel({
    required this.packageId,
    required this.gameId,
    required this.packageName,
    required this.gameName,
    required this.price,
    required this.isActive,
    required this.requiresServer,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      final text = value?.toString().toLowerCase();
      return text == '1' || text == 'true';
    }

    return PackageModel(
      packageId: parseInt(json['package_id']),
      gameId: parseInt(json['game_id']),
      packageName: json['package_name']?.toString() ?? '',
      gameName: json['game_name']?.toString() ?? '',
      price: parseDouble(json['price']),
      isActive: parseBool(json['is_active']),
      requiresServer: parseBool(json['requires_server']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'game_id': gameId,
      'package_name': packageName,
      'price': price,
      'is_active': isActive ? 1 : 0,
    };
  }
}
