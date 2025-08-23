import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

/// Progressive Loading PDFrx の使用例
/// 
/// この例では、プログレッシブローディング機能を使った
/// 様々なPDF表示パターンを紹介します。

void main() => runApp(ExampleApp());

class ExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Progressive PDFrx Examples',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ExampleList(),
    );
  }
}

class ExampleList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PDFrx Examples')),
      body: ListView(
        children: [
          ListTile(
            title: Text('基本的な使用例'),
            subtitle: Text('プログレッシブローディング有効'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BasicExample()),
            ),
          ),
          ListTile(
            title: Text('単一ページビューア'),
            subtitle: Text('メモリ効率最適化'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SinglePageExample()),
            ),
          ),
          ListTile(
            title: Text('ギャラリービュー'),
            subtitle: Text('複数ページを横スクロール'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GalleryExample()),
            ),
          ),
          ListTile(
            title: Text('サムネイル付きビューア'),
            subtitle: Text('サムネイルナビゲーション'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ThumbnailExample()),
            ),
          ),
        ],
      ),
    );
  }
}

/// 例1: 基本的な使用例
class BasicExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('基本的な使用例')),
      body: PdfDocumentViewBuilder.uri(
        Uri.parse('https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'),
        builder: (context, document) {
          if (document == null) {
            return Center(child: CircularProgressIndicator());
          }
          
          return ListView.builder(
            itemCount: document.pages.length,
            itemBuilder: (context, index) {
              return Container(
                height: 600,
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: PdfPageView(
                  document: document,
                  pageNumber: index + 1,
                  useProgressiveLoading: true,  // プログレッシブローディング
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// 例2: 単一ページビューア（メモリ効率重視）
class SinglePageExample extends StatefulWidget {
  @override
  _SinglePageExampleState createState() => _SinglePageExampleState();
}

class _SinglePageExampleState extends State<SinglePageExample> {
  int currentPage = 1;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('単一ページビューア'),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Page $currentPage'),
            ),
          ),
        ],
      ),
      body: PdfDocumentViewBuilder.uri(
        Uri.parse('https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'),
        builder: (context, document) {
          if (document == null) {
            return Center(child: CircularProgressIndicator());
          }
          
          final totalPages = document.pages.length;
          
          return Column(
            children: [
              Expanded(
                child: PdfPageView(
                  document: document,
                  pageNumber: currentPage,
                  useProgressiveLoading: true,
                  loadOnlyTargetPage: true,  // 現在のページのみロード
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left),
                      onPressed: currentPage > 1
                          ? () => setState(() => currentPage--)
                          : null,
                    ),
                    Text('$currentPage / $totalPages'),
                    IconButton(
                      icon: Icon(Icons.chevron_right),
                      onPressed: currentPage < totalPages
                          ? () => setState(() => currentPage++)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 例3: ギャラリービュー
class GalleryExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ギャラリービュー')),
      body: PdfDocumentViewBuilder.uri(
        Uri.parse('https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'),
        builder: (context, document) {
          if (document == null) {
            return Center(child: CircularProgressIndicator());
          }
          
          return PageView.builder(
            itemCount: document.pages.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 4,
                        child: PdfPageView(
                          document: document,
                          pageNumber: index + 1,
                          useProgressiveLoading: true,
                          loadOnlyTargetPage: true,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Page ${index + 1} of ${document.pages.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// 例4: サムネイル付きビューア
class ThumbnailExample extends StatefulWidget {
  @override
  _ThumbnailExampleState createState() => _ThumbnailExampleState();
}

class _ThumbnailExampleState extends State<ThumbnailExample> {
  int selectedPage = 1;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('サムネイル付きビューア')),
      body: PdfDocumentViewBuilder.uri(
        Uri.parse('https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'),
        builder: (context, document) {
          if (document == null) {
            return Center(child: CircularProgressIndicator());
          }
          
          return Row(
            children: [
              // サムネイルリスト
              Container(
                width: 120,
                color: Colors.grey[200],
                child: ListView.builder(
                  itemCount: document.pages.length,
                  itemBuilder: (context, index) {
                    final pageNum = index + 1;
                    final isSelected = pageNum == selectedPage;
                    
                    return GestureDetector(
                      onTap: () => setState(() => selectedPage = pageNum),
                      child: Container(
                        height: 150,
                        margin: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: PdfPageView(
                                document: document,
                                pageNumber: pageNum,
                                useProgressiveLoading: true,
                                maximumDpi: 72,  // サムネイル用低解像度
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(4),
                              color: isSelected ? Colors.blue : Colors.grey[300],
                              child: Text(
                                '$pageNum',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // メインビュー
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: PdfPageView(
                    document: document,
                    pageNumber: selectedPage,
                    useProgressiveLoading: true,
                    loadOnlyTargetPage: true,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// カスタムローディングインジケーター例
class CustomLoadingExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('カスタムローディング')),
      body: PdfDocumentViewBuilder.uri(
        Uri.parse('https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'),
        builder: (context, document) {
          if (document == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('PDFを読み込んでいます...'),
                ],
              ),
            );
          }
          
          return PdfPageView(
            document: document,
            pageNumber: 1,
            useProgressiveLoading: true,
            decorationBuilder: (context, pageSize, page, pageImage) {
              if (pageImage == null) {
                // カスタムローディング表示
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(height: 8),
                      Text('ページ ${page.pageNumber} を読み込み中...'),
                    ],
                  ),
                );
              }
              
              // 通常の表示
              return Align(
                alignment: Alignment.center,
                child: AspectRatio(
                  aspectRatio: pageSize.width / pageSize.height,
                  child: Container(
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
                    child: pageImage,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}