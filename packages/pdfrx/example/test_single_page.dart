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
      title: 'Single Page Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SinglePageTest(),
    );
  }
}

class SinglePageTest extends StatefulWidget {
  const SinglePageTest({super.key});

  @override
  State<SinglePageTest> createState() => _SinglePageTestState();
}

class _SinglePageTestState extends State<SinglePageTest> {
  int _currentPage = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page $_currentPage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: _currentPage > 1
                ? () => setState(() => _currentPage--)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => setState(() => _currentPage++),
          ),
        ],
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: PdfSinglePage.uri(
              Uri.parse('https://www.rfc-editor.org/rfc/pdfrfc/rfc6749.txt.pdf'),
              pageNumber: _currentPage,
              useProgressiveLoading: true,
              preferRangeAccess: true,
            ),
          ),
        ),
      ),
    );
  }
}