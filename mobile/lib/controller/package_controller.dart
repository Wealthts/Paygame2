import 'package:flutter/foundation.dart';

import 'package:mobile/model/game_model.dart';
import 'package:mobile/model/package_model.dart';
import 'package:mobile/service/game_service.dart';
import 'package:mobile/service/package_service.dart';
import 'package:mobile/service/api_service.dart';

class PackageController extends ChangeNotifier {
  final PackageService packageService;
  final GameService gameService;

  PackageController(this.packageService, this.gameService);

  bool _isLoading = false;
  bool _isSaving = false;

  List<PackageModel> _packages = [];
  List<GameModel> _games = [];

  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  List<PackageModel> get packages => _packages;
  List<GameModel> get games => _games;
  String? get errorMessage => _errorMessage;

  // ========================================
  // Load Packages and Games
  // ========================================
  Future<void> loadData() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        packageService.getAllPackages(),
        gameService.getAllGames(),
      ]);

      _packages = results[0] as List<PackageModel>;
      _games = results[1] as List<GameModel>;
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================
  // Create Package
  // ========================================
  Future<bool> createPackage(Map<String, dynamic> data) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await packageService.createPackage(data);
      await _reloadPackages();
      return true;
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ========================================
  // Update Package
  // ========================================
  Future<bool> updatePackage(int packageId, Map<String, dynamic> data) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await packageService.updatePackage(packageId, data);
      await _reloadPackages();
      return true;
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ========================================
  // Update Package Status
  // ========================================
  Future<bool> updatePackageStatus(int packageId, bool isActive) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await packageService.updatePackageStatus(packageId, isActive);

      await _reloadPackages();
      return true;
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ========================================
  // Reload Packages
  // ========================================
  Future<void> _reloadPackages() async {
    _packages = await packageService.getAllPackages();
  }

  // ========================================
  // Error Message
  // ========================================
  String _getErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    if (error is FormatException) {
      return 'รูปแบบข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง';
    }

    return 'ไม่สามารถจัดการข้อมูลแพ็กเกจได้';
  }
}
