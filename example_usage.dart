import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('PDFビューアー')),
        body: MyPdfViewer(),
      ),
    );
  }
}

class MyPdfViewer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 方法1: シンプルな全ページ表示
    return PdfViewer.uri(
      Uri.parse('https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'),
      params: PdfViewerParams(
        enableTextSelection: true,
      ),
    );
  }
}

// 方法2: 特定ページのみを効率的に読み込む
class SinglePageViewer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PdfDocumentViewBuilder.uri(
      Uri.parse('https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'),
      useProgressiveLoading: true,
      targetPageNumber: 3,  // 3ページ目のみを読み込む
      builder: (context, document) {
        if (document == null) {
          return Center(child: CircularProgressIndicator());
        }
        
        return PdfPageView(
          document: document,
          pageNumber: 3,
          useProgressiveLoading: true,  // プログレッシブレンダリング
          loadOnlyTargetPage: true,     // このページのみを読み込む
        );
      },
    );
  }
}

// 方法3: プログレッシブレンダリング付きページビュー
class ProgressivePageViewer extends StatefulWidget {
  @override
  _ProgressivePageViewerState createState() => _ProgressivePageViewerState();
}

class _ProgressivePageViewerState extends State<ProgressivePageViewer> {
  int currentPage = 1;
  
  @override
  Widget build(BuildContext context) {
    return PdfDocumentViewBuilder.uri(
      Uri.parse('https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'),
      useProgressiveLoading: true,
      builder: (context, document) {
        if (document == null) {
          return Center(child: CircularProgressIndicator());
        }
        
        return Column(
          children: [
            Expanded(
              child: PdfPageView(
                key: ValueKey('page_$currentPage'),
                document: document,
                pageNumber: currentPage,
                useProgressiveLoading: true,  // 追加した機能
                alignment: Alignment.center,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: currentPage > 1 
                    ? () => setState(() => currentPage--) 
                    : null,
                ),
                Text('ページ $currentPage / ${document.pages.length}'),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: currentPage < document.pages.length 
                    ? () => setState(() => currentPage++) 
                    : null,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}