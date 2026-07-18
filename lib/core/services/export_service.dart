import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportException implements Exception {
  final String message;
  const ExportException(this.message);

  @override
  String toString() => message;
}

class ExportService {
  static final ExportService instance = ExportService._();
  ExportService._();

  Future<File> toCsv({
    required List<String> headers,
    required List<List<String>> rows,
    required String filename,
  }) async {
    final buf = StringBuffer();
    buf.writeln(headers.map(_csvCell).join(','));
    for (final row in rows) {
      buf.writeln(row.map(_csvCell).join(','));
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename.csv');
    await file.writeAsString(buf.toString());
    return file;
  }

  Future<File> toExcel({
    required List<String> headers,
    required List<List<dynamic>> rows,
    required String filename,
    String sheetName = 'Sheet1',
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel[sheetName];

    // Header row
    for (var c = 0; c < headers.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.white,
        backgroundColorHex: ExcelColor.indigo900,
      );
    }

    // Data rows
    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < rows[r].length; c++) {
        final val = rows[r][c];
        final cell = sheet.cell(CellIndex.indexByColumnRow(
          columnIndex: c,
          rowIndex: r + 1,
        ));

        if (val is String) {
          final numVal = num.tryParse(val);
          if (numVal != null) {
            cell.value = numVal is int
                ? IntCellValue(numVal)
                : DoubleCellValue(numVal.toDouble());
          } else {
            cell.value = TextCellValue(val);
          }
        } else if (val is int) {
          cell.value = IntCellValue(val);
        } else if (val is double) {
          cell.value = DoubleCellValue(val);
        } else {
          cell.value = TextCellValue(val.toString());
        }
      }
    }

    // Auto-fit column width
    for (var c = 0; c < headers.length; c++) {
      int maxLen = headers[c].length;
      for (var r = 0; r < rows.length; r++) {
        if (c < rows[r].length) {
          final len = rows[r][c].toString().length;
          if (len > maxLen) maxLen = len;
        }
      }
      sheet.setColumnWidth(c, (maxLen + 3).clamp(8, 50).toDouble());
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename.xlsx');
    final bytes = excel.encode();
    if (bytes == null) throw ExportException('Gagal menyimpan file Excel');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> shareFile(File file, {String? text}) async {
    if (!await file.exists()) {
      throw ExportException('File tidak ditemukan');
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: text ?? 'Export - Sheress',
      ),
    );
  }

  String _csvCell(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
