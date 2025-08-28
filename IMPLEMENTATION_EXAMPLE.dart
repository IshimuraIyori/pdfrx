import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

void main() => runApp(MyPdfApp());

class MyPdfApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Single Page Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PdfViewerScreen(),
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  // PDFのURL（実際のURLに置き換えてください）
  final String pdfUrl = 'https://www.rfc-editor.org/rfc/pdfrfc/rfc6749.txt.pdf';
  int currentPage = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Viewer - Page $currentPage'),
        actions: [
          // 前のページ
          IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: currentPage > 1 
              ? () => setState(() => currentPage--) 
              : null,
          ),
          // 次のページ
          IconButton(
            icon: Icon(Icons.arrow_forward_ios),
            onPressed: () => setState(() => currentPage++),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[200],
        child: Center(
          child: Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              // ⭐ PdfSinglePageウィジェットを使用
              child: PdfSinglePage.uri(
                Uri.parse(pdfUrl),
                pageNumber: currentPage,
                useProgressiveLoading: true,    // 段階的読み込み
                preferRangeAccess: true,        // HTTP Range使用
                backgroundColor: Colors.white,
                maximumDpi: 200,                // レンダリング品質
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// より高度な例：エラーハンドリング付き
// ============================================================

class AdvancedPdfViewer extends StatefulWidget {
  final String pdfUrl;
  
  const AdvancedPdfViewer({Key? key, required this.pdfUrl}) : super(key: key);
  
  @override
  State<AdvancedPdfViewer> createState() => _AdvancedPdfViewerState();
}

class _AdvancedPdfViewerState extends State<AdvancedPdfViewer> {
  int currentPage = 1;
  int? totalPages;
  bool isLoading = true;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Viewer'),
        bottom: totalPages != null ? PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Container(
            color: Colors.blue[700],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Page $currentPage of $totalPages',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ) : null,
      ),
      body: PdfDocumentViewBuilder.uri(
        Uri.parse(widget.pdfUrl),
        builder: (context, document) {
          // ローディング中
          if (document == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading PDF...'),
                ],
              ),
            );
          }

          // 総ページ数を保存
          if (totalPages == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                totalPages = document.pages.length;
                isLoading = false;
              });
            });
          }

          // PDFを表示
          return Stack(
            children: [
              // PDF表示エリア
              PdfSinglePage.documentRef(
                documentRef: PdfDocumentRefDirect(document),
                pageNumber: currentPage.clamp(1, document.pages.length),
                maximumDpi: 200,
                backgroundColor: Colors.grey[100],
              ),
              
              // ページナビゲーション（オーバーレイ）
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 最初のページへ
                        IconButton(
                          icon: Icon(Icons.first_page, color: Colors.white),
                          onPressed: currentPage > 1
                            ? () => setState(() => currentPage = 1)
                            : null,
                        ),
                        // 前のページ
                        IconButton(
                          icon: Icon(Icons.chevron_left, color: Colors.white),
                          onPressed: currentPage > 1
                            ? () => setState(() => currentPage--)
                            : null,
                        ),
                        // ページ番号表示
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '$currentPage / ${totalPages ?? '?'}',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        // 次のページ
                        IconButton(
                          icon: Icon(Icons.chevron_right, color: Colors.white),
                          onPressed: (totalPages != null && currentPage < totalPages!)
                            ? () => setState(() => currentPage++)
                            : null,
                        ),
                        // 最後のページへ
                        IconButton(
                          icon: Icon(Icons.last_page, color: Colors.white),
                          onPressed: (totalPages != null && currentPage < totalPages!)
                            ? () => setState(() => currentPage = totalPages!)
                            : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// その他の使用例
// ============================================================

class UsageExamples {
  // 1. アセットからPDFを読み込む
  Widget assetExample() {
    return PdfSinglePage.asset(
      'assets/documents/manual.pdf',
      pageNumber: 1,
      maximumDpi: 150,
    );
  }

  // 2. ファイルパスから読み込む
  Widget fileExample(String filePath) {
    return PdfSinglePage.file(
      filePath,
      pageNumber: 1,
      useProgressiveLoading: true,
    );
  }

  // 3. 認証が必要なPDF
  Widget authenticatedPdf(String token) {
    return PdfSinglePage.uri(
      Uri.parse('https://api.example.com/secure/document.pdf'),
      pageNumber: 1,
      headers: {
        'Authorization': 'Bearer $token',
      },
      preferRangeAccess: true,
    );
  }

  // 4. パスワード保護されたPDF
  Widget passwordProtectedPdf() {
    return PdfSinglePage.uri(
      Uri.parse('https://example.com/protected.pdf'),
      pageNumber: 1,
      passwordProvider: () async {
        // ダイアログなどでパスワードを取得
        return 'password123';
      },
    );
  }

  // 5. メモリ（Uint8List）から読み込む
  Widget fromMemory(Uint8List pdfData) {
    return PdfSinglePage.data(
      pdfData,
      pageNumber: 1,
    );
  }
}