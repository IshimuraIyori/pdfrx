# リポジトリ情報

## 現在の実装場所

真の完全遅延ロード機能は以下のリポジトリ・ブランチに実装されています：

### GitHubリポジトリ
- **URL**: `https://github.com/IshimuraIyori/pdfrx.git`
- **ブランチ**: `feature/pdf-single-page`
- **フォーク元**: `https://github.com/espresso3389/pdfrx.git`

### 実装されたファイル

#### pdfrx_engine パッケージ内
- `/packages/pdfrx_engine/lib/src/pdfrx_api.dart`
  - `loadPageDynamically()` メソッド追加
  - `loadPagesDynamically()` メソッド追加

- `/packages/pdfrx_engine/lib/src/native/pdfrx_pdfium.dart`
  - `_PdfDocumentPdfium` クラスに動的ロード実装
  - `_loadSinglePageDimensions()` ヘルパーメソッド

- `/packages/pdfrx_engine/lib/src/native/pdfrx_truly_lazy.dart`
  - 真の遅延ロード実装（初期版）

- `/packages/pdfrx_engine/lib/src/native/pdfrx_truly_lazy_optimized.dart`
  - **最適化版の真の遅延ロード実装（推奨）**
  - `PdfDocumentTrulyLazyOptimized.openFileTrulyLazy()` - ローカルファイル用
  - `PdfDocumentTrulyLazyOptimized.openUriTrulyLazy()` - URL用
  - `PdfDocumentTrulyLazyOptimized.openDataTrulyLazy()` - メモリデータ用

- `/packages/pdfrx_engine/lib/src/pdfrx_api_extension.dart`
  - 便利な拡張メソッド
  - `loadPage()`, `getPageAspectRatio()` など

- `/packages/pdfrx_engine/lib/src/pdfrx_lazy_loading.dart`
  - ラッパー実装（代替案）

#### pdfrx パッケージ内
- `/packages/pdfrx/lib/src/widgets/pdf_single_page.dart`
  - 単一ページ表示ウィジェット

- `/packages/pdfrx/lib/src/widgets/pdf_single_page_dynamic.dart`
  - 動的ロード対応ウィジェット

- `/packages/pdfrx/lib/src/widgets/pdf_page_instant.dart`
  - 即座ページ切り替えウィジェット

- `/packages/pdfrx/lib/src/widgets/pdf_page_view_dynamic.dart`
  - 動的ページビューウィジェット

- `/packages/pdfrx/lib/src/wasm/pdfrx_wasm.dart`
  - Web版の動的ロード実装

### コミット履歴

最新のコミット（上から新しい順）：
1. `e0f00ca` - Pdfium直接呼び出しでローカルファイルで遅延ローディングを実現
2. `eb22576` - Add truly lazy loading support for PDF documents
3. `0548068` - feat: add fully lazy loading functionality for PDF documents
4. `ced1da3` - feat: implement dynamic page loading functionality in pdfrx_engine
5. `e30c607` - feat: add implementation example for PdfSinglePage widget

## 使用方法

### pubspec.yaml での指定

```yaml
dependencies:
  pdfrx:
    git:
      url: https://github.com/IshimuraIyori/pdfrx.git
      ref: feature/pdf-single-page  # このブランチを指定
      path: packages/pdfrx
  
  pdfrx_engine:
    git:
      url: https://github.com/IshimuraIyori/pdfrx.git
      ref: feature/pdf-single-page  # このブランチを指定
      path: packages/pdfrx_engine
```

### または特定のコミットを指定

```yaml
dependencies:
  pdfrx:
    git:
      url: https://github.com/IshimuraIyori/pdfrx.git
      ref: e0f00ca  # 最新の実装コミット
      path: packages/pdfrx
  
  pdfrx_engine:
    git:
      url: https://github.com/IshimuraIyori/pdfrx.git
      ref: e0f00ca  # 最新の実装コミット
      path: packages/pdfrx_engine
```

## 実装の確認方法

```bash
# クローン
git clone https://github.com/IshimuraIyori/pdfrx.git
cd pdfrx

# ブランチ切り替え
git checkout feature/pdf-single-page

# 実装ファイルの確認
ls packages/pdfrx_engine/lib/src/native/pdfrx_truly_lazy*.dart
```

## 注意事項

- このリポジトリは `espresso3389/pdfrx` のフォークです
- `feature/pdf-single-page` ブランチに全ての実装があります
- 本家にマージされるまではこのフォークを使用してください