# カスタム機能の説明

このフォークでは、以下の機能が追加されています：

## 🚀 新機能

### 1. プログレッシブローディング with 正しいアスペクト比

`PdfPageView`に`useProgressiveLoading`パラメータを追加しました。これにより：
- ページの正しいアスペクト比が最初から適用されます
- 低品質プレビュー（25%スケール）が先に表示されます
- その後、フル品質画像がレンダリングされます

```dart
PdfPageView(
  document: document,
  pageNumber: 1,
  useProgressiveLoading: true,  // 追加
)
```

### 2. 単一ページのみの効率的な読み込み

大きなPDFファイルから特定の1ページのみを読み込む機能：

```dart
PdfPageView(
  document: document,
  pageNumber: 5,
  useProgressiveLoading: true,
  loadOnlyTargetPage: true,  // 追加：このページのみを読み込む
)
```

### 3. PdfDocumentViewBuilderでの特定ページ指定

ドキュメントレベルで特定ページのみを読み込む：

```dart
PdfDocumentViewBuilder.uri(
  uri,
  useProgressiveLoading: true,
  targetPageNumber: 5,  // 追加：5ページ目のみを読み込む
  builder: (context, document) {
    // ...
  },
)
```

## 📋 使用例

### 例1: 大きなPDFから特定ページを表示

```dart
class SpecificPageViewer extends StatelessWidget {
  final int pageNumber = 10;
  
  @override
  Widget build(BuildContext context) {
    return PdfDocumentViewBuilder.uri(
      Uri.parse('https://example.com/large-document.pdf'),
      useProgressiveLoading: true,
      targetPageNumber: pageNumber,
      builder: (context, document) {
        if (document == null) {
          return Center(child: CircularProgressIndicator());
        }
        
        return PdfPageView(
          document: document,
          pageNumber: pageNumber,
          useProgressiveLoading: true,
          loadOnlyTargetPage: true,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(2, 2),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### 例2: プログレッシブレンダリングでスムーズな表示

```dart
PdfPageView(
  document: document,
  pageNumber: currentPage,
  useProgressiveLoading: true,  // 段階的にレンダリング
  maximumDpi: 300,
  alignment: Alignment.center,
)
```

## 🔧 パラメータ詳細

### PdfPageView

| パラメータ | 型 | デフォルト | 説明 |
|-----------|-----|-----------|------|
| `useProgressiveLoading` | `bool` | `false` | プログレッシブレンダリングを有効化 |
| `loadOnlyTargetPage` | `bool` | `false` | 指定ページのみを読み込む |

### PdfDocumentViewBuilder

| パラメータ | 型 | デフォルト | 説明 |
|-----------|-----|-----------|------|
| `targetPageNumber` | `int?` | `null` | 読み込む特定のページ番号（1ベース） |

## 💡 メリット

1. **メモリ効率**: 大きなPDFファイルでも必要なページだけを読み込み
2. **高速表示**: プログレッシブレンダリングで即座に内容を確認可能
3. **正しいレイアウト**: 最初から正しいアスペクト比で表示
4. **スムーズなUX**: 低品質から高品質へ段階的に改善

## ⚠️ 注意事項

- `useProgressiveLoading`と`loadOnlyTargetPage`は組み合わせて使用することを推奨
- `targetPageNumber`は1ベースのページ番号です（最初のページは1）
- プログレッシブレンダリングは追加のCPU使用量が発生する可能性があります