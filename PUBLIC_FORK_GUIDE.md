# PDFrx Progressive Loading - 公開版セットアップガイド

## 🚀 GitHubで公開する手順

### 1. GitHubでフォークを作成

```bash
# 1. https://github.com/espresso3389/pdfrx にアクセス
# 2. 右上の「Fork」ボタンをクリック
# 3. あなたのGitHubアカウントにフォークが作成される
```

### 2. ローカルにクローン

```bash
# あなたのフォークをクローン
git clone https://github.com/IshimuraIyori/pdfrx.git
cd pdfrx
```

### 3. Progressive Loading ブランチを作成

```bash
# 新しいブランチを作成
git checkout -b progressive-loading

# このリポジトリの変更を適用
# (以下のファイルをコピーまたは手動で変更を適用)
```

### 4. 変更ファイルをコピー

以下のファイルを修正済みのものに置き換える：

- `packages/pdfrx/lib/src/widgets/pdf_widgets.dart`

### 5. GitHubにプッシュ

```bash
# 変更をコミット
git add .
git commit -m "Add progressive loading support with aspect ratio pre-loading"

# GitHubにプッシュ
git push -u origin progressive-loading
```

### 6. リリースタグを作成（オプション）

```bash
# タグを作成
git tag v1.0.0-progressive
git push origin v1.0.0-progressive
```

## 📦 誰でも使える方法

### 方法1: Git依存関係として使用

**pubspec.yaml:**
```yaml
dependencies:
  pdfrx:
    git:
      url: https://github.com/IshimuraIyori/pdfrx.git
      ref: progressive-loading
      path: packages/pdfrx
```

### 方法2: 特定のタグを使用（推奨）

**pubspec.yaml:**
```yaml
dependencies:
  pdfrx:
    git:
      url: https://github.com/IshimuraIyori/pdfrx.git
      ref: v1.0.0-progressive
      path: packages/pdfrx
```

### 方法3: 特定のコミットを固定

**pubspec.yaml:**
```yaml
dependencies:
  pdfrx:
    git:
      url: https://github.com/IshimuraIyori/pdfrx.git
      ref: f351c4c  # 特定のコミットハッシュ
      path: packages/pdfrx
```

## 💻 使用例

### 基本的な使い方

```dart
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class MyPdfViewer extends StatelessWidget {
  final String pdfUrl;
  
  const MyPdfViewer({required this.pdfUrl});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PDF Viewer')),
      body: PdfDocumentViewBuilder.uri(
        Uri.parse(pdfUrl),
        builder: (context, document) {
          if (document == null) {
            return Center(child: CircularProgressIndicator());
          }
          
          return PageView.builder(
            itemCount: document.pages.length,
            itemBuilder: (context, index) {
              return PdfPageView(
                document: document,
                pageNumber: index + 1,
                useProgressiveLoading: true,  // プログレッシブローディング
                loadOnlyTargetPage: true,     // メモリ最適化
              );
            },
          );
        },
      ),
    );
  }
}
```

### 単一ページ表示

```dart
PdfPageView(
  document: document,
  pageNumber: 5,  // 5ページ目を表示
  useProgressiveLoading: true,
  loadOnlyTargetPage: true,  // 5ページ目のみロード
)
```

## 📝 README.md テンプレート

以下の内容でREADME.mdを作成してGitHubリポジトリに追加：

```markdown
# PDFrx with Progressive Loading

A fork of [pdfrx](https://github.com/espresso3389/pdfrx) with progressive loading support.

## Features

✨ **Progressive Loading**: Display PDFs with correct aspect ratio immediately
🚀 **Performance**: Low quality preview (25%) → Full quality rendering
💾 **Memory Efficient**: Optional single page loading
📐 **Aspect Ratio**: Pre-loads page dimensions before rendering

## Installation

Add to your `pubspec.yaml`:

\`\`\`yaml
dependencies:
  pdfrx:
    git:
      url: https://github.com/IshimuraIyori/pdfrx.git
      ref: progressive-loading
      path: packages/pdfrx
\`\`\`

## Usage

\`\`\`dart
PdfPageView(
  document: document,
  pageNumber: 1,
  useProgressiveLoading: true,  // Enable progressive loading
  loadOnlyTargetPage: true,     // Load only displayed page
)
\`\`\`

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `useProgressiveLoading` | `bool` | `false` | Enable two-pass progressive rendering |
| `loadOnlyTargetPage` | `bool` | `false` | Load only the target page (memory optimization) |

## License

Same as the original [pdfrx](https://github.com/espresso3389/pdfrx) project.
```

## 🌍 共有用メッセージテンプレート

SNSやフォーラムで共有する際のテンプレート：

```
PDFrxにプログレッシブローディング機能を追加したフォークを公開しました！

✨ 特徴:
- 正しいアスペクト比で即座に表示
- 低品質→高品質の段階的レンダリング
- メモリ効率的な単一ページ読み込み

📦 使い方:
pubspec.yamlに追加するだけ：
pdfrx:
  git:
    url: https://github.com/IshimuraIyori/pdfrx.git
    ref: progressive-loading
    path: packages/pdfrx

詳細: https://github.com/IshimuraIyori/pdfrx/tree/progressive-loading
```

## ⚠️ 重要な注意事項

1. GitHubユーザー名: **IshimuraIyori**
2. パブリックリポジトリにすることで誰でも使用可能
3. MITライセンス（オリジナルと同じ）を維持
4. オリジナルへのクレジットを含める

## 🔄 メンテナンス

### 最新版との同期

```bash
# オリジナルをリモートとして追加
git remote add upstream https://github.com/espresso3389/pdfrx.git

# 最新の変更を取得
git fetch upstream
git checkout progressive-loading
git merge upstream/master

# 競合を解決してプッシュ
git push origin progressive-loading
```

これで世界中の誰でもあなたのプログレッシブローディング機能を使えます！🎉