# 完全遅延ロード（Fully Lazy Loading）の使い方

## 概要

**完全遅延ロード**により、PDFドキュメントを開く際に**一切のページサイズを取得しません**。
各ページのサイズは、そのページが実際にアクセスされた時に初めて取得されます。

## 比較

| 方式 | 初期化時の動作 | メモリ使用 | アスペクト比 |
|------|--------------|-----------|------------|
| **通常ロード** | 全ページをロード | 最大 | ✅ 正確 |
| **プログレッシブ** | 全ページサイズ取得、内容は1ページのみ | 中 | ✅ 正確 |
| **完全遅延（新）** | ページ数のみ取得 | 最小 | ✅ 正確（動的取得） |

## 使用方法

### 1. インポート

```dart
import 'package:pdfrx_engine/pdfrx_engine.dart';
```

### 2. 完全遅延ロードでPDFを開く

```dart
// URLから開く
final document = await PdfDocumentLazyLoading.openUriLazy(
  Uri.parse('https://example.com/large-document.pdf'),
  preferRangeAccess: true,
);

// バイトデータから開く
final document2 = await PdfDocumentLazyLoading.openDataLazy(
  pdfBytes,
  sourceName: 'my-document.pdf',
);
```

### 3. ページにアクセス

```dart
// ページ数は即座に取得可能
print('Total pages: ${document.pages.length}');

// 特定のページを動的にロード
await document.loadPageDynamically(42);

// ページのサイズを取得（自動的にロードされる）
final page42 = document.pages[41];
print('Page 42 size: ${page42.width} x ${page42.height}');
```

## 実装例

### 基本的な使用例

```dart
import 'package:flutter/material.dart';
import 'package:pdfrx_engine/pdfrx_engine.dart';
import 'package:pdfrx/pdfrx.dart';

class FullyLazyPdfViewer extends StatefulWidget {
  final String pdfUrl;
  
  const FullyLazyPdfViewer({super.key, required this.pdfUrl});
  
  @override
  State<FullyLazyPdfViewer> createState() => _FullyLazyPdfViewerState();
}

class _FullyLazyPdfViewerState extends State<FullyLazyPdfViewer> {
  PdfDocument? document;
  int currentPage = 1;
  double? currentAspectRatio;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initDocument();
  }
  
  Future<void> _initDocument() async {
    try {
      // 完全遅延ロードでドキュメントを開く
      document = await PdfDocumentLazyLoading.openUriLazy(
        Uri.parse(widget.pdfUrl),
        preferRangeAccess: true,
      );
      
      // 最初のページのみロード
      await _loadPage(1);
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading PDF: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
  
  Future<void> _loadPage(int pageNumber) async {
    if (document == null) return;
    
    // ページを動的にロード
    final success = await document!.loadPageDynamically(pageNumber);
    if (!success) return;
    
    // アスペクト比を取得
    final page = document!.pages[pageNumber - 1];
    final aspectRatio = page.width / page.height;
    
    setState(() {
      currentPage = pageNumber;
      currentAspectRatio = aspectRatio;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (document == null || currentAspectRatio == null) {
      return const Center(child: Text('Failed to load PDF'));
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Page $currentPage / ${document!.pages.length}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: currentAspectRatio!,
              child: PdfPageView(
                document: document!,
                pageNumber: currentPage,
              ),
            ),
          ),
          _buildPageSelector(),
        ],
      ),
    );
  }
  
  Widget _buildPageSelector() {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: () => _loadPage(1),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 1
              ? () => _loadPage(currentPage - 1)
              : null,
          ),
          Text('$currentPage / ${document!.pages.length}'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < document!.pages.length
              ? () => _loadPage(currentPage + 1)
              : null,
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed: () => _loadPage(document!.pages.length),
          ),
        ],
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

### パフォーマンス最適化版

```dart
class OptimizedLazyPdfViewer extends StatefulWidget {
  final String pdfUrl;
  
  const OptimizedLazyPdfViewer({super.key, required this.pdfUrl});
  
  @override
  State<OptimizedLazyPdfViewer> createState() => _OptimizedLazyPdfViewerState();
}

class _OptimizedLazyPdfViewerState extends State<OptimizedLazyPdfViewer> {
  PdfDocument? document;
  int currentPage = 1;
  
  // アスペクト比のキャッシュ
  final Map<int, double> aspectRatioCache = {};
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    document = await PdfDocumentLazyLoading.openUriLazy(
      Uri.parse(widget.pdfUrl),
    );
    
    // 最初のページと隣接ページをプリロード
    await _preloadPages([1, 2]);
    
    setState(() {});
  }
  
  Future<void> _preloadPages(List<int> pageNumbers) async {
    if (document == null) return;
    
    // 複数ページを並行してロード
    final results = await document!.loadPagesDynamically(pageNumbers);
    
    // アスペクト比をキャッシュ
    for (final pageNum in pageNumbers) {
      if (results[pageNum] == true) {
        final page = document!.pages[pageNum - 1];
        aspectRatioCache[pageNum] = page.width / page.height;
      }
    }
  }
  
  Future<void> _goToPage(int pageNumber) async {
    if (document == null) return;
    
    // 現在のページをロード（キャッシュがなければ）
    if (!aspectRatioCache.containsKey(pageNumber)) {
      await document!.loadPageDynamically(pageNumber);
      final page = document!.pages[pageNumber - 1];
      aspectRatioCache[pageNumber] = page.width / page.height;
    }
    
    // 隣接ページを先読み
    final adjacentPages = <int>[];
    if (pageNumber > 1) adjacentPages.add(pageNumber - 1);
    if (pageNumber < document!.pages.length) adjacentPages.add(pageNumber + 1);
    
    // バックグラウンドでプリロード
    _preloadPages(adjacentPages);
    
    setState(() {
      currentPage = pageNumber;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // ... UI実装
  }
}
```

## メリット

1. **超高速初期化**: ページサイズの取得を完全にスキップ
2. **最小メモリ使用**: アクセスしたページのみメモリに保持
3. **大規模PDF対応**: 1000ページ以上のPDFでも瞬時に開く
4. **ネットワーク効率**: HTTP Rangeで必要な部分のみダウンロード

## 注意点

1. **初回アクセス時の遅延**: 各ページの初回表示時にサイズ取得が発生
2. **デフォルトサイズ**: ロード前はA4サイズ（595x842）を仮定
3. **同期APIの制限**: `page.width`などの同期プロパティは非理想的な実装

## プログレッシブロードとの違い

```dart
// プログレッシブロード（従来）
final doc1 = await PdfDocument.openUri(
  uri,
  useProgressiveLoading: true,  // 全ページサイズを初期化時に取得
);

// 完全遅延ロード（新機能）
final doc2 = await PdfDocumentLazyLoading.openUriLazy(
  uri,  // ページサイズは一切取得しない
);
```

## まとめ

完全遅延ロードは、特に以下のケースで有効です：

- 巨大なPDF（数百～数千ページ）
- ネットワーク経由のPDF
- 特定のページのみ表示する場合
- 初期表示速度が最優先の場合

通常の用途では従来のプログレッシブローディングでも十分ですが、
より高度な最適化が必要な場合は完全遅延ロードを使用してください。