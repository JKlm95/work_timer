import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Raport PDF (A4 poziom) z tabelą stringów — pierwszy wiersz = nagłówki.
///
/// Tekst UTF-8 (np. PL): wymaga osadzenia [assetFontPath] (Noto Sans w assets).
Future<Uint8List> buildWorkEntriesPdfDocument({
  required List<List<String>> rowsWithHeader,
  required String title,
  required String subtitle,
  required String assetFontPath,
}) async {
  if (rowsWithHeader.isEmpty) {
    throw ArgumentError('rowsWithHeader must include a header row');
  }

  final fontData = await rootBundle.load(assetFontPath);
  final font = pw.Font.ttf(fontData);

  final header = rowsWithHeader.first;
  final colCount = header.length;
  final body = rowsWithHeader.skip(1).map((r) {
    final copy = List<String>.from(r);
    while (copy.length < colCount) {
      copy.add('');
    }
    if (copy.length > colCount) {
      return copy.take(colCount).toList();
    }
    return copy;
  }).toList();

  final alignments = <int, pw.Alignment>{
    for (var i = 0; i < header.length; i++) i: pw.Alignment.centerLeft,
  };

  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: font, bold: font),
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Text(subtitle, style: pw.TextStyle(fontSize: 9)),
        pw.SizedBox(height: 14),
        pw.TableHelper.fromTextArray(
          headers: header,
          data: body,
          headerAlignments: alignments,
          cellAlignments: alignments,
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 8,
          ),
          cellStyle: const pw.TextStyle(fontSize: 7),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
        ),
      ],
    ),
  );

  return doc.save();
}
