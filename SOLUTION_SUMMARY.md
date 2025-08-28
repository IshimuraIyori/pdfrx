# 現状と解決策のまとめ

## 現在の制約

pdfrxの現在のAPI設計では、`progressiveLoadingTargetPage`は**ドキュメント作成時のみ**指定可能で、後から変更できません。

これは**pdfrx_engineレベルの制約**であり、簡単には回避できません。

## 実現可能な解決策

### 1. **PdfPageInstant（現在の実装）**
```dart
PdfPageInstant.uri(
  Uri.parse('https://example.com/document.pdf'),
  pageNumber: currentPage,  // 変更時に新しいインスタンス
)
```

**メリット:**
- 指定ページの正しいアスペクト比を取得
- HTTP Range対応
- 実装がシンプル

**デメリット:**
- ページ変更のたびに新しいドキュメントインスタンスを作成（非効率）
- 同じPDFを何度も開き直す

### 2. **ドキュメントを1回開いて全ページロード**
```dart
// 最初に全ページロード（Progressive Loading OFF）
PdfDocument.openUri(
  uri,
  useProgressiveLoading: false,  // 全ページロード
)
```

**メリット:**
- 全ページが正しいアスペクト比で利用可能
- ページ切り替えが高速

**デメリット:**
- 初回ロードが遅い
- 大きなPDFではメモリを大量消費

### 3. **最初のアクセス時にページをキャッシュ**
```dart
class PdfPageCache {
  final Map<int, double> _aspectRatios = {};
  
  // ページアクセス時にそのページだけロード
  Future<double> getPageAspectRatio(int pageNumber) async {
    if (!_aspectRatios.containsKey(pageNumber)) {
      // そのページだけを新しいインスタンスでロード
      final doc = await PdfDocument.openUri(
        uri,
        progressiveLoadingTargetPage: pageNumber,
      );
      _aspectRatios[pageNumber] = doc.pages[pageNumber - 1].aspectRatio;
      doc.dispose();
    }
    return _aspectRatios[pageNumber]!;
  }
}
```

**メリット:**
- 必要なページのみロード
- アスペクト比をキャッシュして再利用

**デメリット:**
- 初回アクセス時は遅い
- 実装が複雑

## 推奨される解決策

**用途に応じて選択:**

### A. 少ないページ数のPDF（〜50ページ）
→ **全ページロード**（Progressive Loading OFF）

### B. 大きなPDF + 特定ページのみ表示
→ **PdfPageInstant**（現在の実装）

### C. 大きなPDF + 頻繁なページ切り替え
→ **キャッシュ実装**（要カスタム開発）

## 根本的な解決

pdfrx_engineに以下の機能が必要：

```dart
// 理想的なAPI（現在は存在しない）
document.loadPage(pageNumber);  // 特定ページのみ動的ロード
page.ensureLoaded();            // そのページだけロード
```

これには**pdfrx_engineの改修**が必要です。

## 現時点での最善策

```dart
// 実用的な実装例
class SmartPdfViewer extends StatefulWidget {
  final String pdfUrl;
  final int maxPages;  // PDFのページ数上限
  
  @override
  State<SmartPdfViewer> createState() => _SmartPdfViewerState();
}

class _SmartPdfViewerState extends State<SmartPdfViewer> {
  PdfDocument? _document;
  bool _useFullLoad = false;
  
  @override
  void initState() {
    super.initState();
    // ページ数が少なければ全ロード、多ければ個別ロード
    _useFullLoad = widget.maxPages <= 50;
    if (_useFullLoad) {
      _loadFullDocument();
    }
  }
  
  Future<void> _loadFullDocument() async {
    _document = await PdfDocument.openUri(
      Uri.parse(widget.pdfUrl),
      useProgressiveLoading: false,  // 全ページロード
    );
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    if (_useFullLoad && _document != null) {
      // 全ページロード済み：高速切り替え
      return PdfPageView(
        document: _document!,
        pageNumber: currentPage,
      );
    } else {
      // 個別ロード：各ページで新インスタンス
      return PdfPageInstant.uri(
        Uri.parse(widget.pdfUrl),
        pageNumber: currentPage,
      );
    }
  }
}
```

## まとめ

現在のpdfrxの制約では、**「アプリ内で選択したページを動的に高速で正しいアスペクト比で表示」**を完全に実現することは困難です。

**実用的な選択肢:**
1. 小さいPDF → 全ページロード
2. 大きいPDF → PdfPageInstant（ページごとに新インスタンス）
3. カスタムキャッシュ層の実装

根本的な解決にはpdfrx_engineレベルの改修が必要です。