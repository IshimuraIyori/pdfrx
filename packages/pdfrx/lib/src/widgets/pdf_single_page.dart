// packages/pdfrx/lib/src/widgets/pdf_single_page.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../pdfrx.dart';

/// A widget that displays a single page from a PDF document.
///
/// This widget is optimized for displaying a specific page with the correct aspect ratio
/// from the start, without needing to load other pages. It supports partial loading
/// through HTTP Range requests for network PDFs.
///
/// Example:
/// ```dart
/// PdfSinglePage.uri(
///   Uri.parse('https://example.com/document.pdf'),
///   pageNumber: 5,
///   preferRangeAccess: true,
/// )
/// ```
class PdfSinglePage extends StatefulWidget {
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

  /// Creates a PdfSinglePage widget with a document reference.
  const PdfSinglePage.documentRef({
    super.key,
    required this.documentRef,
    required this.pageNumber,
    this.maximumDpi = 300,
    this.alignment = Alignment.center,
    this.backgroundColor,
    this.fallbackAspectRatio = 1 / 1.41421356,
  });

  /// Creates a PdfSinglePage widget that loads a PDF from an asset.
  factory PdfSinglePage.asset(
    String assetName, {
    Key? key,
    required int pageNumber,
    bool useProgressiveLoading = true,
    double maximumDpi = 300,
    Alignment alignment = Alignment.center,
    Color? backgroundColor,
    double fallbackAspectRatio = 1 / 1.41421356,
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
  }) {
    return PdfSinglePage.documentRef(
      key: key,
      documentRef: PdfDocumentRefAsset(
        assetName,
        useProgressiveLoading: useProgressiveLoading,
        progressiveLoadingTargetPage: pageNumber,
        passwordProvider: passwordProvider,
        firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
      ),
      pageNumber: pageNumber,
      maximumDpi: maximumDpi,
      alignment: alignment,
      backgroundColor: backgroundColor,
      fallbackAspectRatio: fallbackAspectRatio,
    );
  }

  /// Creates a PdfSinglePage widget that loads a PDF from a file.
  factory PdfSinglePage.file(
    String filePath, {
    Key? key,
    required int pageNumber,
    bool useProgressiveLoading = true,
    double maximumDpi = 300,
    Alignment alignment = Alignment.center,
    Color? backgroundColor,
    double fallbackAspectRatio = 1 / 1.41421356,
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
  }) {
    return PdfSinglePage.documentRef(
      key: key,
      documentRef: PdfDocumentRefFile(
        filePath,
        useProgressiveLoading: useProgressiveLoading,
        progressiveLoadingTargetPage: pageNumber,
        passwordProvider: passwordProvider,
        firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
      ),
      pageNumber: pageNumber,
      maximumDpi: maximumDpi,
      alignment: alignment,
      backgroundColor: backgroundColor,
      fallbackAspectRatio: fallbackAspectRatio,
    );
  }

  /// Creates a PdfSinglePage widget that loads a PDF from a URI.
  ///
  /// For network PDFs, this widget supports:
  /// - Progressive loading (loading only the target page initially)
  /// - HTTP Range requests (partial content download)
  factory PdfSinglePage.uri(
    Uri uri, {
    Key? key,
    required int pageNumber,
    bool useProgressiveLoading = true,
    bool preferRangeAccess = true,
    Map<String, String>? headers,
    bool withCredentials = false,
    double maximumDpi = 300,
    Alignment alignment = Alignment.center,
    Color? backgroundColor,
    double fallbackAspectRatio = 1 / 1.41421356,
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
  }) {
    return PdfSinglePage.documentRef(
      key: key,
      documentRef: PdfDocumentRefUri(
        uri,
        useProgressiveLoading: useProgressiveLoading,
        progressiveLoadingTargetPage: pageNumber,
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
    );
  }

  /// Creates a PdfSinglePage widget that loads a PDF from memory.
  factory PdfSinglePage.data(
    Uint8List data, {
    Key? key,
    required int pageNumber,
    bool useProgressiveLoading = true,
    double maximumDpi = 300,
    Alignment alignment = Alignment.center,
    Color? backgroundColor,
    double fallbackAspectRatio = 1 / 1.41421356,
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
  }) {
    return PdfSinglePage.documentRef(
      key: key,
      documentRef: PdfDocumentRefData(
        data,
        sourceName: 'memory',
        useProgressiveLoading: useProgressiveLoading,
        progressiveLoadingTargetPage: pageNumber,
        passwordProvider: passwordProvider,
        firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
      ),
      pageNumber: pageNumber,
      maximumDpi: maximumDpi,
      alignment: alignment,
      backgroundColor: backgroundColor,
      fallbackAspectRatio: fallbackAspectRatio,
    );
  }

  @override
  State<PdfSinglePage> createState() => _PdfSinglePageState();
}

class _PdfSinglePageState extends State<PdfSinglePage> {
  bool _kickedEnsure = false;
  PdfPageRenderCancellationToken? _cancellationToken;

  @override
  void dispose() {
    _cancellationToken?.cancel();
    super.dispose();
  }

  /// Ensures the page is loaded by rendering it at minimum resolution.
  /// This allows us to get the correct dimensions without a full render.
  Future<void> _ensurePageLoaded(PdfPage page) async {
    if (page.isLoaded) return;

    _cancellationToken?.cancel();
    _cancellationToken = page.createCancellationToken();

    try {
      // Render at 1x1 to force load and get dimensions
      await page.render(fullWidth: 1, fullHeight: 1, cancellationToken: _cancellationToken);
    } catch (e) {
      // If rendering was cancelled or failed, we'll try again
      if (!mounted) return;
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

        // Clamp page number to valid range
        final pageIndex = (widget.pageNumber - 1).clamp(0, document.pages.length - 1);
        final page = document.pages[pageIndex];

        // Kick off dimension loading on first build if needed
        if (!_kickedEnsure && !page.isLoaded) {
          _kickedEnsure = true;
          scheduleMicrotask(() async {
            await _ensurePageLoaded(page);
            if (mounted) {
              setState(() {});
            }
          });
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // Calculate aspect ratio from loaded page or use fallback
            final aspectRatio =
                page.isLoaded ? (page.width / page.height).clamp(0.01, 100.0) : widget.fallbackAspectRatio;

            // Calculate dimensions based on available width
            final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 200.0;
            final height = width / aspectRatio;

            // Use SizedBox to ensure proper dimensions
            return SizedBox(
              width: width,
              height: height,
              child: PdfPageView(
                document: document,
                pageNumber: pageIndex + 1, // PdfPageView uses 1-based indexing
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
