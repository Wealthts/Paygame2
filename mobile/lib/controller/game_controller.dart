import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';

import 'package:mobile/model/game_model.dart';
import 'package:mobile/service/game_service.dart';
import 'package:mobile/service/api_service.dart';

class GameController extends ChangeNotifier {
  final GameService gameService;

  GameController(this.gameService);

  bool _isLoading = false;
  bool _isSaving = false;

  List<GameModel> _games = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  List<GameModel> get games => _games;
  String? get errorMessage => _errorMessage;

  // ========================================
  // Load Games
  // ========================================
  Future<void> loadGames() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _games = await gameService.getAllGames();
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================
  // Create Game
  // ========================================
  Future<bool> createGame(Map<String, dynamic> data) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await gameService.createGame(data);
      await _reloadGames();
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
  // Update Game
  // ========================================
  Future<bool> updateGame(int gameId, Map<String, dynamic> data) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await gameService.updateGame(gameId, data);
      await _reloadGames();
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
  // Toggle Game Status
  // ========================================
  Future<bool> updateGameStatus(int gameId, bool isActive) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await gameService.updateGameStatus(gameId, isActive);

      await _reloadGames();
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
  // Reload Data
  // ========================================
  Future<void> _reloadGames() async {
    _games = await gameService.getAllGames();
  }

  // ========================================
  // Error Message
  // ========================================
  String _getErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    if (error is FormatException) {
      return 'รูปแบบข้อมูลเกมจากเซิร์ฟเวอร์ไม่ถูกต้อง';
    }

    return 'ไม่สามารถจัดการข้อมูลเกมได้';
  }
}
