import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

// =============================================================
// 動的ページ切り替え対応版の使用例
// =============================================================

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic PDF Page Viewer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: DynamicPdfViewer(),
    );
  }
}

/// PdfSinglePageDynamicを使用した動的ページビューア
/// どのページを選択しても高速で正しいアスペクト比で表示
class DynamicPdfViewer extends StatefulWidget {
  @override
  State<DynamicPdfViewer> createState() => _DynamicPdfViewerState();
}

class _DynamicPdfViewerState extends State<DynamicPdfViewer> {
  // PDFのURL
  final String pdfUrl = 'https://www.rfc-editor.org/rfc/pdfrfc/rfc6749.txt.pdf';
  
  // 現在のページ番号
  int currentPage = 1;
  
  // 総ページ数（ロード後に設定）
  int? totalPages;
  
  // ページ番号入力コントローラー
  final TextEditingController pageController = TextEditingController(text: '1');
  
  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
  
  void _goToPage(int page) {
    if (totalPages != null && page >= 1 && page <= totalPages!) {
      setState(() {
        currentPage = page;
        pageController.text = page.toString();
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dynamic PDF Viewer'),
        actions: [
          // ページ番号入力
          Container(
            width: 80,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              controller: pageController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Page',
                hintStyle: TextStyle(color: Colors.white70),
              ),
              onSubmitted: (value) {
                final page = int.tryParse(value);
                if (page != null) {
                  _goToPage(page);
                }
              },
            ),
          ),
          Text(
            ' / ${totalPages ?? '?'}',
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // PDF表示エリア
          Expanded(
            child: PdfDocumentViewBuilder.uri(
              Uri.parse(pdfUrl),
              builder: (context, document) {
                // ドキュメントがロードされたら総ページ数を保存
                if (document != null && totalPages == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      totalPages = document.pages.length;
                    });
                  });
                }
                
                if (document == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('PDFを読み込み中...'),
                      ],
                    ),
                  );
                }
                
                // ⭐ PdfSinglePageDynamicを使用
                // どのページに切り替えても高速で正しいアスペクト比で表示
                return PdfSinglePageDynamic.documentRef(
                  documentRef: PdfDocumentRefDirect(document),
                  pageNumber: currentPage,
                  maximumDpi: 200,
                  backgroundColor: Colors.grey[100],
                  preloadAdjacentPages: true,  // 隣接ページを事前ロード
                  preloadPageCount: 2,         // 前後2ページずつプリロード
                );
              },
            ),
          ),
          
          // ページナビゲーションコントロール
          Container(
            color: Colors.grey[200],
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 最初のページ
                IconButton(
                  icon: Icon(Icons.first_page),
                  onPressed: currentPage > 1
                    ? () => _goToPage(1)
                    : null,
                ),
                
                // 10ページ戻る
                IconButton(
                  icon: Icon(Icons.keyboard_double_arrow_left),
                  onPressed: currentPage > 10
                    ? () => _goToPage(currentPage - 10)
                    : currentPage > 1
                      ? () => _goToPage(1)
                      : null,
                ),
                
                // 1ページ戻る
                IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: currentPage > 1
                    ? () => _goToPage(currentPage - 1)
                    : null,
                ),
                
                // ページ番号表示
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Page $currentPage / ${totalPages ?? '?'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                
                // 1ページ進む
                IconButton(
                  icon: Icon(Icons.chevron_right),
                  onPressed: (totalPages != null && currentPage < totalPages!)
                    ? () => _goToPage(currentPage + 1)
                    : null,
                ),
                
                // 10ページ進む
                IconButton(
                  icon: Icon(Icons.keyboard_double_arrow_right),
                  onPressed: totalPages != null
                    ? (currentPage + 10 <= totalPages!
                      ? () => _goToPage(currentPage + 10)
                      : currentPage < totalPages!
                        ? () => _goToPage(totalPages!)
                        : null)
                    : null,
                ),
                
                // 最後のページ
                IconButton(
                  icon: Icon(Icons.last_page),
                  onPressed: (totalPages != null && currentPage < totalPages!)
                    ? () => _goToPage(totalPages!)
                    : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// ネットワークPDFでHTTP Range対応版
// =============================================================

class NetworkPdfViewerWithRange extends StatefulWidget {
  @override
  State<NetworkPdfViewerWithRange> createState() => _NetworkPdfViewerWithRangeState();
}

class _NetworkPdfViewerWithRangeState extends State<NetworkPdfViewerWithRange> {
  int currentPage = 1;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Network PDF with HTTP Range'),
      ),
      body: Column(
        children: [
          // ページ選択スライダー
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Page: $currentPage'),
                Slider(
                  value: currentPage.toDouble(),
                  min: 1,
                  max: 100,  // 仮の最大値
                  divisions: 99,
                  label: currentPage.toString(),
                  onChanged: (value) {
                    setState(() {
                      currentPage = value.round();
                    });
                  },
                ),
              ],
            ),
          ),
          
          // PDF表示
          Expanded(
            // ⭐ HTTP Range対応でネットワークPDFを効率的に表示
            child: PdfSinglePageDynamic.uri(
              Uri.parse('https://www.rfc-editor.org/rfc/pdfrfc/rfc9110.pdf'),
              pageNumber: currentPage,
              preferRangeAccess: true,       // HTTP Range有効
              preloadAdjacentPages: true,    // 隣接ページプリロード
              preloadPageCount: 3,           // 前後3ページプリロード
              maximumDpi: 150,
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// 高度な使用例：サムネイル付きビューア
// =============================================================

class AdvancedPdfViewer extends StatefulWidget {
  @override
  State<AdvancedPdfViewer> createState() => _AdvancedPdfViewerState();
}

class _AdvancedPdfViewerState extends State<AdvancedPdfViewer> {
  final String pdfUrl = 'https://www.rfc-editor.org/rfc/pdfrfc/rfc6749.txt.pdf';
  int currentPage = 1;
  PdfDocument? document;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Advanced PDF Viewer'),
      ),
      body: PdfDocumentViewBuilder.uri(
        Uri.parse(pdfUrl),
        builder: (context, doc) {
          document = doc;
          
          if (doc == null) {
            return Center(child: CircularProgressIndicator());
          }
          
          return Row(
            children: [
              // サムネイル一覧（左サイドバー）
              Container(
                width: 120,
                color: Colors.grey[300],
                child: ListView.builder(
                  itemCount: doc.pages.length,
                  itemBuilder: (context, index) {
                    final pageNum = index + 1;
                    final isSelected = pageNum == currentPage;
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          currentPage = pageNum;
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.all(4),
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            // ミニプレビュー
                            AspectRatio(
                              aspectRatio: doc.pages[index].width / doc.pages[index].height,
                              child: Container(
                                color: Colors.white,
                                child: Center(
                                  child: Text(
                                    pageNum.toString(),
                                    style: TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                            ),
                            Text('Page $pageNum', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // メインビュー（右側）
              Expanded(
                child: PdfSinglePageDynamic.documentRef(
                  documentRef: PdfDocumentRefDirect(doc),
                  pageNumber: currentPage,
                  maximumDpi: 300,
                  backgroundColor: Colors.grey[100],
                  preloadAdjacentPages: true,
                  preloadPageCount: 1,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}