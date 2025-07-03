import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pdfrx/pdfrx.dart';

import 'setup.dart';
import 'utils.dart';

final testPdfFile = File('example/viewer/assets/hello.pdf');
String? iso32000PdfFileName;
String? xfaPdfFileName;
void main() {
  setUp(() async {
    iso32000PdfFileName = await downloadFile(
      'https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf',
    );
    await setup();
  });

  test('PdfDocument.openFile', () async => await testDocument(await PdfDocument.openFile(testPdfFile.path)));
  test('PdfDocument.openData', () async {
    final data = await testPdfFile.readAsBytes();
    await testDocument(await PdfDocument.openData(data));
  });
  test('PdfDocument.openUri', () async {
    Pdfrx.createHttpClient =
        () => MockClient((request) async => http.Response.bytes(await testPdfFile.readAsBytes(), 200));
    await testDocument(await PdfDocument.openUri(Uri.parse('https://example.com/hello.pdf')));
  });

  test('PdfDocument.openFile with xfa.pdf', () async {
    await testDocument(await PdfDocument.openFile('test/.tmp/data/xfa.pdf'));
  });
}
