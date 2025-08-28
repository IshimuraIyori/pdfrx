// packages/pdfrx/lib/src/widgets/pdf_single_page_dynamic.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../pdfrx.dart';

/// A widget that displays a single page from a PDF document with dynamic page loading.
///
/// This widget is optimized for displaying any page with the correct aspect ratio
/// from the start, and efficiently switches between pages. It supports partial loading
/// through HTTP Range requests for network PDFs.
///
/// Unlike PdfSinglePage, this widget maintains a document reference and can
/// efficiently switch between pages without recreating the document.
///
/// Example:
/// ```dart
/// PdfSinglePageDynamic.uri(
///   Uri.parse('https://example.com/document.pdf'),
///   pageNumber: currentPage,  // Can be changed dynamically
///   preferRangeAccess: true,
/// )
/// ```
class PdfSinglePageDynamic extends StatefulWidget {
  /// The PDF document reference to display.
  final PdfDocumentRef documentRef;

  /// The page number to display (1-based indexing).
  final int pageNumber;

  /// Maximum DPI for rendering the page.
  final double maximumDpi;

  /// Alignment of the page within the widget bounds.
  final Alignment alignment;

  /// Background color of the page view.
  final Color? backgroundColor;

  /// Fallback aspect ratio to use before the page dimensions are loaded.
  /// Defaults to A4 portrait ratio (1/√2 ≈ 0.707).
  final double fallbackAspectRatio;

  /// Whether to preload adjacent pages for faster navigation.
  final bool preloadAdjacentPages;

  /// Number of pages to preload in each direction.
  final int preloadPageCount;

  /// Creates a PdfSinglePageDynamic widget with a document reference.
  const PdfSinglePageDynamic.documentRef({
    super.key,
    required this.documentRef,
    required this.pageNumber,
    this.maximumDpi = 300,
    this.alignment = Alignment.center,
    this.backgroundColor,
    this.fallbackAspectRatio = 1 / 1.41421356,
    this.preloadAdjacentPages = true,
    this.preloadPageCount = 2,
  });

  /// Creates a PdfSinglePageDynamic widget that loads a PDF from an asset.
  factory PdfSinglePageDynamic.asset(
    String assetName, {
    Key? key,
    required int pageNumber,
    double maximumDpi = 300,
    Alignment alignment = Alignment.center,
    Color? backgroundColor,
    double fallbackAspectRatio = 1 / 1.41421356,
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    bool preloadAdjacentPages = true,
    int preloadPageCount = 2,
  }) {
    return PdfSinglePageDynamic.documentRef(
      key: key,
      documentRef: PdfDocumentRefAsset(
        assetName,
        useProgressiveLoading: true,
        passwordProvider: passwordProvider,
        firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
      ),
      pageNumber: pageNumber,
      maximumDpi: maximumDpi,
      alignment: alignment,
      backgroundColor: backgroundColor,
      fallbackAspectRatio: fallbackAspectRatio,
      preloadAdjacentPages: preloadAdjacentPages,
      preloadPageCount: preloadPageCount,
    );
  }

  /// Creates a PdfSinglePageDynamic widget that loads a PDF from a file.
  factory PdfSinglePageDynamic.file(
    String filePath, {
    Key? key,
    required int pageNumber,
    double maximumDpi = 300,
    Alignment alignment = Alignment.center,
    Color? backgroundColor,
    double fallbackAspectRatio = 1 / 1.41421356,
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    bool preloadAdjacentPages = true,
    int preloadPageCount = 2,
  }) {
    return PdfSinglePageDynamic.documentRef(
      key: key,
      documentRef: PdfDocumentRefFile(
        filePath,
        useProgressiveLoading: true,
        passwordProvider: passwordProvider,
        firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
      ),
      pageNumber: pageNumber,
      maximumDpi: maximumDpi,
      alignment: alignment,
      backgroundColor: backgroundColor,
      fallbackAspectRatio: fallbackAspectRatio,
      preloadAdjacentPages: preloadAdjacentPages,
      preloadPageCount: preloadPageCount,
    );
  }

  /// Creates a PdfSinglePageDynamic widget that loads a PDF from a URI.
  ///
  /// For network PDFs, this widget supports:
  /// - Progressive loading with dynamic page switching
  /// - HTTP Range requests for efficient partial downloads
  /// - Preloading adjacent pages for smoother navigation
  factory PdfSinglePageDynamic.uri(
    Uri uri, {
    Key? key,
    required int pageNumber,
    bool preferRangeAccess = true,
    Map<String, String>? headers,
    bool withCredentials = false,
    double maximumDpi = 300,
    Alignment alignment = Alignment.center,
    Color? backgroundColor,
    double fallbackAspectRatio = 1 / 1.41421356,
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    bool preloadAdjacentPages = true,
    int preloadPageCount = 2,
  }) {
    return PdfSinglePageDynamic.documentRef(
      key: key,
      documentRef: PdfDocumentRefUri(
        uri,
        useProgressiveLoading: true,
        preferRangeAccess: preferRangeAccess,
        headers: headers,
        withCredentials: withCredentials,
        passwordProvider: passwordProvider,
        firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
      ),
      pageNumber: pageNumber,
      maximumDpi: maximumDpi,
      alignment: alignment,
      backgroundColor: backgroundColor,
      fallbackAspectRatio: fallbackAspectRatio,
      preloadAdjacentPages: preloadAdjacentPages,
      preloadPageCount: preloadPageCount,
    );
  }

  /// Creates a PdfSinglePageDynamic widget that loads a PDF from memory.
  factory PdfSinglePageDynamic.data(
    Uint8List data, {
    Key? key,
    required int pageNumber,
    double maximumDpi = 300,
    Alignment alignment = Alignment.center,
    Color? backgroundColor,
    double fallbackAspectRatio = 1 / 1.41421356,
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    bool preloadAdjacentPages = true,
    int preloadPageCount = 2,
  }) {
    return PdfSinglePageDynamic.documentRef(
      key: key,
      documentRef: PdfDocumentRefData(
        data,
        sourceName: 'memory',
        useProgressiveLoading: true,
        passwordProvider: passwordProvider,
        firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
      ),
      pageNumber: pageNumber,
      maximumDpi: maximumDpi,
      alignment: alignment,
      backgroundColor: backgroundColor,
      fallbackAspectRatio: fallbackAspectRatio,
      preloadAdjacentPages: preloadAdjacentPages,
      preloadPageCount: preloadPageCount,
    );
  }

  @override
  State<PdfSinglePageDynamic> createState() => _PdfSinglePageDynamicState();
}

class _PdfSinglePageDynamicState extends State<PdfSinglePageDynamic> {
  final Map<int, PdfPageRenderCancellationToken> _cancellationTokens = {};
  final Map<int, double> _pageAspectRatios = {};
  PdfDocument? _document;
  int? _lastPageNumber;
  bool _isPreloading = false;

  @override
  void dispose() {
    for (final token in _cancellationTokens.values) {
      token.cancel();
    }
    _cancellationTokens.clear();
    super.dispose();
  }

  @override
  void didUpdateWidget(PdfSinglePageDynamic oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If page number changed, trigger preloading
    if (oldWidget.pageNumber != widget.pageNumber) {
      _preloadAdjacentPages();
    }
  }

  /// Ensures the page is loaded by rendering it at minimum resolution.
  /// This allows us to get the correct dimensions without a full render.
  Future<void> _ensurePageLoaded(PdfPage page, int pageNumber) async {
    if (page.isLoaded) {
      // Cache the aspect ratio
      _pageAspectRatios[pageNumber] = page.width / page.height;
      return;
    }

    // Cancel existing token for this page if any
    _cancellationTokens[pageNumber]?.cancel();

    final token = page.createCancellationToken();
    _cancellationTokens[pageNumber] = token;

    try {
      // Render at 1x1 to force load and get dimensions
      await page.render(fullWidth: 1, fullHeight: 1, cancellationToken: token);

      if (page.isLoaded) {
        // Cache the aspect ratio
        _pageAspectRatios[pageNumber] = page.width / page.height;
      }
    } catch (e) {
      // If rendering was cancelled or failed, we'll try again
      if (!mounted) return;
    } finally {
      _cancellationTokens.remove(pageNumber);
    }
  }

  /// Preload adjacent pages for smoother navigation
  Future<void> _preloadAdjacentPages() async {
    if (!widget.preloadAdjacentPages || _isPreloading || _document == null) {
      return;
    }

    _isPreloading = true;

    try {
      final currentPage = widget.pageNumber;
      final totalPages = _document!.pages.length;

      // Determine which pages to preload
      final pagesToPreload = <int>[];

      // Add pages before current page
      for (int i = 1; i <= widget.preloadPageCount; i++) {
        final pageNum = currentPage - i;
        if (pageNum >= 1 && pageNum <= totalPages) {
          pagesToPreload.add(pageNum);
        }
      }

      // Add pages after current page
      for (int i = 1; i <= widget.preloadPageCount; i++) {
        final pageNum = currentPage + i;
        if (pageNum >= 1 && pageNum <= totalPages) {
          pagesToPreload.add(pageNum);
        }
      }

      // Preload pages concurrently
      final futures = <Future>[];
      for (final pageNum in pagesToPreload) {
        final pageIndex = pageNum - 1;
        final page = _document!.pages[pageIndex];
        if (!page.isLoaded && !_pageAspectRatios.containsKey(pageNum)) {
          futures.add(_ensurePageLoaded(page, pageNum));
        }
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures, eagerError: false);
      }
    } finally {
      _isPreloading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PdfDocumentViewBuilder(
      documentRef: widget.documentRef,
      builder: (context, document) {
        if (document == null) {
          // Show loading placeholder with fallback aspect ratio
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 200.0;
              final height = width / widget.fallbackAspectRatio;

              return Container(
                width: width,
                height: height,
                color: widget.backgroundColor,
                child: const Center(child: CircularProgressIndicator()),
              );
            },
          );
        }

        // Store document reference
        _document = document;

        // Clamp page number to valid range
        final pageIndex = (widget.pageNumber - 1).clamp(0, document.pages.length - 1);
        final pageNumber = pageIndex + 1;
        final page = document.pages[pageIndex];

        // Ensure current page is loaded
        if (!page.isLoaded && !_pageAspectRatios.containsKey(pageNumber)) {
          scheduleMicrotask(() async {
            await _ensurePageLoaded(page, pageNumber);
            if (mounted) {
              setState(() {});
            }
          });
        }

        // Trigger preloading of adjacent pages
        if (_lastPageNumber != pageNumber) {
          _lastPageNumber = pageNumber;
          scheduleMicrotask(() => _preloadAdjacentPages());
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // Use cached aspect ratio if available, otherwise calculate from loaded page
            final aspectRatio =
                _pageAspectRatios[pageNumber] ??
                (page.isLoaded ? (page.width / page.height).clamp(0.01, 100.0) : widget.fallbackAspectRatio);

            // Calculate dimensions based on available width
            final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 200.0;
            final height = width / aspectRatio;

            // Use SizedBox to ensure proper dimensions
            return SizedBox(
              width: width,
              height: height,
              child: PdfPageView(
                document: document,
                pageNumber: pageNumber,
                maximumDpi: widget.maximumDpi,
                alignment: widget.alignment,
                backgroundColor: widget.backgroundColor,
              ),
            );
          },
        );
      },
    );
  }
}
