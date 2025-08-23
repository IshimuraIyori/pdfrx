# Single Page Mode Feature

## Overview

The Single Page Mode feature has been added to pdfrx to address the issue where pages with different aspect ratios are displayed incorrectly when using progressive loading. This mode ensures that each page is displayed with its correct aspect ratio by loading and displaying only one page at a time.

## Problem It Solves

Previously, when `useProgressiveLoading` was enabled (default behavior), the viewer would assume all pages have the same aspect ratio as the first page. This caused issues when a PDF contained pages with different sizes or orientations (e.g., mixed portrait/landscape pages, or A4/A3 mixed documents).

## How to Use

### Basic Usage

Enable single page mode by setting `enableSinglePageMode` to `true` in `PdfViewerParams`:

```dart
PdfViewer.asset(
  'assets/document.pdf',
  params: PdfViewerParams(
    enableSinglePageMode: true,
  ),
)
```

### With Page Navigation

You can programmatically navigate between pages using the controller:

```dart
final controller = PdfViewerController();

// Navigate to next page
controller.goToPage(pageNumber: currentPage + 1);

// Navigate to previous page
controller.goToPage(pageNumber: currentPage - 1);

// Navigate to specific page
controller.goToPage(pageNumber: 5);
```

### Advanced Configuration

You can also specify a specific page to display:

```dart
PdfViewerParams(
  enableSinglePageMode: true,
  singlePageNumber: 3, // Display page 3
)
```

## Key Features

1. **Correct Aspect Ratio**: Each page is displayed with its actual aspect ratio, not the first page's ratio
2. **Memory Efficient**: Only the current page is loaded and rendered
3. **No Prefetching**: Adjacent pages are not preloaded, reducing memory usage
4. **Automatic Relayout**: When switching pages, the layout automatically adjusts to the new page size

## Performance Considerations

- **Pros**:
  - Lower memory usage (only one page in memory)
  - Correct display of mixed-size documents
  - No layout recalculation issues from progressive loading

- **Cons**:
  - Page transitions might be slightly slower (no prefetch)
  - Scrolling through multiple pages is not possible

## Example Implementation

See `single_page_mode_example.dart` for a complete working example that demonstrates:
- Toggling between single page and multi-page modes
- Page navigation controls
- Zoom controls
- Page change callbacks

## When to Use

Use Single Page Mode when:
- Your PDF contains pages with different sizes or orientations
- You want a presentation-style viewer (one page at a time)
- Memory usage is a concern
- You need accurate aspect ratios for each page

Continue using the default multi-page mode when:
- All pages have the same size
- Users need to scroll through multiple pages
- Quick page transitions are important