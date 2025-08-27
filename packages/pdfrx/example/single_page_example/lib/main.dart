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
      title: 'PdfSinglePage Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SinglePageExampleScreen(),
    );
  }
}

class SinglePageExampleScreen extends StatefulWidget {
  const SinglePageExampleScreen({super.key});

  @override
  State<SinglePageExampleScreen> createState() => _SinglePageExampleScreenState();
}

class _SinglePageExampleScreenState extends State<SinglePageExampleScreen> {
  int _currentPage = 1;
  final _pageController = TextEditingController(text: '1');

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PdfSinglePage Example'),
        actions: [
          // Page navigation controls
          IconButton(
            onPressed: _currentPage > 1
                ? () => setState(() {
                      _currentPage--;
                      _pageController.text = _currentPage.toString();
                    })
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          SizedBox(
            width: 60,
            child: TextField(
              controller: _pageController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              onSubmitted: (value) {
                final page = int.tryParse(value);
                if (page != null && page > 0) {
                  setState(() {
                    _currentPage = page;
                  });
                }
              },
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white),
            ),
          ),
          IconButton(
            onPressed: () => setState(() {
              _currentPage++;
              _pageController.text = _currentPage.toString();
            }),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar for different examples
          DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Network PDF'),
                    Tab(text: 'Asset PDF'),
                    Tab(text: 'Large Network PDF'),
                  ],
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 150,
                  child: TabBarView(
                    children: [
                      // Example 1: Network PDF with HTTP Range support
                      _buildExample(
                        'Network PDF (HTTP Range)',
                        PdfSinglePage.uri(
                          Uri.parse('https://www.rfc-editor.org/rfc/pdfrfc/rfc6749.txt.pdf'),
                          pageNumber: _currentPage,
                          useProgressiveLoading: true,
                          preferRangeAccess: true,
                        ),
                      ),
                      
                      // Example 2: Asset PDF
                      _buildExample(
                        'Asset PDF',
                        PdfSinglePage.asset(
                          'assets/sample.pdf',
                          pageNumber: _currentPage,
                          useProgressiveLoading: true,
                        ),
                      ),
                      
                      // Example 3: Large PDF with specific page
                      _buildExample(
                        'Large PDF (Page 5)',
                        PdfSinglePage.uri(
                          Uri.parse('https://www.pdf995.com/samples/pdf.pdf'),
                          pageNumber: 5,
                          useProgressiveLoading: true,
                          preferRangeAccess: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExample(String title, Widget pdfWidget) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: pdfWidget,
            ),
          ),
        ),
      ],
    );
  }
}