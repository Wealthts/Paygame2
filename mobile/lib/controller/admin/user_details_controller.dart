import 'package:material_ui/material_ui.dart';

import '../../model/admin/user_details_model.dart';
import '../../service/admin/user_management_service.dart';

class UserDetailsController extends ChangeNotifier {
  final UserManagementService userService;

  UserDetailsController(this.userService);

  UserDetailsModel? details;

  bool isLoading = false;
  String? errorMessage;

  Future<void> loadDetails(int userId) async {
    if (isLoading) return;
    final hasExistingDetails = details != null;
    isLoading = !hasExistingDetails;
    errorMessage = null;
    notifyListeners();

    try {
      details = await userService.getUserDetails(userId);
    } catch (e) {
      if (!hasExistingDetails) {
        errorMessage = e.toString();
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
