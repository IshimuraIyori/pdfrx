import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Aspect Ratio Test',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Test Progressive Loading with Different Aspect Ratios'),
        ),
        body: PdfViewer.uri(
          Uri.parse('https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'),
          params: PdfViewerParams(
            useProgressiveLoading: true,
            enableTextSelection: true,
          ),
        ),
      ),
    );
  }
}