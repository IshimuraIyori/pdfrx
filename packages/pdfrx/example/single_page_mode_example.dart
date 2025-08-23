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
      title: 'Single Page Mode Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SinglePageViewer(),
    );
  }
}

class SinglePageViewer extends StatefulWidget {
  const SinglePageViewer({super.key});

  @override
  State<SinglePageViewer> createState() => _SinglePageViewerState();
}

class _SinglePageViewerState extends State<SinglePageViewer> {
  final PdfViewerController _controller = PdfViewerController();
  bool _enableSinglePageMode = true;
  int _currentPageNumber = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Single Page Mode Example'),
        actions: [
          // Toggle single page mode
          Switch(
            value: _enableSinglePageMode,
            onChanged: (value) {
              setState(() {
                _enableSinglePageMode = value;
              });
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Page navigation controls
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.navigate_before),
                  onPressed: _currentPageNumber > 1
                      ? () {
                          _controller.goToPage(
                            pageNumber: _currentPageNumber - 1,
                          );
                        }
                      : null,
                ),
                const SizedBox(width: 16),
                Text(
                  'Page $_currentPageNumber',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.navigate_next),
                  onPressed: () {
                    _controller.goToPage(
                      pageNumber: _currentPageNumber + 1,
                    );
                  },
                ),
              ],
            ),
          ),
          // PDF Viewer
          Expanded(
            child: PdfViewer.asset(
              'assets/sample.pdf', // Replace with your PDF asset path
              controller: _controller,
              params: PdfViewerParams(
                enableSinglePageMode: _enableSinglePageMode,
                // When single page mode is enabled, only the current page is loaded
                // with its correct aspect ratio, not using the first page's ratio
                onPageChanged: (pageNumber) {
                  setState(() {
                    _currentPageNumber = pageNumber ?? 1;
                  });
                },
                // Disable prefetch in single page mode
                horizontalCacheExtent: _enableSinglePageMode ? 0.0 : 1.0,
                verticalCacheExtent: _enableSinglePageMode ? 0.0 : 1.0,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              _controller.zoomUp();
            },
            tooltip: 'Zoom In',
            child: const Icon(Icons.zoom_in),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () {
              _controller.zoomDown();
            },
            tooltip: 'Zoom Out',
            child: const Icon(Icons.zoom_out),
          ),
        ],
      ),
    );
  }
}
