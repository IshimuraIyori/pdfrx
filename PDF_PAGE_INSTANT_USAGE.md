# PdfPageInstant - 単一ページ即座表示ウィジェット

指定したページ**だけ**を、**正しいアスペクト比**で**即座に表示**するウィジェットです。

## 特徴

- ✅ **指定ページのみロード** - 他のページは一切触らない
- ✅ **正しいアスペクト比** - 各ページの実際の比率を即座に取得
- ✅ **HTTP Range対応** - ネットワークPDFで必要な部分だけ取得
- ✅ **軽量** - プリロードや隣接ページの処理なし
- ✅ **独立動作** - ページ切り替え時は新しいインスタンスで高速表示

## 基本的な使い方

```dart
import 'package:pdfrx/pdfrx.dart';

// ネットワークPDFの42ページ目だけを表示
PdfPageInstant.uri(
  Uri.parse('https://example.com/document.pdf'),
  pageNumber: 42,  // このページだけがロードされる
)
```

## ページ切り替えの実装例

```dart
class SinglePageViewer extends StatefulWidget {
  @override
  State<SinglePageViewer> createState() => _SinglePageViewerState();
}

class _SinglePageViewerState extends State<SinglePageViewer> {
  final String pdfUrl = 'https://www.rfc-editor.org/rfc/pdfrfc/rfc9110.pdf';
  int currentPage = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page $currentPage'),
        actions: [
          IconButton(
            icon: Icon(Icons.navigate_before),
            onPressed: currentPage > 1
                ? () => setState(() => currentPage--)
                : null,
          ),
          IconButton(
            icon: Icon(Icons.navigate_next),
            onPressed: () => setState(() => currentPage++),
          ),
        ],
      ),
      body: Center(
        // ページが変わるたびに新しいインスタンスが作られ、
        // そのページだけが正しいアスペクト比で表示される
        child: PdfPageInstant.uri(
          Uri.parse(pdfUrl),
          pageNumber: currentPage,
          preferRangeAccess: true,  // HTTP Range使用
          maximumDpi: 200,
        ),
      ),
    );
  }
}
```

## 様々なソースからの読み込み

```dart
// 1. ネットワークPDF（HTTP Range対応）
PdfPageInstant.uri(
  Uri.parse('https://example.com/large.pdf'),
  pageNumber: 100,
  preferRangeAccess: true,
)

// 2. ローカルファイル
PdfPageInstant.file(
  '/path/to/document.pdf',
  pageNumber: 5,
)

// 3. アセット
PdfPageInstant.asset(
  'assets/manual.pdf',
  pageNumber: 1,
)

// 4. メモリ（Uint8List）
PdfPageInstant.data(
  pdfBytes,
  pageNumber: 3,
)
```

## 高度な使い方

### ページ番号入力での直接ジャンプ

```dart
class DirectPageJumper extends StatefulWidget {
  @override
  State<DirectPageJumper> createState() => _DirectPageJumperState();
}

class _DirectPageJumperState extends State<DirectPageJumper> {
  final TextEditingController _controller = TextEditingController(text: '1');
  int _currentPage = 1;
  
  void _jumpToPage(String value) {
    final page = int.tryParse(value);
    if (page != null && page > 0) {
      setState(() {
        _currentPage = page;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Page number',
            border: InputBorder.none,
          ),
          keyboardType: TextInputType.number,
          onSubmitted: _jumpToPage,
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: PdfPageInstant.uri(
        Uri.parse('https://example.com/document.pdf'),
        pageNumber: _currentPage,
        backgroundColor: Colors.grey[100],
      ),
    );
  }
}
```

### 認証付きPDF

```dart
PdfPageInstant.uri(
  Uri.parse('https://api.example.com/secure.pdf'),
  pageNumber: 10,
  headers: {
    'Authorization': 'Bearer $token',
  },
  preferRangeAccess: true,
)
```

### パスワード保護PDF

```dart
PdfPageInstant.uri(
  Uri.parse('https://example.com/protected.pdf'),
  pageNumber: 1,
  passwordProvider: () async => 'secret123',
)
```

## パフォーマンスのポイント

1. **ページごとに独立** - 各ページは完全に独立して処理される
2. **キャッシュ不要** - ウィジェット自体が軽量なので再作成のコストが低い
3. **メモリ効率** - 表示中のページのみメモリに保持
4. **HTTP Range** - ネットワークPDFで必要な部分だけダウンロード

## 他のウィジェットとの比較

| ウィジェット | 用途 | 特徴 |
|------------|------|------|
| **PdfPageInstant** | 単一ページの即座表示 | 最も軽量、指定ページのみロード |
| PdfSinglePage | 固定ページ表示 | progressiveLoadingTargetPage使用 |
| PdfSinglePageDynamic | 隣接ページも考慮 | プリロード機能あり（複雑） |
| PdfViewer | 全体表示 | スクロール可能、全ページ管理 |

## 実装の仕組み

```dart
// 内部動作
1. PdfPageInstant作成（pageNumber: 42）
2. progressiveLoadingTargetPage: 42 でドキュメントを開く
3. 42ページ目だけをロード（1x1ピクセルでレンダリング）
4. アスペクト比を取得（width/height）
5. 正しい比率で実際のレンダリング
```

## エラーハンドリング

ウィジェット内でエラーハンドリングが実装されています：

```dart
PdfPageInstant.uri(
  Uri.parse('https://example.com/may-fail.pdf'),
  pageNumber: 999,  // 存在しないページでも安全
  fallbackAspectRatio: 1 / 1.41421356,  // A4縦
)
```

## pubspec.yaml設定

```yaml
dependencies:
  pdfrx:
    git:
      url: https://github.com/IshimuraIyori/pdfrx.git
      ref: feature/pdf-single-page
      path: packages/pdfrx
```

## まとめ

`PdfPageInstant`は、**特定のページだけを素早く正しいアスペクト比で表示したい**場合に最適です。余計な処理がなく、シンプルで高速な実装になっています。