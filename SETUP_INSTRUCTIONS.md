# セットアップ手順

## 🚀 クイックスタート

### 方法A: GitHubフォークを使用（推奨）

1. **GitHubでフォーク**
   ```bash
   # https://github.com/espresso3389/pdfrx をフォーク
   # その後、あなたのフォークをクローン
   git clone https://github.com/YOUR_USERNAME/pdfrx.git
   cd pdfrx
   ```

2. **現在の変更を取り込む**
   ```bash
   # このリポジトリをリモートとして追加
   git remote add custom /Users/iyori/pdfrx
   
   # 変更を取り込む
   git fetch custom
   git merge custom/master
   
   # あなたのフォークにプッシュ
   git push origin master
   ```

3. **Flutterプロジェクトで使用**
   ```yaml
   # pubspec.yaml
   dependencies:
     pdfrx:
       git:
         url: https://github.com/YOUR_USERNAME/pdfrx.git
         path: packages/pdfrx
         ref: master
   ```

### 方法B: 直接このリポジトリを使用

```yaml
# pubspec.yaml
dependencies:
  pdfrx:
    path: /Users/iyori/pdfrx/packages/pdfrx
```

## 📦 変更内容の確認

変更されたファイル：
- `packages/pdfrx/lib/src/widgets/pdf_widgets.dart`

追加機能：
- `useProgressiveLoading`: プログレッシブレンダリング
- `loadOnlyTargetPage`: 単一ページ読み込み
- `targetPageNumber`: 特定ページ指定

## 🔨 ビルドとテスト

```bash
# 依存関係の取得
cd packages/pdfrx
flutter pub get

# テストの実行
flutter test

# 例の実行
cd example/viewer
flutter run
```

## 📝 使用例

### 基本的な使用

```dart
import 'package:pdfrx/pdfrx.dart';

class MyPdfViewer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PdfViewer.uri(
      Uri.parse('https://example.com/document.pdf'),
      params: PdfViewerParams(
        enableTextSelection: true,
      ),
    );
  }
}
```

### 単一ページの効率的な読み込み

```dart
PdfDocumentViewBuilder.uri(
  Uri.parse('https://example.com/large.pdf'),
  useProgressiveLoading: true,
  targetPageNumber: 10,  // 10ページ目のみ読み込み
  builder: (context, document) {
    if (document == null) {
      return CircularProgressIndicator();
    }
    
    return PdfPageView(
      document: document,
      pageNumber: 10,
      useProgressiveLoading: true,
      loadOnlyTargetPage: true,
    );
  },
)
```

### プログレッシブレンダリング

```dart
// 低品質プレビューから高品質へ段階的にレンダリング
PdfPageView(
  document: document,
  pageNumber: 1,
  useProgressiveLoading: true,
  maximumDpi: 300,
)
```

## 🆕 新しいパラメータ

### PdfPageView

```dart
PdfPageView({
  required PdfDocument? document,
  required int pageNumber,
  bool useProgressiveLoading = false,  // 新規
  bool loadOnlyTargetPage = false,     // 新規
  // ... その他のパラメータ
})
```

### PdfDocumentViewBuilder

```dart
PdfDocumentViewBuilder.uri(
  Uri uri, {
  int? targetPageNumber,  // 新規：特定ページのみ読み込み
  // ... その他のパラメータ
})
```

## 📚 詳細ドキュメント

- [カスタム機能の説明](CUSTOM_FEATURES.md)
- [フォークガイド](FORK_GUIDE.md)

## ⚡ パフォーマンスのヒント

1. 大きなPDFファイル（100ページ以上）では`targetPageNumber`を使用
2. ネットワーク経由のPDFでは`useProgressiveLoading`を有効化
3. メモリが限られている環境では`loadOnlyTargetPage`を使用

## 🐛 トラブルシューティング

### エラー: "package not found"
```bash
flutter clean
flutter pub get
```

### エラー: "version solving failed"
```bash
flutter pub cache clean
flutter pub get
```

## 📄 ライセンス

このフォークは元のpdfrxプロジェクトのライセンスに従います。
詳細は[LICENSE](LICENSE)を参照してください。