// packages/pdfrx_engine/lib/src/pdfrx_api_extension.dart

import 'dart:async';
import 'pdfrx_api.dart';

/// Extension methods for PdfDocument to enable dynamic page loading.
extension PdfDocumentDynamicLoader on PdfDocument {
  /// Load a specific page dynamically without loading other pages.
  /// 
  /// This method loads only the specified page, ensuring its correct dimensions
  /// are available. If the page is already loaded, this method returns immediately.
  /// 
  /// [pageNumber] is 1-based page number.
  /// 
  /// Returns true if the page was successfully loaded, false otherwise.
  Future<bool> loadPage(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > pages.length) {
      return false;
    }
    
    final pageIndex = pageNumber - 1;
    final page = pages[pageIndex];
    
    // If already loaded, return immediately
    if (page.isLoaded) {
      return true;
    }
    
    // Force load the page by rendering it at minimum size
    try {
      final token = page.createCancellationToken();
      try {
        await page.render(
          fullWidth: 1,
          fullHeight: 1,
          cancellationToken: token,
        );
        return page.isLoaded;
      } finally {
        // Token doesn't have dispose method, it will be cleaned up automatically
      }
    } catch (e) {
      return false;
    }
  }
  
  /// Load multiple pages dynamically.
  /// 
  /// This method loads multiple pages specified in [pageNumbers].
  /// Pages that are already loaded are skipped.
  /// 
  /// Returns a map of page numbers to their load success status.
  Future<Map<int, bool>> loadPages(List<int> pageNumbers) async {
    final results = <int, bool>{};
    
    // Load pages concurrently
    final futures = <Future>[];
    for (final pageNumber in pageNumbers) {
      futures.add(
        loadPage(pageNumber).then((success) {
          results[pageNumber] = success;
        }),
      );
    }
    
    await Future.wait(futures, eagerError: false);
    return results;
  }
  
  /// Get the aspect ratio of a specific page.
  /// 
  /// If the page is not loaded, this method will load it first.
  /// Returns null if the page cannot be loaded.
  Future<double?> getPageAspectRatio(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > pages.length) {
      return null;
    }
    
    final success = await loadPage(pageNumber);
    if (!success) {
      return null;
    }
    
    final page = pages[pageNumber - 1];
    return page.width / page.height;
  }
  
  /// Ensure a page is loaded and get its dimensions.
  /// 
  /// Returns a record containing width, height, and aspect ratio.
  /// Returns null if the page cannot be loaded.
  Future<({double width, double height, double aspectRatio})?> getPageDimensions(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > pages.length) {
      return null;
    }
    
    final success = await loadPage(pageNumber);
    if (!success) {
      return null;
    }
    
    final page = pages[pageNumber - 1];
    return (
      width: page.width,
      height: page.height,
      aspectRatio: page.width / page.height,
    );
  }
}