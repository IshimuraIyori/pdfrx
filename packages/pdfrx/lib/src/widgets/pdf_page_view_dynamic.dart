// packages/pdfrx/lib/src/widgets/pdf_page_view_dynamic.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../pdfrx.dart';

/// A widget that displays PDF pages dynamically with correct aspect ratios.
/// 
/// This widget uses the new dynamic page loading API to load only the
/// requested page, ensuring correct aspect ratio for each page without
/// loading unnecessary pages.
/// 
/// The document is opened once and kept in memory, but pages are loaded
/// on-demand as they are requested.
/// 
/// Example:
/// ```dart
/// PdfPageViewDynamic.uri(
///   Uri.parse('https://example.com/document.pdf'),
///   pageNumber: currentPage,  // Can be changed dynamically
/// )
/// ```
class PdfPageViewDynamic extends StatefulWidget {
  /// The PDF document reference.
  final PdfDocumentRef documentRef;

  /// The page number to display (1-based indexing).
  final int pageNumber;

  /// Maximum DPI for rendering the page.
  final double maximumDpi;

  /// Alignment of the page within the widget bounds.
  final Alignment alignment;

  /// Background color of the page view.
  final Color? backgroundColor;

  /// Fallback aspect ratio before page dimensions are known.
  final double fallbackAspectRatio;

  /// Creates a PdfPageViewDynamic widget with a document reference.
  const PdfPageViewDynamic.documentRef({
    super.key,
    required this.documentRef,
    required this.pageNumber,
    this.maximumDpi = 300,
    this.alignment = Alignment.center,
    this.backgroundColor,
    this.fallbackAspectRatio = 1 / 1.41421356,
  });

  /// Creates a PdfPageViewDynamic widget from a URI.
  factory PdfPageViewDynamic.uri(
    Uri uri, {
    Key? key,
    required int pageNumber,
    double maximumDpi = 300,
    Alignment alignment = Alignment.center,
    Color? backgroundColor,
    double fallbackAspectRatio = 1 / 1.41421356,
    bool preferRangeAccess = true,
    Map<String, String>? headers,
    bool withCredentials = false,
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
  }) {
    return PdfPageViewDynamic.documentRef(
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
    );
  }

  /// Creates a PdfPageViewDynamic widget from a file.
  factory PdfPageViewDynamic.file(
    String filePath, {
    Key? key,
    required int pageNumber,
    double maximumDpi = 300,
    Alignment alignment = Alignment.center,
    Color? backgroundColor,
    double fallbackAspectRatio = 1 / 1.41421356,
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
  }) {
    return PdfPageViewDynamic.documentRef(
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
    );
  }

  /// Creates a PdfPageViewDynamic widget from an asset.
  factory PdfPageViewDynamic.asset(
    String assetName, {
    Key? key,
    required int pageNumber,
    double maximumDpi = 300,
    Alignment alignment = Alignment.center,
    Color? backgroundColor,
    double fallbackAspectRatio = 1 / 1.41421356,
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
  }) {
    return PdfPageViewDynamic.documentRef(
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
    );
  }

  @override
  State<PdfPageViewDynamic> createState() => _PdfPageViewDynamicState();
}

class _PdfPageViewDynamicState extends State<PdfPageViewDynamic> {
  PdfDocument? _document;
  final Map<int, double> _aspectRatioCache = {};
  bool _isLoadingPage = false;
  int? _currentLoadingPage;

  @override
  void didUpdateWidget(PdfPageViewDynamic oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If page changed, ensure it's loaded
    if (oldWidget.pageNumber != widget.pageNumber && _document != null) {
      _ensurePageLoaded();
    }
  }

  Future<void> _ensurePageLoaded() async {
    if (_document == null) return;
    if (_isLoadingPage && _currentLoadingPage == widget.pageNumber) return;
    
    final pageNumber = widget.pageNumber;
    
    // Check cache first
    if (_aspectRatioCache.containsKey(pageNumber)) {
      return;
    }
    
    setState(() {
      _isLoadingPage = true;
      _currentLoadingPage = pageNumber;
    });
    
    try {
      // Use the new dynamic loading API
      final success = await _document!.loadPage(pageNumber);
      
      if (success && mounted) {
        final page = _document!.pages[pageNumber - 1];
        final aspectRatio = page.width / page.height;
        
        setState(() {
          _aspectRatioCache[pageNumber] = aspectRatio;
          _isLoadingPage = false;
          _currentLoadingPage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPage = false;
          _currentLoadingPage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PdfDocumentViewBuilder(
      documentRef: widget.documentRef,
      builder: (context, document) {
        if (document == null) {
          return _buildPlaceholder();
        }
        
        // Store document reference
        _document ??= document;
        
        // Ensure current page is loaded
        if (!_aspectRatioCache.containsKey(widget.pageNumber)) {
          scheduleMicrotask(_ensurePageLoaded);
        }
        
        // Get page
        final pageIndex = (widget.pageNumber - 1).clamp(0, document.pages.length - 1);
        final page = document.pages[pageIndex];
        
        return LayoutBuilder(
          builder: (context, constraints) {
            // Use cached aspect ratio or fallback
            final aspectRatio = _aspectRatioCache[widget.pageNumber] ?? 
                                (page.isLoaded 
                                    ? page.width / page.height 
                                    : widget.fallbackAspectRatio);
            
            final width = constraints.maxWidth.isFinite 
                ? constraints.maxWidth 
                : 200.0;
            final height = width / aspectRatio;
            
            return SizedBox(
              width: width,
              height: height,
              child: Stack(
                children: [
                  PdfPageView(
                    document: document,
                    pageNumber: pageIndex + 1,
                    maximumDpi: widget.maximumDpi,
                    alignment: widget.alignment,
                    backgroundColor: widget.backgroundColor,
                  ),
                  
                  // Loading overlay for this specific page
                  if (_isLoadingPage && _currentLoadingPage == widget.pageNumber)
                    Container(
                      color: Colors.black12,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite 
            ? constraints.maxWidth 
            : 200.0;
        final height = width / widget.fallbackAspectRatio;
        
        return Container(
          width: width,
          height: height,
          color: widget.backgroundColor ?? Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}