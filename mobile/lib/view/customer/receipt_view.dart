import 'package:material_ui/material_ui.dart';

import 'package:mobile/model/receipt_model.dart';
import 'package:mobile/view/customer/receipt_details_view.dart';

/// Compatibility entry point for receipt screens. The actual receipt layout
/// and PDF export are implemented by CustomerReceiptDetailsView.
class CustomerReceiptView extends StatelessWidget {
  final ReceiptModel receipt;

  const CustomerReceiptView({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    return CustomerReceiptDetailsView(receipt: receipt);
  }
}
