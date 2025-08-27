# 他のFlutterアプリでPdfSinglePageを利用する方法

このフォーク版pdfrxの`PdfSinglePage`ウィジェットを他のFlutterアプリで利用する手順です。

## 1. pubspec.yamlの設定

### 方法A: GitHubから直接参照（推奨）

```yaml
dependencies:
  pdfrx:
    git:
      url: https://github.com/[YOUR_USERNAME]/pdfrx.git
      ref: feature/pdf-single-page
      path: packages/pdfrx
```

### 方法B: ローカルパスで参照（開発時）

```yaml
dependencies:
  pdfrx:
    path: /path/to/your/pdfrx/packages/pdfrx
```

### 方法C: pub.devの公式版 + オーバーライド

公式版pdfrxを使いつつ、フォーク版でオーバーライドする：

```yaml
dependencies:
  pdfrx: ^2.1.3  # 公式版

dependency_overrides:
  pdfrx:
    git:
      url: https://github.com/[YOUR_USERNAME]/pdfrx.git
      ref: feature/pdf-single-page
      path: packages/pdfrx
```

## 2. 依存関係のインストール

```bash
flutter pub get
```

## 3. 基本的な使い方

### シンプルな例

```dart
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfSinglePageView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PDF Single Page')),
      body: PdfSinglePage.uri(
        Uri.parse('https://example.com/document.pdf'),
        pageNumber: 5,  // 5ページ目を表示
        useProgressiveLoading: true,
        preferRangeAccess: true,  // HTTP Range対応
      ),
    );
  }
}
```

### ページ切り替え可能な例

```dart
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfPageViewer extends StatefulWidget {
  final String pdfUrl;
  
  const PdfPageViewer({required this.pdfUrl, super.key});
  
  @override
  State<PdfPageViewer> createState() => _PdfPageViewerState();
}

class _PdfPageViewerState extends State<PdfPageViewer> {
  int _currentPage = 1;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page $_currentPage'),
        actions: [
          IconButton(
            icon: Icon(Icons.navigate_before),
            onPressed: _currentPage > 1 
              ? () => setState(() => _currentPage--) 
              : null,
          ),
          IconButton(
            icon: Icon(Icons.navigate_next),
            onPressed: () => setState(() => _currentPage++),
          ),
        ],
      ),
      body: PdfSinglePage.uri(
        Uri.parse(widget.pdfUrl),
        pageNumber: _currentPage,
        useProgressiveLoading: true,
        preferRangeAccess: true,
      ),
    );
  }
}
```

### ローカルファイル/アセットの場合

```dart
// アセットから
PdfSinglePage.asset(
  'assets/documents/manual.pdf',
  pageNumber: 1,
)

// ファイルパスから
PdfSinglePage.file(
  '/path/to/document.pdf',
  pageNumber: 3,
)

// メモリ（Uint8List）から
PdfSinglePage.data(
  pdfBytes,
  pageNumber: 2,
)
```

## 4. カスタマイズオプション

```dart
PdfSinglePage.uri(
  Uri.parse('https://example.com/document.pdf'),
  pageNumber: 5,
  
  // レンダリング品質（DPI）
  maximumDpi: 300,  // デフォルト: 300
  
  // ページの配置
  alignment: Alignment.center,  // デフォルト: center
  
  // 背景色
  backgroundColor: Colors.grey[200],
  
  // 初期表示時の仮アスペクト比（A4縦）
  fallbackAspectRatio: 1 / 1.41421356,
  
  // Progressive Loading（段階的読み込み）
  useProgressiveLoading: true,
  
  // HTTP Range リクエスト（部分ダウンロード）
  preferRangeAccess: true,
  
  // HTTPヘッダー（認証等）
  headers: {
    'Authorization': 'Bearer $token',
  },
  
  // パスワード保護されたPDF
  passwordProvider: () async => 'password123',
)
```

## 5. エラーハンドリング

```dart
class SafePdfSinglePage extends StatelessWidget {
  final String pdfUrl;
  final int pageNumber;
  
  const SafePdfSinglePage({
    required this.pdfUrl,
    required this.pageNumber,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return PdfDocumentViewBuilder(
      documentRef: PdfDocumentRefUri(
        Uri.parse(pdfUrl),
        useProgressiveLoading: true,
        preferRangeAccess: true,
      ),
      builder: (context, document) {
        if (document == null) {
          // ローディング中
          return Center(child: CircularProgressIndicator());
        }
        
        // エラー時の処理
        if (document.pages.isEmpty) {
          return Center(child: Text('PDFを読み込めませんでした'));
        }
        
        // 正常表示
        return PdfSinglePage.documentRef(
          documentRef: PdfDocumentRefDirect(document),
          pageNumber: pageNumber.clamp(1, document.pages.length),
        );
      },
    );
  }
}
```

## 6. パフォーマンスのヒント

### メモリ管理

```dart
class OptimizedPdfViewer extends StatefulWidget {
  @override
  State<OptimizedPdfViewer> createState() => _OptimizedPdfViewerState();
}

class _OptimizedPdfViewerState extends State<OptimizedPdfViewer> {
  PdfDocumentRef? _documentRef;
  
  @override
  void initState() {
    super.initState();
    _documentRef = PdfDocumentRefUri(
      Uri.parse('https://example.com/large.pdf'),
      useProgressiveLoading: true,
      progressiveLoadingTargetPage: 5,  // 5ページ目を優先的に読み込み
      preferRangeAccess: true,
    );
  }
  
  @override
  void dispose() {
    // メモリ解放
    _documentRef?.resolveListenable().dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return PdfSinglePage.documentRef(
      documentRef: _documentRef!,
      pageNumber: 5,
    );
  }
}
```

## 7. トラブルシューティング

### CORSエラー（Web版）

Web版でCORSエラーが発生する場合：

1. サーバー側でCORSヘッダーを設定
2. または、プロキシサーバーを使用

```dart
// プロキシ経由でアクセス
final proxyUrl = 'https://cors-proxy.example.com/';
final pdfUrl = 'https://external-site.com/document.pdf';

PdfSinglePage.uri(
  Uri.parse('$proxyUrl$pdfUrl'),
  pageNumber: 1,
)
```

### Range未対応サーバー

サーバーがHTTP Rangeに対応していない場合、自動的に全体ダウンロードにフォールバックします。

```dart
PdfSinglePage.uri(
  Uri.parse('https://example.com/document.pdf'),
  pageNumber: 5,
  preferRangeAccess: true,  // 対応していれば使用、未対応なら全体DL
)
```

## 8. 完全な実装例

```dart
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Single Page Demo',
      home: PdfViewerScreen(),
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final _pdfUrl = 'https://www.rfc-editor.org/rfc/pdfrfc/rfc6749.txt.pdf';
  int _currentPage = 1;
  int? _totalPages;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Viewer'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // PDFビュー
          Expanded(
            child: PdfDocumentViewBuilder.uri(
              Uri.parse(_pdfUrl),
              builder: (context, document) {
                if (document == null) {
                  return Center(child: CircularProgressIndicator());
                }
                
                // 総ページ数を保存
                if (_totalPages == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() => _totalPages = document.pages.length);
                  });
                }
                
                return PdfSinglePage.documentRef(
                  documentRef: PdfDocumentRefDirect(document),
                  pageNumber: _currentPage,
                  maximumDpi: 200,
                  backgroundColor: Colors.grey[100],
                );
              },
            ),
          ),
          
          // ページナビゲーション
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.first_page),
                  onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage = 1)
                    : null,
                ),
                IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$_currentPage / ${_totalPages ?? '?'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right),
                  onPressed: (_totalPages != null && _currentPage < _totalPages!)
                    ? () => setState(() => _currentPage++)
                    : null,
                ),
                IconButton(
                  icon: Icon(Icons.last_page),
                  onPressed: (_totalPages != null && _currentPage < _totalPages!)
                    ? () => setState(() => _currentPage = _totalPages!)
                    : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## 注意事項

- フォーク版のため、公式版pdfrxのアップデートに追従する必要があります
- プロダクション利用の場合は、十分なテストを行ってください
- HTTP Rangeは、サーバー側の対応が必要です（206 Partial Content）

## サポート

問題が発生した場合は、GitHubのIssuesでお知らせください。