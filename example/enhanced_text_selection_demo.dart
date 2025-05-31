// Example demonstrating how to use the new enhanced text selection system

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enhanced Text Selection Demo',
      home: PdfViewerPage(),
    );
  }
}

class PdfViewerPage extends StatefulWidget {
  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final PdfViewerController _controller = PdfViewerController();
  PdfEnhancedTextSelectionManager? _selectionManager;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enhanced Text Selection Demo'),
        actions: [
          IconButton(
            icon: Icon(Icons.select_all),
            onPressed: () => _selectionManager?.selectAll(),
            tooltip: 'Select All',
          ),
          IconButton(
            icon: Icon(Icons.copy),
            onPressed: () => _selectionManager?.copySelectedText(),
            tooltip: 'Copy',
          ),
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () => _selectionManager?.clearSelection(),
            tooltip: 'Clear Selection',
          ),
        ],
      ),
      body: PdfViewer.asset(
        'assets/sample.pdf',
        controller: _controller,
        params: PdfViewerParams(
          // Enable enhanced text selection
          enableTextSelection: true,
          textSelectionMode: PdfTextSelectionMode.enhanced,
          
          // Callback when document loads
          onDocumentChanged: (document) {
            if (document != null) {
              _selectionManager = PdfEnhancedTextSelectionManager(
                document: document,
                onSelectionChange: (selection) {
                  print('Selection changed: ${selection.hasSelection}');
                },
              );
            }
          },
          
          // Other customization options
          backgroundColor: Colors.grey[300]!,
          margin: 8.0,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final selectedText = await _selectionManager?.getSelectedText() ?? '';
          if (selectedText.isNotEmpty) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Selected Text'),
                content: SelectableText(selectedText),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                  ),
                ],
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No text selected')),
            );
          }
        },
        child: Icon(Icons.text_snippet),
        tooltip: 'Show Selected Text',
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _selectionManager?.dispose();
    super.dispose();
  }
}

// Example of how to use the enhanced text selection programmatically
class ProgrammaticSelectionExample extends StatelessWidget {
  final PdfEnhancedTextSelectionManager selectionManager;

  const ProgrammaticSelectionExample({
    Key? key,
    required this.selectionManager,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            // Select all text in the document
            selectionManager.selectAll();
          },
          child: Text('Select All'),
        ),
        
        ElevatedButton(
          onPressed: () {
            // Clear all selections
            selectionManager.clearSelection();
          },
          child: Text('Clear Selection'),
        ),
        
        ElevatedButton(
          onPressed: () async {
            // Get selected text
            final selectedText = await selectionManager.getSelectedText();
            print('Selected: $selectedText');
          },
          child: Text('Get Selected Text'),
        ),
        
        ElevatedButton(
          onPressed: () {
            // Copy to clipboard
            selectionManager.copySelectedText();
          },
          child: Text('Copy Selection'),
        ),
      ],
    );
  }
}

// Example showing comparison between modes
class TextSelectionModeComparison extends StatefulWidget {
  @override
  _TextSelectionModeComparisonState createState() => _TextSelectionModeComparisonState();
}

class _TextSelectionModeComparisonState extends State<TextSelectionModeComparison> {
  PdfTextSelectionMode _mode = PdfTextSelectionMode.legacy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Text Selection Mode Comparison'),
        actions: [
          SegmentedButton<PdfTextSelectionMode>(
            segments: [
              ButtonSegment<PdfTextSelectionMode>(
                value: PdfTextSelectionMode.legacy,
                label: Text('Legacy'),
              ),
              ButtonSegment<PdfTextSelectionMode>(
                value: PdfTextSelectionMode.enhanced,
                label: Text('Enhanced'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (Set<PdfTextSelectionMode> newSelection) {
              setState(() {
                _mode = newSelection.first;
              });
            },
          ),
        ],
      ),
      body: PdfViewer.asset(
        'assets/sample.pdf',
        params: PdfViewerParams(
          enableTextSelection: true,
          textSelectionMode: _mode,
          backgroundColor: Colors.grey[300]!,
        ),
      ),
    );
  }
}