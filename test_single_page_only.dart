import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '単一ページ読み込みテスト',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SinglePageOnlyDemo(),
    );
  }
}

class SinglePageOnlyDemo extends StatefulWidget {
  @override
  State<SinglePageOnlyDemo> createState() => _SinglePageOnlyDemoState();
}

class _SinglePageOnlyDemoState extends State<SinglePageOnlyDemo> {
  int targetPageNumber = 5; // 5ページ目のみを読み込み

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('単一ページ読み込み (ページ $targetPageNumber のみ)'),
      ),
      body: Column(
        children: [
          // 説明パネル
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Text(
              '大きなPDFファイルから特定の1ページ（ページ $targetPageNumber）のみを効率的に読み込みます。\n'
              'useProgressiveLoading と loadOnlyTargetPage を組み合わせることで、\n'
              '必要なページだけを読み込み、メモリ使用量を最小限に抑えます。',
              style: TextStyle(fontSize: 14),
            ),
          ),
          
          // PDFページ表示
          Expanded(
            child: PdfDocumentViewBuilder.uri(
              Uri.parse('https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'),
              useProgressiveLoading: true,
              targetPageNumber: targetPageNumber,
              builder: (context, document) {
                if (document == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('PDFを読み込み中...'),
                      ],
                    ),
                  );
                }
                
                // ドキュメントが読み込まれたら、指定ページのみを表示
                if (targetPageNumber > document.pages.length) {
                  return Center(
                    child: Text(
                      'エラー: ページ $targetPageNumber は存在しません。\n'
                      'このPDFは ${document.pages.length} ページです。',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                
                return Container(
                  margin: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ページ情報
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'ページ $targetPageNumber / ${document.pages.length} を表示中',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // PDFページ
                      Expanded(
                        child: PdfPageView(
                          document: document,
                          pageNumber: targetPageNumber,
                          useProgressiveLoading: true,
                          loadOnlyTargetPage: true,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // コントロールパネル
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('表示ページ: '),
                SizedBox(width: 8),
                DropdownButton<int>(
                  value: targetPageNumber,
                  items: List.generate(10, (index) => index + 1)
                      .map((page) => DropdownMenuItem(
                            value: page,
                            child: Text('ページ $page'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        targetPageNumber = value;
                      });
                    }
                  },
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // 再読み込み
                    });
                  },
                  child: Text('再読み込み'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}