import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';

/// The release of pdfium to download.
const pdfiumRelease = 'chromium%2F7202';

/// Temporary directory for testing.
final tmpRoot = Directory('${Directory.current.path}/test/.tmp');

/// Test document with all pages.flutte
Future<void> testDocument(PdfDocument doc) async {
  await testNamedDest(doc);
  //await testXfaPackets(doc);

  expect(doc.pages.length, greaterThan(0), reason: 'doc.pages.length');
  for (var i = 1; i <= doc.pages.length; i++) {
    await testPage(doc, i);
  }
  doc.dispose();
}

/// Test named destinations in the document.
Future<void> testNamedDest(PdfDocument doc) async {
  final namedDests = await doc.getNamedDests();
  for (final entry in namedDests.entries) {
    expect(entry.key, isNotEmpty, reason: 'Named destination name should not be empty');
    expect(entry.value.pageNumber, greaterThan(0), reason: 'Named destination page number should be greater than 0');
    final dest = await doc.getNamedDestByName(entry.key);
    expect(dest, isNotNull, reason: 'doc.getNamedDestByName(${entry.key})');
  }
}

Future<void> testXfaPackets(PdfDocument doc) async {
  final xfaPackets = await doc.getXfaPackets();
  for (final packet in xfaPackets) {
    expect(packet.name, isNotEmpty, reason: 'XFA packet name should not be empty');
    final content = await packet.getContent();
    expect(content, isNotEmpty, reason: 'XFA packet content should not be empty');
  }
}

/// Test a page.
Future<void> testPage(PdfDocument doc, int pageNumber) async {
  final page = doc.pages[pageNumber - 1];
  expect(page.pageNumber, pageNumber, reason: 'page.pageNumber ($pageNumber)');
  expect(page.width, greaterThan(0.0), reason: 'Positive page.width');
  expect(page.height, greaterThan(0.0), reason: 'Positive page.height');
  final pageImage = await page.render();
  expect(pageImage, isNotNull);
  expect(pageImage!.width, page.width.toInt(), reason: 'pageImage.width');
  expect(pageImage.height, page.height.toInt(), reason: 'pageImage.height');
  final image = await pageImage.createImage();
  expect(image.width, page.width.toInt(), reason: 'image.width');
  expect(image.height, page.height.toInt(), reason: 'image.height');
  image.dispose();
  pageImage.dispose();
}
