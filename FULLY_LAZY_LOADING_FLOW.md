# 完全遅延ロードの動作フロー詳細

## 現在の実装の流れ

### Step 1: PDFドキュメントを開く

```dart
final document = await PdfDocumentLazyLoading.openUriLazy(
  Uri.parse('https://example.com/document.pdf'),
  preferRangeAccess: true,
);
```

内部動作：
1. **PDFファイルのヘッダー部分のみダウンロード**（HTTP Range使用時）
2. PDFium経由でドキュメントハンドルを取得
3. **ページ数のみ取得**（`FPDF_GetPageCount`）
4. プレースホルダーページを作成（デフォルトサイズ: A4）

```cpp
// PDFium C++ API
FPDF_DOCUMENT doc = FPDF_LoadDocument(...);
int pageCount = FPDF_GetPageCount(doc);
// この時点では個別ページはロードしない
```

### Step 2: プレースホルダーページの作成

```dart
// _LazyPdfDocument コンストラクタ内
_lazyPages = List.generate(
  pageCount,
  (index) => _LazyPdfPage(
    pageNumber: index + 1,
    document: null,
  ),
);
```

各ページの初期状態：
- `_actualWidth = null`（未ロード）
- `_actualHeight = null`（未ロード）
- `_isActuallyLoaded = false`
- デフォルト値: 595x842（A4サイズ）

### Step 3: 特定ページへのアクセス

ユーザーがページ42を表示したい場合：

```dart
await document.loadPageDynamically(42);
```

### Step 4: 動的ページロード

```dart
// _LazyPdfDocument.loadPageDynamically
Future<bool> loadPageDynamically(int pageNumber) async {
  final pageIndex = pageNumber - 1;
  final lazyPage = _lazyPages[pageIndex];
  
  if (lazyPage._isActuallyLoaded) return true; // 既にロード済み
  
  // ここで初めてページをロード
  final success = await _loadPageDimensions(pageIndex);
  // ...
}
```

### Step 5: PDFiumでページ情報取得

```dart
// バックグラウンドワーカーで実行
Future<PageDimensions> _loadPageDimensions(int pageIndex) async {
  return await backgroundWorker.compute((params) {
    final doc = FPDF_DOCUMENT.fromAddress(params.docAddress);
    
    // この時点で初めてページをロード
    final page = pdfium.FPDF_LoadPage(doc, pageIndex);
    
    try {
      return (
        width: pdfium.FPDF_GetPageWidthF(page),
        height: pdfium.FPDF_GetPageHeightF(page),
        rotation: pdfium.FPDFPage_GetRotation(page),
      );
    } finally {
      pdfium.FPDF_ClosePage(page);
    }
  }, ...);
}
```

### Step 6: ページ情報の更新

```dart
// 実際のサイズで更新
lazyPage._actualWidth = pageData.width;
lazyPage._actualHeight = pageData.height;
lazyPage._actualRotation = pageData.rotation;
lazyPage._isActuallyLoaded = true;
```

### Step 7: レンダリング

```dart
// PdfPageView ウィジェットが呼び出す
await page.render(
  fullWidth: viewportWidth,
  fullHeight: viewportHeight,
);
```

レンダリング時の動作：
1. ページがまだロードされていない場合は自動ロード
2. PDFiumでページをレンダリング
3. ビットマップをFlutterのImageに変換
4. 画面に表示

## HTTP Rangeリクエストの流れ（ネットワークPDFの場合）

```
初期化時:
GET /document.pdf
Range: bytes=0-1024  // ヘッダー部分のみ

ページ42アクセス時:
GET /document.pdf
Range: bytes=420000-440000  // ページ42周辺のデータ
```

## メモリ使用パターン

```
初期化直後:
- ドキュメントハンドル: 1KB
- プレースホルダーページ × 100: 10KB
合計: ~11KB

ページ1表示後:
- ドキュメントハンドル: 1KB
- プレースホルダーページ × 99: 9.9KB
- ロード済みページ × 1: 100KB
合計: ~111KB

ページ1,42,85表示後:
- ドキュメントハンドル: 1KB
- プレースホルダーページ × 97: 9.7KB
- ロード済みページ × 3: 300KB
合計: ~311KB
```

## タイミング分析

```
通常ロード:
1. PDFを開く: 2000ms（全ページロード）
2. ページ42表示: 10ms（既にロード済み）
合計: 2010ms

プログレッシブロード:
1. PDFを開く: 500ms（全ページサイズ取得）
2. ページ42表示: 100ms（ページ内容ロード）
合計: 600ms

完全遅延ロード:
1. PDFを開く: 50ms（ページ数のみ）
2. ページ42表示: 150ms（サイズ+内容ロード）
合計: 200ms
```

## 実装の課題と解決策

### 課題1: 同期的なプロパティアクセス

```dart
// page.width は同期プロパティ
double width = page.width;  // この時点でロードが必要
```

解決策：
- 内部で非同期ロードをトリガー（理想的ではない）
- または事前に`loadPageDynamically()`を呼ぶ

### 課題2: 初回表示の遅延

解決策：
```dart
// 隣接ページの先読み
await document.loadPagesDynamically([
  currentPage - 1,
  currentPage,
  currentPage + 1,
]);
```

### 課題3: デフォルトサイズの不一致

解決策：
```dart
// ロード前は推定サイズを使用
final estimatedRatio = _guessAspectRatio(pageNumber);
// 実際のサイズが判明したら更新
setState(() {
  actualRatio = page.width / page.height;
});
```

## フローチャート

```
[ユーザー] PDFを開く
    ↓
[System] ドキュメントハンドル取得
    ↓
[System] ページ数のみ取得
    ↓
[System] プレースホルダー作成
    ↓
[ユーザー] ページ42を表示
    ↓
[System] ページ42ロード済み？
    ↓ No
[System] PDFiumでページ42ロード
    ↓
[System] サイズ取得（width, height）
    ↓
[System] ページ情報更新
    ↓
[System] レンダリング
    ↓
[画面] 表示完了
```

## パフォーマンス最適化のポイント

1. **バッチロード**: 複数ページを同時にロード
2. **キャッシング**: 一度ロードしたページ情報を保持
3. **先読み**: 隣接ページを事前ロード
4. **Range Request**: 必要な部分のみダウンロード
5. **バックグラウンド処理**: UIをブロックしない

## まとめ

完全遅延ロードは以下の流れで動作：

1. **最小限の初期化**（ページ数のみ）
2. **オンデマンドロード**（アクセス時に初めてロード）
3. **段階的な情報取得**（サイズ→内容）
4. **効率的なメモリ管理**（必要なページのみ保持）

これにより、巨大なPDFでも瞬時に開き、必要なページのみを効率的に表示できます。