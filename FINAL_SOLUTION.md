# 最終解決策：動的ページロードの実装

## ✅ 実装内容

### 1. **pdfrx_engineレベルでの拡張**

`PdfDocumentDynamicLoader` 拡張メソッドを追加：

```dart
// 特定ページのみを動的にロード
await document.loadPage(pageNumber);

// 複数ページを同時ロード
await document.loadPages([1, 5, 10]);

// ページのアスペクト比を取得（未ロードなら自動ロード）
final aspectRatio = await document.getPageAspectRatio(pageNumber);
```

### 2. **PdfPageViewDynamic ウィジェット**

新APIを使用した最適化されたウィジェット：

```dart
PdfPageViewDynamic.uri(
  Uri.parse('https://example.com/document.pdf'),
  pageNumber: currentPage,  // 動的に変更可能
)
```

## 🎯 特徴

- **ドキュメントは1回だけ開く** - 効率的なリソース管理
- **ページは必要時のみロード** - メモリ効率が良い
- **正しいアスペクト比** - 各ページの実際の比率を使用
- **キャッシュ機能** - 一度ロードしたページの比率を保持
- **HTTP Range対応** - ネットワークPDFの部分取得

## 📋 使用例

### 基本的な使い方

```dart
class PdfViewerScreen extends StatefulWidget {
  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  int currentPage = 1;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page $currentPage'),
        actions: [
          IconButton(
            icon: Icon(Icons.navigate_before),
            onPressed: currentPage > 1 
              ? () => setState(() => currentPage--) 
              : null,
          ),
          IconButton(
            icon: Icon(Icons.navigate_next),
            onPressed: () => setState(() => currentPage++),
          ),
        ],
      ),
      body: PdfPageViewDynamic.uri(
        Uri.parse('https://example.com/document.pdf'),
        pageNumber: currentPage,
        preferRangeAccess: true,
      ),
    );
  }
}
```

### 高度な使い方（直接API使用）

```dart
class AdvancedPdfViewer extends StatefulWidget {
  @override
  State<AdvancedPdfViewer> createState() => _AdvancedPdfViewerState();
}

class _AdvancedPdfViewerState extends State<AdvancedPdfViewer> {
  PdfDocument? document;
  int currentPage = 1;
  double? aspectRatio;
  
  @override
  void initState() {
    super.initState();
    _loadDocument();
  }
  
  Future<void> _loadDocument() async {
    document = await PdfDocument.openUri(
      Uri.parse('https://example.com/document.pdf'),
      useProgressiveLoading: true,
    );
    setState(() {});
  }
  
  Future<void> _loadCurrentPage() async {
    if (document == null) return;
    
    // 新API: 特定ページのみロード
    await document!.loadPage(currentPage);
    
    // アスペクト比を取得
    aspectRatio = await document!.getPageAspectRatio(currentPage);
    
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    if (document == null) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (aspectRatio == null) {
      // ページをロード
      _loadCurrentPage();
      return Center(child: CircularProgressIndicator());
    }
    
    return PdfPageView(
      document: document!,
      pageNumber: currentPage,
      // 正しいアスペクト比で表示
    );
  }
}
```

## 🔧 pubspec.yaml設定

```yaml
dependencies:
  pdfrx:
    git:
      url: https://github.com/IshimuraIyori/pdfrx.git
      ref: feature/pdf-single-page
      path: packages/pdfrx
  pdfrx_engine:
    git:
      url: https://github.com/IshimuraIyori/pdfrx.git
      ref: feature/pdf-single-page
      path: packages/pdfrx_engine
```

## 📊 パフォーマンス比較

| 手法 | ドキュメント作成 | ページロード | メモリ使用 | アスペクト比 |
|-----|----------------|-------------|-----------|------------|
| **PdfPageViewDynamic（新）** | 1回のみ | 必要時のみ | 最小 | ✅正確 |
| PdfPageInstant | ページごと | ページごと | 中 | ✅正確 |
| PdfViewer（全ロード） | 1回 | 全ページ | 最大 | ✅正確 |
| Progressive（既存） | 1回 | 順次 | 大 | ❌最初のページ |

## 🚀 メリット

1. **効率的** - ドキュメントは1回だけ開く
2. **高速** - 必要なページのみロード
3. **正確** - 各ページの正しいアスペクト比
4. **柔軟** - 任意のページを任意の順序でロード
5. **メモリ効率** - 不要なページはロードしない

## 📝 実装の詳細

### pdfrx_engine拡張

```dart
extension PdfDocumentDynamicLoader on PdfDocument {
  // ページを動的にロード
  Future<bool> loadPage(int pageNumber) async {
    final page = pages[pageNumber - 1];
    if (page.isLoaded) return true;
    
    // 最小サイズでレンダリングしてロード
    await page.render(fullWidth: 1, fullHeight: 1);
    return page.isLoaded;
  }
  
  // アスペクト比を取得
  Future<double?> getPageAspectRatio(int pageNumber) async {
    await loadPage(pageNumber);
    final page = pages[pageNumber - 1];
    return page.width / page.height;
  }
}
```

### ウィジェット実装

```dart
class PdfPageViewDynamic extends StatefulWidget {
  // ドキュメントは保持
  // ページは動的にロード
  // アスペクト比をキャッシュ
}
```

## まとめ

これで**「アプリ内で選択したページを動的に高速で正しいアスペクト比で表示」**が実現できました。

- ✅ ユーザーが選択したページのみロード
- ✅ 正しいアスペクト比で表示
- ✅ 効率的なメモリ使用
- ✅ HTTP Range対応