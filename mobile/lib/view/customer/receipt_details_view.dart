import 'package:material_ui/material_ui.dart';
import 'package:mobile/core/app_colors.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../model/receipt_model.dart';

class CustomerReceiptDetailsView extends StatefulWidget {
  final ReceiptModel receipt;

  const CustomerReceiptDetailsView({super.key, required this.receipt});

  @override
  State<CustomerReceiptDetailsView> createState() =>
      _CustomerReceiptDetailsViewState();
}

class _CustomerReceiptDetailsViewState
    extends State<CustomerReceiptDetailsView> {
  bool _isPrinting = false;

  ReceiptModel get receipt => widget.receipt;

  // ========================================
  // Print / Save Receipt PDF
  // ========================================
  Future<void> _printReceiptPdf() async {
    setState(() {
      _isPrinting = true;
    });

    try {
      // Load Thai-capable font for the PDF
      final thaiRegular = await PdfGoogleFonts.notoSansThaiRegular();
      final thaiBold = await PdfGoogleFonts.notoSansThaiBold();

      // Build the PDF document
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(base: thaiRegular, bold: thaiBold),
      );

      final amount = (receipt.totalAmount ?? 0).toStringAsFixed(2);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'PAYGAME',
                    style: pw.TextStyle(
                      font: thaiBold,
                      fontSize: 25,
                      color: PdfColors.deepPurple,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'Receipt',
                    style: pw.TextStyle(font: thaiBold, fontSize: 20),
                  ),
                ),

                pw.SizedBox(height: 6),

                pw.Center(
                  child: pw.Text(
                    'PAYGAME PAYMENT RECEIPT',
                    style: pw.TextStyle(
                      font: thaiRegular,
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
                pw.SizedBox(height: 28),
                // Receipt details
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(24),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      _pdfRow(
                        'Receipt No.',
                        receipt.receiptNumber,
                        thaiRegular,
                        thaiBold,
                      ),
                      pw.Divider(color: PdfColors.grey300),
                      _pdfRow(
                        'Receipt ID',
                        '${receipt.receiptId}',
                        thaiRegular,
                        thaiBold,
                      ),
                      _pdfRow(
                        'Order ID',
                        '#${receipt.orderId}',
                        thaiRegular,
                        thaiBold,
                      ),
                      _pdfRow(
                        'Game',
                        receipt.gameName ?? '-',
                        thaiRegular,
                        thaiBold,
                      ),
                      _pdfRow(
                        'Package',
                        receipt.packageName ?? '-',
                        thaiRegular,
                        thaiBold,
                      ),
                      _pdfRow(
                        'Issued at',
                        _formatDate(receipt.issuedAt),
                        thaiRegular,
                        thaiBold,
                      ),
                      pw.SizedBox(height: 12),
                      pw.Divider(color: PdfColors.grey500, thickness: 1.2),
                      pw.SizedBox(height: 12),

                      // Total amount
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Total paid',
                            style: pw.TextStyle(font: thaiBold, fontSize: 16),
                          ),
                          pw.Text(
                            '฿$amount',
                            style: pw.TextStyle(
                              font: thaiBold,
                              fontSize: 19,
                              color: PdfColors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 35),

                // Footer
                pw.Center(
                  child: pw.Text(
                    'Thank you for using PAYGAME',
                    style: pw.TextStyle(font: thaiBold, fontSize: 13),
                  ),
                ),

                pw.SizedBox(height: 8),

                pw.Center(
                  child: pw.Text(
                    'This document was generated by PayGame',
                    style: pw.TextStyle(
                      font: thaiRegular,
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Open the print / save PDF dialog
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          return pdf.save();
        },
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not create PDF: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  // ========================================
  // PDF Detail Row
  // ========================================
  pw.Widget _pdfRow(
    String label,
    String value,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 9),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 4,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 11,
                color: PdfColors.grey700,
              ),
            ),
          ),

          pw.SizedBox(width: 12),

          pw.Expanded(
            flex: 6,
            child: pw.Text(
              value.isEmpty ? '-' : value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(font: boldFont, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // Main UI
  // ========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        foregroundColor: AppColors.white,
        title: const Text('Receipt Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 12),

            const Icon(
              Icons.verified_outlined,
              color: AppColors.success,
              size: 64,
            ),

            const SizedBox(height: 12),

            const Text(
              'Receipt',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'PAYGAME',
              style: TextStyle(
                color: AppColors.goldText,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 24),

            // Receipt Information
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _detailRow('Receipt No.', receipt.receiptNumber),

                  const Divider(color: AppColors.divider, height: 28),

                  _detailRow('Receipt ID', '${receipt.receiptId}'),

                  const SizedBox(height: 18),

                  _detailRow('Order ID', '#${receipt.orderId}'),

                  const SizedBox(height: 18),

                  _detailRow('Game', receipt.gameName ?? '-'),

                  const SizedBox(height: 18),

                  _detailRow('Package', receipt.packageName ?? '-'),

                  const SizedBox(height: 18),

                  _detailRow('Issued at', _formatDate(receipt.issuedAt)),

                  const Divider(color: AppColors.divider, height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total paid',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '฿${(receipt.totalAmount ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.goldText,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Print / Save PDF Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isPrinting ? null : _printReceiptPdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.border,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isPrinting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(
                  _isPrinting ? 'Creating PDF...' : 'Print / Save PDF',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'These receipt details come from PayGame',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ========================================
  // UI Detail Row
  // ========================================
  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ========================================
  // Date Format
  // ========================================
  String _formatDate(DateTime? date) {
    if (date == null) return '-';

    final value = date.toLocal();

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();

    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}
