/// Example demonstrating dynamic page loading in pdfrx_engine
/// 
/// This example shows how to use the new dynamic page loading APIs
/// to load specific PDF pages on demand without loading the entire document.

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDFrx Dynamic Loading Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DynamicPdfViewer(),
    );
  }
}

class DynamicPdfViewer extends StatefulWidget {
  const DynamicPdfViewer({super.key});

  @override
  State<DynamicPdfViewer> createState() => _DynamicPdfViewerState();
}

class _DynamicPdfViewerState extends State<DynamicPdfViewer> {
  PdfDocument? document;
  int currentPage = 1;
  bool isLoading = false;
  String? errorMessage;
  
  // Cache for page aspect ratios
  final Map<int, double> aspectRatioCache = {};
  
  @override
  void initState() {
    super.initState();
    _loadDocument();
  }
  
  Future<void> _loadDocument() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    try {
      // Open the document with progressive loading enabled
      document = await PdfDocument.openUri(
        Uri.parse('https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'),
        useProgressiveLoading: true,
      );
      
      // Load the first page immediately
      await _loadPage(1);
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }
  
  Future<void> _loadPage(int pageNumber) async {
    if (document == null) return;
    if (pageNumber < 1 || pageNumber > document!.pages.length) return;
    
    // Use the new dynamic loading API
    final success = await document!.loadPageDynamically(pageNumber);
    
    if (success) {
      // Cache the aspect ratio
      final page = document!.pages[pageNumber - 1];
      aspectRatioCache[pageNumber] = page.width / page.height;
      
      setState(() {
        currentPage = pageNumber;
      });
    }
  }
  
  Future<void> _preloadAdjacentPages() async {
    if (document == null) return;
    
    // Optionally preload adjacent pages for smoother navigation
    final pagesToLoad = <int>[];
    
    if (currentPage > 1) pagesToLoad.add(currentPage - 1);
    if (currentPage < document!.pages.length) pagesToLoad.add(currentPage + 1);
    
    if (pagesToLoad.isNotEmpty) {
      await document!.loadPagesDynamically(pagesToLoad);
    }
  }
  
  @override
  void dispose() {
    document?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Dynamic PDF Viewer - Page $currentPage'),
        actions: [
          if (document != null)
            Text(
              '${currentPage} / ${document!.pages.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildPdfView(),
          ),
          _buildNavigationBar(),
        ],
      ),
    );
  }
  
  Widget _buildPdfView() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDocument,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (document == null) {
      return const Center(child: Text('No document loaded'));
    }
    
    // Use the cached aspect ratio if available
    final aspectRatio = aspectRatioCache[currentPage] ?? 1.4142; // Default to A4 ratio
    
    return Center(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: PdfPageView(
          document: document!,
          pageNumber: currentPage,
          alignment: Alignment.center,
        ),
      ),
    );
  }
  
  Widget _buildNavigationBar() {
    if (document == null) return const SizedBox.shrink();
    
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: currentPage > 1
                ? () => _loadPage(1)
                : null,
            tooltip: 'First Page',
          ),
          IconButton(
            icon: const Icon(Icons.navigate_before),
            onPressed: currentPage > 1
                ? () => _loadPage(currentPage - 1)
                : null,
            tooltip: 'Previous Page',
          ),
          const SizedBox(width: 24),
          // Page number input
          SizedBox(
            width: 100,
            child: TextField(
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (value) {
                final pageNum = int.tryParse(value);
                if (pageNum != null) {
                  _loadPage(pageNum);
                }
              },
              controller: TextEditingController(text: currentPage.toString()),
            ),
          ),
          const SizedBox(width: 24),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            onPressed: currentPage < document!.pages.length
                ? () => _loadPage(currentPage + 1)
                : null,
            tooltip: 'Next Page',
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed: currentPage < document!.pages.length
                ? () => _loadPage(document!.pages.length)
                : null,
            tooltip: 'Last Page',
          ),
        ],
      ),
    );
  }
}

/// Alternative implementation using the high-level PdfPageViewDynamic widget
class SimpleDynamicPdfViewer extends StatefulWidget {
  const SimpleDynamicPdfViewer({super.key});

  @override
  State<SimpleDynamicPdfViewer> createState() => _SimpleDynamicPdfViewerState();
}

class _SimpleDynamicPdfViewerState extends State<SimpleDynamicPdfViewer> {
  int currentPage = 1;
  final int totalPages = 10; // You would get this from the document
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simple Dynamic PDF Viewer - Page $currentPage'),
      ),
      body: Column(
        children: [
          Expanded(
            // This widget handles all the complexity internally
            child: PdfPageViewDynamic.uri(
              Uri.parse('https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'),
              pageNumber: currentPage,
              preferRangeAccess: true,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.navigate_before),
                onPressed: currentPage > 1
                    ? () => setState(() => currentPage--)
                    : null,
              ),
              Text('Page $currentPage'),
              IconButton(
                icon: const Icon(Icons.navigate_next),
                onPressed: () => setState(() => currentPage++),
              ),
            ],
          ),
        ],
      ),
    );
  }
}