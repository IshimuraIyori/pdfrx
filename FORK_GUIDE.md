# pdfrx フォークガイド

このガイドでは、修正版のpdfrxを他のFlutterアプリで使用する方法を説明します。

## 方法1: GitHubフォーク（推奨）

### 手順1: GitHubでフォーク

1. https://github.com/espresso3389/pdfrx にアクセス
2. 右上の「Fork」ボタンをクリック
3. 自分のGitHubアカウントにフォーク

### 手順2: ローカルにクローン

```bash
git clone https://github.com/YOUR_USERNAME/pdfrx.git
cd pdfrx
```

### 手順3: 変更をコミット

現在の変更をコミットします：

```bash
# 変更をステージング
git add packages/pdfrx/lib/src/widgets/pdf_widgets.dart

# コミット
git commit -m "feat: Add single page progressive loading support

- Add useProgressiveLoading parameter to PdfPageView
- Add loadOnlyTargetPage for efficient single page loading
- Add targetPageNumber to PdfDocumentViewBuilder
- Implement progressive rendering with correct aspect ratio"

# リモートにプッシュ
git push origin master
```

### 手順4: Flutterアプリで使用

あなたのFlutterアプリの`pubspec.yaml`で：

```yaml
dependencies:
  pdfrx:
    git:
      url: https://github.com/YOUR_USERNAME/pdfrx.git
      path: packages/pdfrx
      ref: master  # または特定のコミットハッシュ/タグ
```

## 方法2: ローカルパス依存関係

開発中やテスト時に便利です：

```yaml
dependencies:
  pdfrx:
    path: /path/to/your/pdfrx/packages/pdfrx
```

## 方法3: プライベートpub.devパッケージ

独自のパッケージ名で公開する場合：

### 手順1: パッケージ名を変更

`packages/pdfrx/pubspec.yaml`を編集：

```yaml
name: pdfrx_custom  # または好きな名前
version: 1.1.0  # バージョンを上げる
description: Custom fork of pdfrx with single page loading support
```

### 手順2: 公開

```bash
cd packages/pdfrx
flutter pub publish
```

### 手順3: 使用

```yaml
dependencies:
  pdfrx_custom: ^1.1.0
```

## 使用例

### 単一ページのプログレッシブローディング

```dart
import 'package:pdfrx/pdfrx.dart';

// 特定のページのみを効率的に読み込む
class SinglePageViewer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PdfDocumentViewBuilder.uri(
      Uri.parse('https://example.com/large.pdf'),
      useProgressiveLoading: true,
      targetPageNumber: 5,  // 5ページ目のみを読み込む
      builder: (context, document) {
        if (document == null) {
          return CircularProgressIndicator();
        }
        
        return PdfPageView(
          document: document,
          pageNumber: 5,
          useProgressiveLoading: true,
          loadOnlyTargetPage: true,  // このページのみを読み込む
        );
      },
    );
  }
}
```

### プログレッシブレンダリング

```dart
// 低品質プレビューから高品質へ段階的にレンダリング
PdfPageView(
  document: document,
  pageNumber: 1,
  useProgressiveLoading: true,  // プログレッシブレンダリング有効
)
```

## 主な機能追加

1. **`useProgressiveLoading`**: プログレッシブレンダリングを有効化
   - 正しいアスペクト比を即座に適用
   - 低品質プレビュー（25%）を先に表示
   - その後フル品質画像をレンダリング

2. **`loadOnlyTargetPage`**: 単一ページのみを読み込む
   - 大きなPDFファイルでメモリ効率的
   - 必要なページだけを読み込む

3. **`targetPageNumber`**: PdfDocumentViewBuilderで特定ページを指定
   - ドキュメントレベルで特定ページのみを読み込む

## 注意事項

- フォークを最新に保つため、定期的に上流リポジトリから更新を取り込むことをお勧めします
- 本家にプルリクエストを送ることも検討してください

## 上流の更新を取り込む

```bash
# 上流リポジトリを追加（初回のみ）
git remote add upstream https://github.com/espresso3389/pdfrx.git

# 上流から最新を取得
git fetch upstream
git checkout master
git merge upstream/master

# 競合があれば解決してコミット
git push origin master
```