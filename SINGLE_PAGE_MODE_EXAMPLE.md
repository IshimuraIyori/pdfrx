# Single Page Mode Example

This example demonstrates how to use the `progressiveLoadingTargetPage` parameter to display a single page with its correct aspect ratio when using progressive loading.

## Problem

When using progressive loading with `useProgressiveLoading: true`, PDFium normally loads only the first page initially and assumes all other pages have the same aspect ratio as the first page. This can cause display issues when jumping directly to a different page that has a different aspect ratio.

## Solution

The new `progressiveLoadingTargetPage` parameter allows you to specify which page should be loaded initially to get its correct aspect ratio. This is particularly useful when implementing a single-page viewer that starts at a specific page.

## Usage Examples

### Example 1: Display a specific page with correct aspect ratio

```dart
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class SinglePagePdfViewer extends StatelessWidget {
  final String assetPath;
  final int targetPage;

  const SinglePagePdfViewer({
    Key? key,
    required this.assetPath,
    required this.targetPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PdfViewer.asset(
      assetPath,
      initialPageNumber: targetPage,
      useProgressiveLoading: true,
      progressiveLoadingTargetPage: targetPage, // Load this specific page to get correct aspect ratio
      params: PdfViewerParams(
        layoutPages: (pages, params) {
          // Display only the target page
          final page = pages[targetPage - 1];
          return [
            PdfPageLayout(
              page: page,
              layout: Rect.fromLTWH(0, 0, page.width, page.height),
            ),
          ];
        },
      ),
    );
  }
}
```

### Example 2: Using with different PDF sources

```dart
// From file
PdfViewer.file(
  '/path/to/document.pdf',
  initialPageNumber: 5,
  useProgressiveLoading: true,
  progressiveLoadingTargetPage: 5, // Load page 5 for correct aspect ratio
);

// From URI
PdfViewer.uri(
  Uri.parse('https://example.com/document.pdf'),
  initialPageNumber: 10,
  useProgressiveLoading: true,
  progressiveLoadingTargetPage: 10, // Load page 10 for correct aspect ratio
);

// From data
PdfViewer.data(
  pdfBytes,
  sourceName: 'document.pdf',
  initialPageNumber: 3,
  useProgressiveLoading: true,
  progressiveLoadingTargetPage: 3, // Load page 3 for correct aspect ratio
);

// From custom source
PdfViewer.custom(
  fileSize: fileSize,
  read: customReadFunction,
  sourceName: 'custom.pdf',
  initialPageNumber: 7,
  useProgressiveLoading: true,
  progressiveLoadingTargetPage: 7, // Load page 7 for correct aspect ratio
);
```

### Example 3: Auto-setting target page based on initial page

When `progressiveLoadingTargetPage` is not specified, it defaults to `initialPageNumber` when `useProgressiveLoading` is `true`:

```dart
// These two are equivalent:
PdfViewer.asset(
  'assets/document.pdf',
  initialPageNumber: 5,
  useProgressiveLoading: true,
  progressiveLoadingTargetPage: 5,
);

PdfViewer.asset(
  'assets/document.pdf',
  initialPageNumber: 5,
  useProgressiveLoading: true,
  // progressiveLoadingTargetPage automatically set to 5
);
```

## Benefits

1. **Correct Aspect Ratio**: The target page is displayed with its actual aspect ratio, not the first page's ratio
2. **Faster Loading**: Only the required page is loaded initially, improving performance
3. **Better User Experience**: Users see the correct page layout immediately without distortion

## Notes

- This feature only works when `useProgressiveLoading` is set to `true`
- If `progressiveLoadingTargetPage` is not specified, it defaults to `initialPageNumber` when progressive loading is enabled
- The page number is 1-based (first page is 1, not 0)