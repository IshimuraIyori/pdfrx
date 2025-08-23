# PDFrx Progressive Loading Fork

正しいアスペクト比で即座にPDFを表示できるpdfrxの改良版です。

## ✨ 新機能

- **Progressive Loading**: 低品質プレビュー → 高品質レンダリング
- **正確なアスペクト比**: ページ情報を事前取得して正しい比率で表示
- **メモリ最適化**: 必要なページのみロード可能

## 📦 インストール

### 方法1: GitHubから直接使用

```yaml
dependencies:
  pdfrx:
    git:
      url: https://github.com/IshimuraIyori/pdfrx.git
      ref: progressive-loading
      path: packages/pdfrx
```

### 方法2: ローカルパスから使用

```yaml
dependencies:
  pdfrx:
    path: /path/to/pdfrx/packages/pdfrx
```

## 🚀 使い方

```dart
import 'package:pdfrx/pdfrx.dart';

// 基本的な使用（公式版と同じ）
PdfViewer.uri(
  Uri.parse('https://example.com/document.pdf'),
)

// Progressive Loading を有効化
PdfPageView(
  document: document,
  pageNumber: 1,
  useProgressiveLoading: true,  // NEW!
  loadOnlyTargetPage: true,     // NEW! (optional)
)
```

## 📝 新しいパラメータ

| パラメータ | 型 | デフォルト | 説明 |
|-----------|-----|----------|------|
| `useProgressiveLoading` | `bool` | `false` | プログレッシブレンダリングを有効化 |
| `loadOnlyTargetPage` | `bool` | `false` | 表示ページのみロード（メモリ効率） |

## 🎯 動作の仕組み

`useProgressiveLoading: true` の場合：

1. **ページ情報の事前取得**: `loadPagesProgressively()` でページのwidth/heightを取得
2. **ローディング表示**: ページ情報取得中は `CircularProgressIndicator` を表示
3. **正しいアスペクト比で領域確保**: ページサイズが確定後、正確な比率で表示領域を確保
4. **段階的レンダリング**: 25%品質 → 100%品質の2段階でレンダリング

## 💡 使用例

### シンプルな例

```dart
PdfDocumentViewBuilder.uri(
  Uri.parse('https://example.com/document.pdf'),
  builder: (context, document) {
    if (document == null) {
      return Center(child: CircularProgressIndicator());
    }
    
    return PdfPageView(
      document: document,
      pageNumber: 1,
      useProgressiveLoading: true,
    );
  },
)
```

### ページビューアー

```dart
PageView.builder(
  itemCount: document.pages.length,
  itemBuilder: (context, index) {
    return PdfPageView(
      document: document,
      pageNumber: index + 1,
      useProgressiveLoading: true,
      loadOnlyTargetPage: true,  // メモリ効率化
    );
  },
)
```

## 🔧 トラブルシューティング

エラーが発生する場合：

```bash
flutter clean
flutter pub cache clean
flutter pub get
```

## ⚙️ 技術詳細

変更箇所：
- `packages/pdfrx/lib/src/widgets/pdf_widgets.dart` のみ
- 追加メソッド: `_ensurePageLoaded()`, `_updateImageProgressive()`, `_renderProgressive()`
- 公式版との100%後方互換性を維持

## 📄 ライセンス

オリジナルのpdfrxと同じライセンスです。

## 🙏 クレジット

Original pdfrx: https://github.com/espresso3389/pdfrx

---

**注意**: これは非公式のフォークです。公式版は [https://github.com/espresso3389/pdfrx](https://github.com/espresso3389/pdfrx) をご覧ください。