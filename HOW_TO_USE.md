# 他のFlutterアプリでの使用方法

## ⚠️ 重要な注意事項

このフォークは公式版pdfrx 2.1.3に新機能を追加したものです。`useProgressiveLoading`と`loadOnlyTargetPage`は**このフォーク独自の機能**です。

## 🔧 セットアップ方法

### 方法1: ローカルパスを使用（推奨）

1. **pubspec.yamlを編集**：
```yaml
dependencies:
  pdfrx:
    path: /Users/iyori/pdfrx/packages/pdfrx
```

2. **依存関係を取得**：
```bash
flutter clean
flutter pub get
```

### 方法2: Gitから直接使用

1. **GitHubにプッシュ**（まだの場合）：
```bash
cd /Users/iyori/pdfrx
git add .
git commit -m "Add progressive loading features"
git push origin master
```

2. **pubspec.yamlでGit URLを指定**：
```yaml
dependencies:
  pdfrx:
    git:
      url: https://github.com/YOUR_USERNAME/pdfrx.git
      path: packages/pdfrx
      ref: master
```

## 📝 コードの修正

### 既存のコードとの互換性

公式版pdfrxを使用していたコードは、以下のように修正してください：

#### 修正前（公式版）:
```dart
PdfPageView(
  document: document,
  pageNumber: 1,
)
```

#### 修正後（このフォーク）:
```dart
PdfPageView(
  document: document,
  pageNumber: 1,
  useProgressiveLoading: true,  // 新機能（オプション）
  loadOnlyTargetPage: true,      // 新機能（オプション）
)
```

### 新機能を使わない場合

新機能のパラメータはすべてオプションなので、既存のコードはそのまま動作します：

```dart
// これは問題なく動作します
PdfViewer.uri(
  Uri.parse('https://example.com/document.pdf'),
  params: PdfViewerParams(
    enableTextSelection: true,
  ),
)
```

## 🚀 新機能の使用例

### 1. プログレッシブローディング

```dart
PdfPageView(
  document: document,
  pageNumber: currentPage,
  useProgressiveLoading: true,  // 段階的レンダリング
)
```

### 2. 単一ページのみ読み込み

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

## 🔍 トラブルシューティング

### エラー: "No named parameter with the name 'useProgressiveLoading'"

このエラーは公式版pdfrxを使用している場合に発生します。このフォークを使用していることを確認してください。

### エラー: "PdfrxEntryFunctions not found"

以下を実行してください：
```bash
flutter clean
rm -rf ~/.pub-cache
flutter pub get
```

### ビルドエラーが続く場合

1. **キャッシュをクリア**：
```bash
cd your_app
flutter clean
rm -rf .dart_tool
rm -rf build
flutter pub get
```

2. **IDEを再起動**

3. **それでも動作しない場合**、公式版を使用：
```yaml
dependencies:
  pdfrx: ^2.1.3  # 公式版（新機能なし）
```

## 📦 パッケージの状態

- ✅ ローカルで動作確認済み
- ✅ 新機能実装済み
- ✅ 既存コードとの互換性あり
- ⚠️ 公式版には新機能なし

## 💡 推奨事項

1. **開発時**: ローカルパスを使用
2. **本番環境**: GitHubにフォークしてGit URLを使用
3. **新機能不要な場合**: 公式版pdfrx ^2.1.3を使用

## 📞 サポート

問題が発生した場合：
1. このドキュメントのトラブルシューティングを確認
2. flutter cleanとpub getを実行
3. 公式版に戻すことを検討