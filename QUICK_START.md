# クイックスタートガイド - Progressive Loading PDFrx

## 🚀 3分で使い始める

### ステップ1: pubspec.yamlに追加

```yaml
dependencies:
  pdfrx:
    git:
      url: https://github.com/IshimuraIyori/pdfrx.git
      ref: progressive-loading
      path: packages/pdfrx
```

### ステップ2: パッケージを取得

```bash
flutter pub get
```

### ステップ3: 使用開始

```dart
import 'package:pdfrx/pdfrx.dart';

// シンプルな例
PdfViewer.uri(
  Uri.parse('https://example.com/sample.pdf'),
  params: PdfViewerParams(
    // 既存の機能はそのまま使える
  ),
)
```

## ✨ 新機能の使い方

### プログレッシブローディング（推奨）

```dart
PdfDocumentViewBuilder.uri(
  Uri.parse('https://example.com/large-document.pdf'),
  builder: (context, document) {
    if (document == null) {
      return Center(child: CircularProgressIndicator());
    }
    
    return PdfPageView(
      document: document,
      pageNumber: 1,
      useProgressiveLoading: true,  // ← これを追加！
    );
  },
)
```

### メモリ最適化（大きなPDF用）

```dart
PdfPageView(
  document: document,
  pageNumber: 10,
  useProgressiveLoading: true,
  loadOnlyTargetPage: true,  // ← 10ページ目のみロード
)
```

## 📱 完全な実装例

```dart
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PdfViewerScreen(),
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  @override
  _PdfViewerScreenState createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final controller = PageController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Progressive PDF Viewer'),
      ),
      body: PdfDocumentViewBuilder.uri(
        Uri.parse('https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'),
        builder: (context, document) {
          if (document == null) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          
          return PageView.builder(
            controller: controller,
            itemCount: document.pages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.all(8),
                child: PdfPageView(
                  document: document,
                  pageNumber: index + 1,
                  useProgressiveLoading: true,  // プログレッシブ
                  loadOnlyTargetPage: true,     // メモリ効率
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

## 🎯 いつ使うべきか

### useProgressiveLoading を使う場合
- ✅ 大きなPDFファイル（10MB以上）
- ✅ ネットワーク経由でPDFを読み込む
- ✅ ユーザー体験を向上させたい
- ✅ 正しいアスペクト比で即座に表示したい

### loadOnlyTargetPage を使う場合
- ✅ 非常に大きなPDF（100ページ以上）
- ✅ メモリが限られたデバイス
- ✅ 単一ページビューア
- ✅ サムネイル表示は不要

## ⚡ パフォーマンス比較

| 機能 | 通常 | Progressive | Progressive + Single Page |
|------|------|-------------|--------------------------|
| 初期表示 | 遅い | 速い (25%) | 速い (25%) |
| メモリ使用 | 全ページ | 全ページ | 1ページのみ |
| アスペクト比 | 読込後 | 即座に正確 | 即座に正確 |
| UX | 待機 | スムーズ | 最もスムーズ |

## 🔧 トラブルシューティング

### エラーが出る場合

```bash
flutter clean
flutter pub cache clean
flutter pub get
```

### 古いバージョンのFlutterを使用している場合

```yaml
# 特定のコミットを使用
dependencies:
  pdfrx:
    git:
      url: https://github.com/IshimuraIyori/pdfrx.git
      ref: f351c4c  # 安定版のコミット
      path: packages/pdfrx
```

## 📚 関連リンク

- [詳細なドキュメント](PROGRESSIVE_LOADING_FORK.md)
- [セットアップガイド](PUBLIC_FORK_GUIDE.md)
- [オリジナルのpdfrx](https://github.com/espresso3389/pdfrx)

---

質問や問題がある場合は、GitHubのIssuesで報告してください！