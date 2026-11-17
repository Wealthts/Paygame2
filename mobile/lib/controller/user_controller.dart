import 'package:material_ui/material_ui.dart';

import 'package:mobile/model/user_model.dart';
import 'package:mobile/service/user_service.dart';

class UserController extends ChangeNotifier {
  final UserService _service;

  UserController(this._service);

  UserModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> loadMyProfile() async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _service.getMyProfile();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _profile = null;
    _errorMessage = null;
    notifyListeners();
  }
}
