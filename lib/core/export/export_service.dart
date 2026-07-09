import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../constants/constants.dart';
import '../../ui/ledger/profit_loss_sheet.dart';
import '../utils/format_helpers.dart';

/// Service to export financial reports as CSV and PDF files.
class ExportService {
  ExportService._();

  /// Export P&L data as CSV and share it
  static Future<void> exportCsv({
    required String businessName,
    required String periodLabel,
    required ProfitLossData data,
  }) async {
    final csv = _buildCsv(businessName, periodLabel, data);
    final dir = await getTemporaryDirectory();
    final fileName =
        'Laporan_LabaRugi_${businessName.replaceAll(' ', '_')}_$periodLabel.csv'
            .replaceAll(' ', '_');
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csv, flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Laporan Laba/Rugi - $businessName ($periodLabel)',
    );
  }

  /// Export P&L data as PDF and share it
  static Future<void> exportPdf({
    required String businessName,
    required String periodLabel,
    required ProfitLossData data,
  }) async {
    final pdfBytes = await _buildPdf(businessName, periodLabel, data);
    final dir = await getTemporaryDirectory();
    final fileName =
        'Laporan_LabaRugi_${businessName.replaceAll(' ', '_')}_$periodLabel.pdf'
            .replaceAll(' ', '_');
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(pdfBytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Laporan Laba/Rugi - $businessName ($periodLabel)',
    );
  }

  /// Build CSV content
  static String _buildCsv(
    String businessName,
    String periodLabel,
    ProfitLossData data,
  ) {
    final buf = StringBuffer();

    // Helper to escape CSV values
    String esc(String v) => v.contains(',') ? '"${v.replaceAll('"', '""')}"' : v;

    // Title
    buf.writeln('Laporan Laba / Rugi');
    buf.writeln('$businessName - $periodLabel');
    buf.writeln(
        'Dicetak: ${FormatHelpers.displayDate(DateTime.now().toIso8601String().substring(0, 10))}');
    buf.writeln('');
    buf.writeln('');

    // Income section
    buf.writeln('PENDAPATAN');
    buf.writeln('Kategori,Jumlah,Transaksi');
    for (final b in data.incomeBreakdown) {
      buf.writeln(
          '${esc(b.categoryName)},${b.amount.toStringAsFixed(0)},${b.count}');
    }
    buf.writeln('Total Pendapatan,${data.totalIncome.toStringAsFixed(0)},');
    buf.writeln('');

    // COGS
    buf.writeln('HPP (Harga Pokok Penjualan)');
    buf.writeln('Total HPP,${data.totalCogs.toStringAsFixed(0)},');
    buf.writeln('');

    // Gross Profit
    buf.writeln('Laba Kotor,${data.grossProfit.toStringAsFixed(0)},');
    buf.writeln('');

    // Expense section
    buf.writeln('PENGELUARAN');
    buf.writeln('Kategori,Jumlah,Transaksi');
    for (final b in data.expenseBreakdown) {
      buf.writeln(
          '${esc(b.categoryName)},${b.amount.toStringAsFixed(0)},${b.count}');
    }
    buf.writeln('Total Pengeluaran,${data.totalExpense.toStringAsFixed(0)},');
    buf.writeln('');

    // Net Profit
    buf.writeln('LABA / RUGI BERSIH,${data.netProfit.toStringAsFixed(0)},');
    buf.writeln('Status,${data.status == 'laba' ? 'LABA' : 'RUGI'},');
    buf.writeln('');

    // Transaction list
    buf.writeln('');
    buf.writeln('=== DAFTAR TRANSAKSI ===');
    buf.writeln('Tanggal,Tipe,Jumlah,HPP,Deskripsi,Metode Bayar');
    for (final tx in data.transactions) {
      final tipe = tx.type == 'income' ? 'Uang Masuk' : 'Uang Keluar';
      final cogs = tx.type == 'income' ? tx.cogs.toStringAsFixed(0) : '0';
      buf.writeln(
        '${tx.transactionDate},$tipe,'
        '${tx.amount.toStringAsFixed(0)},$cogs,'
        '${esc(tx.description ?? '')},${tx.paymentMethod}',
      );
    }

    return buf.toString();
  }

  /// Build PDF document
  static Future<List<int>> _buildPdf(
    String businessName,
    String periodLabel,
    ProfitLossData data,
  ) async {
    final pdf = pw.Document();

    final fontTitle = pw.TextStyle(
      fontSize: 22,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.indigo800,
    );
    final fontHeader = pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final fontNormal = pw.TextStyle(fontSize: 10);
    final fontTotal = pw.TextStyle(
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
    );
    final fontProfit = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          // Title
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(AppConstants.appName, style: fontTitle),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Laporan Laba / Rugi',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '$businessName — $periodLabel',
                  style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 8),
                pw.Divider(),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // === INCOME ===
          pw.Container(
            color: PdfColors.green50,
            padding: const pw.EdgeInsets.all(6),
            child: pw.Row(
              children: [
                pw.Text('PENDAPATAN',
                    style:
                        fontHeader.copyWith(color: PdfColors.green800)),
              ],
            ),
          ),
          pw.SizedBox(height: 4),
          ...data.incomeBreakdown.map((b) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(b.categoryName, style: fontNormal),
                    pw.Row(
                      children: [
                        pw.Text('${b.count}x  ',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey600,
                            )),
                        pw.Text(FormatHelpers.rupiah(b.amount),
                            style: fontNormal),
                      ],
                    ),
                  ],
                ),
              )),
          if (data.incomeBreakdown.isEmpty)
            pw.Text('Belum ada pendapatan',
                style:
                    pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Pendapatan', style: fontTotal),
              pw.Text(FormatHelpers.rupiah(data.totalIncome),
                  style: fontTotal.copyWith(color: PdfColors.green700)),
            ],
          ),
          pw.SizedBox(height: 16),

          // === COGS ===
          pw.Container(
            color: PdfColors.orange50,
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text('HPP (HARGA POKOK PENJUALAN)',
                style: fontHeader.copyWith(color: PdfColors.orange800)),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total HPP', style: fontNormal),
              pw.Text(FormatHelpers.rupiah(data.totalCogs),
                  style: fontTotal.copyWith(color: PdfColors.orange700)),
            ],
          ),
          pw.SizedBox(height: 16),

          // === GROSS PROFIT ===
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue300),
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('LABA KOTOR',
                    style: fontTotal.copyWith(color: PdfColors.blue700)),
                pw.Text(FormatHelpers.rupiah(data.grossProfit),
                    style: fontTotal.copyWith(color: PdfColors.blue700)),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // === EXPENSES ===
          pw.Container(
            color: PdfColors.red50,
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text('PENGELUARAN',
                style: fontHeader.copyWith(color: PdfColors.red800)),
          ),
          pw.SizedBox(height: 4),
          ...data.expenseBreakdown.map((b) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(b.categoryName, style: fontNormal),
                    pw.Row(
                      children: [
                        pw.Text('${b.count}x  ',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey600,
                            )),
                        pw.Text(FormatHelpers.rupiah(b.amount),
                            style: fontNormal),
                      ],
                    ),
                  ],
                ),
              )),
          if (data.expenseBreakdown.isEmpty)
            pw.Text('Belum ada pengeluaran',
                style:
                    pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Pengeluaran', style: fontTotal),
              pw.Text(FormatHelpers.rupiah(data.totalExpense),
                  style: fontTotal.copyWith(color: PdfColors.red700)),
            ],
          ),
          pw.SizedBox(height: 24),

          // === NET PROFIT ===
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            color: data.netProfit >= 0
                ? PdfColors.green50
                : PdfColors.red50,
            child: pw.Column(
              children: [
                pw.Text(
                  'LABA / RUGI BERSIH',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  FormatHelpers.rupiah(data.netProfit),
                  style: fontProfit.copyWith(
                    color: data.netProfit >= 0
                        ? PdfColors.green700
                        : PdfColors.red700,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  color: data.netProfit >= 0
                      ? PdfColors.green700
                      : PdfColors.red700,
                  child: pw.Text(
                    data.netProfit >= 0 ? 'LABA' : 'RUGI',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // === TRANSACTION TABLE ===
          if (data.transactions.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text('Daftar Transaksi',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                )),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.indigo700,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerLeft,
              },
              headers: ['Tanggal', 'Tipe', 'Jumlah', 'HPP', 'Deskripsi'],
              data: data.transactions.map((tx) => [
                    tx.transactionDate,
                    tx.type == 'income' ? 'Masuk' : 'Keluar',
                    FormatHelpers.rupiah(tx.amount),
                    tx.type == 'income'
                        ? FormatHelpers.rupiah(tx.cogs)
                        : '-',
                    tx.description ?? '-',
                  ]).toList(),
            ),
          ],

          // Footer
          pw.SizedBox(height: 32),
          pw.Divider(),
          pw.Text(
            'Dicetak: ${FormatHelpers.displayDate(DateTime.now().toIso8601String().substring(0, 10))}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );

    return pdf.save();
  }
}
