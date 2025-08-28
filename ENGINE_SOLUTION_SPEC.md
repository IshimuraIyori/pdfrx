# pdfrx_engine 根本解決の仕様書

## 🎯 目標

pdfrx_engineレベルで、任意のページを動的に独立してロードできるようにする。

## 📋 現在の問題

### 1. Progressive Loading の制約
```dart
// 現在：初期化時のみ指定可能
PdfDocument.openUri(
  uri,
  progressiveLoadingTargetPage: 5,  // 固定
)
```

### 2. ページロードの仕組み
- `_loadPagesInLimitedTime`メソッドが全ページのサイズを最初に取得
- `progressiveLoadingTargetPage`指定時も全ページサイズをロード
- ページは順番にロードされる前提

## 🔧 必要な修正

### 1. PdfDocument インターフェースの拡張

```dart
abstract class PdfDocument {
  // 新メソッド追加
  Future<bool> loadPageDynamically(int pageNumber);
  Future<Map<int, bool>> loadPagesDynamically(List<int> pageNumbers);
  Future<double?> getPageAspectRatioDynamically(int pageNumber);
}
```

### 2. _PdfDocumentPdfium の修正

#### 現在の実装
```dart
// 初期化時に全ページサイズを取得
final pages = await _loadPagesInLimitedTime(
  maxPageCountToLoadAdditionally: useProgressiveLoading ? 1 : null,
  targetPageNumber: progressiveLoadingTargetPage,
);
```

#### 新しい実装
```dart
class _PdfDocumentPdfium {
  // ページの遅延ロード状態を管理
  final Map<int, _PdfPagePdfium> _lazyLoadedPages = {};
  
  // 個別ページロード
  Future<bool> loadPageDynamically(int pageNumber) async {
    if (_lazyLoadedPages.containsKey(pageNumber)) {
      return true; // Already loaded
    }
    
    final pageData = await _loadSinglePage(pageNumber);
    if (pageData != null) {
      _lazyLoadedPages[pageNumber] = pageData;
      _updatePagesList();
      return true;
    }
    return false;
  }
  
  // 単一ページのロード
  Future<_PdfPagePdfium?> _loadSinglePage(int pageNumber) async {
    return await backgroundWorker.compute((params) {
      final doc = FPDF_DOCUMENT.fromAddress(params.docAddress);
      final page = pdfium.FPDF_LoadPage(doc, params.pageIndex);
      try {
        return (
          width: pdfium.FPDF_GetPageWidthF(page),
          height: pdfium.FPDF_GetPageHeightF(page),
          rotation: pdfium.FPDFPage_GetRotation(page),
        );
      } finally {
        pdfium.FPDF_ClosePage(page);
      }
    }, (docAddress: document.address, pageIndex: pageNumber - 1));
  }
}
```

### 3. ページクラスの修正

```dart
class _PdfPagePdfium extends PdfPage {
  // 遅延ロード状態
  bool _dimensionsLoaded = false;
  double? _actualWidth;
  double? _actualHeight;
  
  @override
  double get width => _actualWidth ?? estimatedWidth;
  
  @override
  double get height => _actualHeight ?? estimatedHeight;
  
  @override
  bool get isLoaded => _dimensionsLoaded;
  
  // 実際の寸法を設定
  void updateDimensions(double width, double height) {
    _actualWidth = width;
    _actualHeight = height;
    _dimensionsLoaded = true;
  }
}
```

### 4. Web実装の対応

```dart
class PdfDocumentWeb extends PdfDocument {
  // 同様の動的ロード実装
  Future<bool> loadPageDynamically(int pageNumber) async {
    // PDFium WASM APIを使用して個別ページロード
    final page = await _wasmLoadPage(pageNumber);
    // ...
  }
}
```

## 📊 実装の影響

### メリット
- ✅ 任意のページを任意の順序でロード可能
- ✅ 各ページの正しいアスペクト比を独立して取得
- ✅ メモリ効率の向上（必要なページのみロード）
- ✅ HTTP Rangeとの相性が良い

### デメリット
- ⚠️ 既存APIとの互換性を保つ必要がある
- ⚠️ ネイティブとWebの両実装が必要

## 🚀 実装手順

### Phase 1: インターフェース定義
1. PdfDocument抽象クラスに新メソッド追加
2. 既存メソッドとの共存を確認

### Phase 2: ネイティブ実装
1. _PdfDocumentPdfiumに動的ロード実装
2. PDFium APIの直接呼び出し
3. ページ状態管理の改善

### Phase 3: Web実装
1. PdfDocumentWebに同様の実装
2. WASM APIの活用

### Phase 4: テスト
1. 単体テスト追加
2. パフォーマンステスト
3. 互換性テスト

## 💡 代替案

### 案A: 完全な書き換え
- 既存のProgressive Loadingを廃止
- 全て動的ロードに統一
- 破壊的変更になる

### 案B: 並行実装
- 既存APIを維持
- 新しい動的ロードAPIを追加
- 段階的移行が可能

### 案C: プラグイン化
- 動的ロード機能を別パッケージに
- pdfrx_engine_dynamicとして提供
- 必要な人だけ使用

## 📝 実装例

```dart
// 使用例
final document = await PdfDocument.openUri(
  uri,
  useDynamicLoading: true,  // 新フラグ
);

// 任意のページをロード
await document.loadPageDynamically(42);
final aspectRatio = await document.getPageAspectRatioDynamically(42);

// 複数ページを並行ロード
await document.loadPagesDynamically([1, 5, 10, 42]);
```

## 🔍 技術的詳細

### PDFium API の直接使用
```cpp
// C++ PDFium API
FPDF_PAGE FPDF_LoadPage(FPDF_DOCUMENT document, int page_index);
float FPDF_GetPageWidthF(FPDF_PAGE page);
float FPDF_GetPageHeightF(FPDF_PAGE page);
void FPDF_ClosePage(FPDF_PAGE page);
```

### FFI バインディング
```dart
// Dart FFI
final page = pdfium.FPDF_LoadPage(doc, pageIndex);
final width = pdfium.FPDF_GetPageWidthF(page);
final height = pdfium.FPDF_GetPageHeightF(page);
pdfium.FPDF_ClosePage(page);
```

## まとめ

pdfrx_engineの根本的な解決には、内部実装の大幅な修正が必要です。
最も現実的なのは**案B（並行実装）**で、既存APIを維持しながら新機能を追加することです。