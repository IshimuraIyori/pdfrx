import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Single Page Progressive Loading Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SinglePageProgressiveDemo(),
    );
  }
}

class SinglePageProgressiveDemo extends StatefulWidget {
  @override
  State<SinglePageProgressiveDemo> createState() => _SinglePageProgressiveDemoState();
}

class _SinglePageProgressiveDemoState extends State<SinglePageProgressiveDemo> {
  int currentPage = 1;
  PdfDocument? document;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Single Page Progressive Loading'),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: currentPage > 1
                ? () {
                    setState(() {
                      currentPage--;
                    });
                  }
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                'Page $currentPage',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: document != null && currentPage < document!.pages.length
                ? () {
                    setState(() {
                      currentPage++;
                    });
                  }
                : null,
          ),
        ],
      ),
      body: PdfDocumentViewBuilder.uri(
        Uri.parse('https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'),
        useProgressiveLoading: true,
        builder: (context, doc) {
          document = doc;
          if (doc == null) {
            return Center(child: CircularProgressIndicator());
          }
          
          return Column(
            children: [
              // Display single page with progressive loading
              Expanded(
                child: Center(
                  child: Container(
                    margin: EdgeInsets.all(16),
                    child: PdfPageView(
                      key: ValueKey('page_$currentPage'),
                      document: doc,
                      pageNumber: currentPage,
                      useProgressiveLoading: true,
                      alignment: Alignment.center,
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
                    ),
                  ),
                ),
              ),
              // Info panel
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Column(
                  children: [
                    Text(
                      'Progressive Loading Enabled',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'The page renders progressively:\n'
                      '1. Shows correct aspect ratio immediately\n'
                      '2. Loads low quality preview first\n'
                      '3. Then loads full quality image',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}