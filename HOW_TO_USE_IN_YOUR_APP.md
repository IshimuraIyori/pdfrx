# 他のFlutterアプリで動的ページロード機能を使用する方法

## 1. pubspec.yaml の設定

あなたのFlutterアプリの `pubspec.yaml` に以下を追加してください：

```yaml
dependencies:
  pdfrx:
    git:
      url: https://github.com/IshimuraIyori/pdfrx.git
      ref: new-feature-branch  # 現在のブランチ
      path: packages/pdfrx
  pdfrx_engine:
    git:
      url: https://github.com/IshimuraIyori/pdfrx.git
      ref: new-feature-branch  # 現在のブランチ
      path: packages/pdfrx_engine
```

## 2. 基本的な使用例

### シンプルな単一ページ表示

```dart
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class SinglePagePdfViewer extends StatefulWidget {
  final String pdfUrl;
  
  const SinglePagePdfViewer({super.key, required this.pdfUrl});
  
  @override
  State<SinglePagePdfViewer> createState() => _SinglePagePdfViewerState();
}

class _SinglePagePdfViewerState extends State<SinglePagePdfViewer> {
  PdfDocument? document;
  int currentPage = 1;
  double? aspectRatio;
  
  @override
  void initState() {
    super.initState();
    _loadPdf();
  }
  
  Future<void> _loadPdf() async {
    // PDFドキュメントを開く（Progressive Loading有効）
    document = await PdfDocument.openUri(
      Uri.parse(widget.pdfUrl),
      useProgressiveLoading: true,
    );
    
    // 最初のページを動的にロード
    await document!.loadPageDynamically(1);
    
    // アスペクト比を取得
    final page = document!.pages[0];
    aspectRatio = page.width / page.height;
    
    setState(() {});
  }
  
  Future<void> _changePage(int pageNumber) async {
    if (document == null) return;
    if (pageNumber < 1 || pageNumber > document!.pages.length) return;
    
    // 新しいページを動的にロード
    await document!.loadPageDynamically(pageNumber);
    
    // アスペクト比を更新
    final page = document!.pages[pageNumber - 1];
    aspectRatio = page.width / page.height;
    
    setState(() {
      currentPage = pageNumber;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (document == null || aspectRatio == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: aspectRatio!,
            child: PdfPageView(
              document: document!,
              pageNumber: currentPage,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: currentPage > 1 
                ? () => _changePage(currentPage - 1) 
                : null,
            ),
            Text('$currentPage / ${document!.pages.length}'),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: currentPage < document!.pages.length
                ? () => _changePage(currentPage + 1)
                : null,
            ),
          ],
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    document?.dispose();
    super.dispose();
  }
}
```

## 3. 拡張メソッドを使用した例

```dart
import 'package:pdfrx_engine/pdfrx_engine.dart';

class OptimizedPdfViewer extends StatefulWidget {
  final String pdfUrl;
  
  const OptimizedPdfViewer({super.key, required this.pdfUrl});
  
  @override
  State<OptimizedPdfViewer> createState() => _OptimizedPdfViewerState();
}

class _OptimizedPdfViewerState extends State<OptimizedPdfViewer> {
  PdfDocument? document;
  int currentPage = 1;
  Map<int, double> aspectRatioCache = {};
  
  @override
  void initState() {
    super.initState();
    _initializePdf();
  }
  
  Future<void> _initializePdf() async {
    document = await PdfDocument.openUri(
      Uri.parse(widget.pdfUrl),
      useProgressiveLoading: true,
      preferRangeAccess: true,  // HTTP Range リクエストを使用
    );
    
    // 拡張メソッドを使用してアスペクト比を取得
    final ratio = await document!.getPageAspectRatio(currentPage);
    if (ratio != null) {
      aspectRatioCache[currentPage] = ratio;
    }
    
    setState(() {});
  }
  
  Future<void> _goToPage(int pageNumber) async {
    if (document == null) return;
    
    // キャッシュを確認
    if (!aspectRatioCache.containsKey(pageNumber)) {
      // 拡張メソッドでページをロード＆アスペクト比取得
      final ratio = await document!.getPageAspectRatio(pageNumber);
      if (ratio != null) {
        aspectRatioCache[pageNumber] = ratio;
      }
    }
    
    setState(() {
      currentPage = pageNumber;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (document == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final aspectRatio = aspectRatioCache[currentPage] ?? 1.4142;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Viewer - Page $currentPage'),
      ),
      body: AspectRatio(
        aspectRatio: aspectRatio,
        child: PdfPageView(
          document: document!,
          pageNumber: currentPage,
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => _goToPage(1),
              child: const Text('First'),
            ),
            ElevatedButton(
              onPressed: currentPage > 1 
                ? () => _goToPage(currentPage - 1)
                : null,
              child: const Text('Previous'),
            ),
            ElevatedButton(
              onPressed: currentPage < document!.pages.length
                ? () => _goToPage(currentPage + 1)
                : null,
              child: const Text('Next'),
            ),
            ElevatedButton(
              onPressed: () => _goToPage(document!.pages.length),
              child: const Text('Last'),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    document?.dispose();
    super.dispose();
  }
}
```

## 4. PdfPageViewDynamic ウィジェットを使用（最も簡単）

```dart
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class SimplestPdfViewer extends StatefulWidget {
  final String pdfUrl;
  
  const SimplestPdfViewer({super.key, required this.pdfUrl});
  
  @override
  State<SimplestPdfViewer> createState() => _SimplestPdfViewerState();
}

class _SimplestPdfViewerState extends State<SimplestPdfViewer> {
  int currentPage = 1;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simple PDF Viewer - Page $currentPage'),
      ),
      body: Column(
        children: [
          Expanded(
            // PdfPageViewDynamic が全ての複雑さを内部で処理
            child: PdfPageViewDynamic.uri(
              Uri.parse(widget.pdfUrl),
              pageNumber: currentPage,
              preferRangeAccess: true,
            ),
          ),
          // ページ選択UI
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 10,  // または document.pages.length
              itemBuilder: (context, index) {
                final pageNum = index + 1;
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        currentPage = pageNum;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentPage == pageNum 
                        ? Theme.of(context).primaryColor 
                        : null,
                    ),
                    child: Text('$pageNum'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

## 5. メインアプリでの使用

```dart
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Viewer App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SimplestPdfViewer(
        pdfUrl: 'https://www.example.com/sample.pdf',
      ),
    );
  }
}
```

## 重要なポイント

### 1. 動的ロードのメリット
- **メモリ効率**: 表示中のページのみロード
- **高速切り替え**: 任意のページへ直接ジャンプ可能
- **正確な表示**: 各ページの正しいアスペクト比

### 2. APIの選択
- **簡単**: `PdfPageViewDynamic` ウィジェット
- **制御**: `document.loadPageDynamically()` 直接使用
- **便利**: 拡張メソッド `getPageAspectRatio()`

### 3. パフォーマンス最適化
```dart
// アスペクト比をキャッシュ
Map<int, double> aspectRatioCache = {};

// 隣接ページを事前ロード（オプション）
await document.loadPagesDynamically([
  currentPage - 1,
  currentPage,
  currentPage + 1,
]);
```

### 4. エラーハンドリング
```dart
try {
  final success = await document.loadPageDynamically(pageNumber);
  if (!success) {
    // ページロード失敗の処理
    print('Failed to load page $pageNumber');
  }
} catch (e) {
  // エラー処理
  print('Error loading page: $e');
}
```

## トラブルシューティング

### 問題: ページが表示されない
```dart
// ページが実際にロードされているか確認
final page = document.pages[pageNumber - 1];
if (!page.isLoaded) {
  await document.loadPageDynamically(pageNumber);
}
```

### 問題: アスペクト比が正しくない
```dart
// 強制的にページを再ロード
await document.loadPage(pageNumber);  // 拡張メソッド
final ratio = await document.getPageAspectRatio(pageNumber);
```

## まとめ

この実装により、PDFの任意のページを効率的に表示できるようになりました。特に大きなPDFファイルや、ネットワーク経由でPDFを読み込む場合に有効です。