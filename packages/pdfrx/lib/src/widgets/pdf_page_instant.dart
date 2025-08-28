// packages/pdfrx/lib/src/widgets/pdf_page_instant.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../pdfrx.dart';

/// A widget that instantly displays a single PDF page with correct aspect ratio.
///
/// This widget is designed to:
/// - Load ONLY the specified page (no other pages are touched)
/// - Get the correct aspect ratio immediately for that specific page
/// - Use HTTP Range requests to fetch only the necessary data for network PDFs
/// - No preloading, no adjacent pages, just the page you want
///
/// Example:
/// ```dart
/// PdfPageInstant.uri(
///   Uri.parse('https://example.com/document.pdf'),
///   pageNumber: 42,  // Only page 42 is loaded
/// )
/// ```
class PdfPageInstant extends StatefulWidget {
  /// The page number to display (1-based indexing).
  final int pageNumber;

  /// The PDF URI to load from.
  final Uri? uri;

  /// The PDF file path to load from.
  final String? filePath;

  /// The PDF asset name to load from.
  final String? assetName;

  /// The PDF data to load from.
  final Uint8List? data;

  /// Maximum DPI for rendering the page.
  final double maximumDpi;

  /// Alignment of the page within the widget bounds.
  final Alignment alignment;

  /// Background color of the page view.
  final Color? backgroundColor;

  /// Fallback aspect ratio before page loads (A4 portrait by default).
  final double fallbackAspectRatio;

  /// Whether to use HTTP Range requests for network PDFs.
  final bool preferRangeAccess;

  /// HTTP headers for network requests.
  final Map<String, String>? headers;

  /// Whether to send credentials with network requests.
  final bool withCredentials;

  /// Password provider for protected PDFs.
  final PdfPasswordProvider? passwordProvider;

  /// Whether to try empty password first.
  final bool firstAttemptByEmptyPassword;

  const PdfPageInstant._({
    super.key,
    required this.pageNumber,
    this.uri,
    this.filePath,
    this.assetName,
    this.data,
    this.maximumDpi = 300,
    this.alignment = Alignment.center,
    this.backgroundColor,
    this.fallbackAspectRatio = 1 / 1.41421356,
    this.preferRangeAccess = true,
    this.headers,
    this.withCredentials = false,
    this.passwordProvider,
    this.firstAttemptByEmptyPassword = true,
  }) : assert(
         (uri != null) ^ (filePath != null) ^ (assetName != null) ^ (data != null),
         'Exactly one source must be provided',
       );

  /// Creates a widget that loads a single page from a network PDF.
  factory PdfPageInstant.uri(
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
    return PdfPageInstant._(
      key: key,
      pageNumber: pageNumber,
      uri: uri,
      maximumDpi: maximumDpi,
      alignment: alignment,
      backgroundColor: backgroundColor,
      fallbackAspectRatio: fallbackAspectRatio,
      preferRangeAccess: preferRangeAccess,
      headers: headers,
      withCredentials: withCredentials,
      passwordProvider: passwordProvider,
      firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
    );
  }

  /// Creates a widget that loads a single page from a file.
  factory PdfPageInstant.file(
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
    return PdfPageInstant._(
      key: key,
      pageNumber: pageNumber,
      filePath: filePath,
      maximumDpi: maximumDpi,
      alignment: alignment,
      backgroundColor: backgroundColor,
      fallbackAspectRatio: fallbackAspectRatio,
      passwordProvider: passwordProvider,
      firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
    );
  }

  /// Creates a widget that loads a single page from an asset.
  factory PdfPageInstant.asset(
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
    return PdfPageInstant._(
      key: key,
      pageNumber: pageNumber,
      assetName: assetName,
      maximumDpi: maximumDpi,
      alignment: alignment,
      backgroundColor: backgroundColor,
      fallbackAspectRatio: fallbackAspectRatio,
      passwordProvider: passwordProvider,
      firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
    );
  }

  /// Creates a widget that loads a single page from memory.
  factory PdfPageInstant.data(
    Uint8List data, {
    Key? key,
    required int pageNumber,
    double maximumDpi = 300,
    Alignment alignment = Alignment.center,
    Color? backgroundColor,
    double fallbackAspectRatio = 1 / 1.41421356,
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
  }) {
    return PdfPageInstant._(
      key: key,
      pageNumber: pageNumber,
      data: data,
      maximumDpi: maximumDpi,
      alignment: alignment,
      backgroundColor: backgroundColor,
      fallbackAspectRatio: fallbackAspectRatio,
      passwordProvider: passwordProvider,
      firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
    );
  }

  @override
  State<PdfPageInstant> createState() => _PdfPageInstantState();
}

class _PdfPageInstantState extends State<PdfPageInstant> {
  PdfDocumentRef? _documentRef;
  PdfPageRenderCancellationToken? _cancellationToken;
  double? _aspectRatio;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _createDocumentRef();
  }

  @override
  void didUpdateWidget(PdfPageInstant oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If source or page changed, recreate document reference
    if (oldWidget.uri != widget.uri ||
        oldWidget.filePath != widget.filePath ||
        oldWidget.assetName != widget.assetName ||
        oldWidget.data != widget.data ||
        oldWidget.pageNumber != widget.pageNumber) {
      _resetState();
      _createDocumentRef();
    }
  }

  void _resetState() {
    _cancellationToken?.cancel();
    _cancellationToken = null;
    _aspectRatio = null;
    _isLoading = false;
    _errorMessage = null;
    _documentRef = null;
  }

  void _createDocumentRef() {
    if (widget.uri != null) {
      _documentRef = PdfDocumentRefUri(
        widget.uri!,
        useProgressiveLoading: true,
        // Target the specific page for progressive loading
        progressiveLoadingTargetPage: widget.pageNumber,
        preferRangeAccess: widget.preferRangeAccess,
        headers: widget.headers,
        withCredentials: widget.withCredentials,
        passwordProvider: widget.passwordProvider,
        firstAttemptByEmptyPassword: widget.firstAttemptByEmptyPassword,
      );
    } else if (widget.filePath != null) {
      _documentRef = PdfDocumentRefFile(
        widget.filePath!,
        useProgressiveLoading: true,
        progressiveLoadingTargetPage: widget.pageNumber,
        passwordProvider: widget.passwordProvider,
        firstAttemptByEmptyPassword: widget.firstAttemptByEmptyPassword,
      );
    } else if (widget.assetName != null) {
      _documentRef = PdfDocumentRefAsset(
        widget.assetName!,
        useProgressiveLoading: true,
        progressiveLoadingTargetPage: widget.pageNumber,
        passwordProvider: widget.passwordProvider,
        firstAttemptByEmptyPassword: widget.firstAttemptByEmptyPassword,
      );
    } else if (widget.data != null) {
      _documentRef = PdfDocumentRefData(
        widget.data!,
        sourceName: 'memory',
        useProgressiveLoading: true,
        progressiveLoadingTargetPage: widget.pageNumber,
        passwordProvider: widget.passwordProvider,
        firstAttemptByEmptyPassword: widget.firstAttemptByEmptyPassword,
      );
    }
  }

  @override
  void dispose() {
    _cancellationToken?.cancel();
    super.dispose();
  }

  /// Load only the specific page and get its dimensions.
  Future<void> _loadPageDimensions(PdfPage page) async {
    if (_isLoading || _aspectRatio != null) return;

    setState(() {
      _isLoading = true;
    });

    _cancellationToken?.cancel();
    _cancellationToken = page.createCancellationToken();

    try {
      // Render at minimum size just to get dimensions
      await page.render(fullWidth: 1, fullHeight: 1, cancellationToken: _cancellationToken);

      if (page.isLoaded && mounted) {
        setState(() {
          _aspectRatio = page.width / page.height;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_documentRef == null) {
      return _buildPlaceholder('Invalid configuration');
    }

    return PdfDocumentViewBuilder(
      documentRef: _documentRef!,
      builder: (context, document) {
        if (document == null) {
          return _buildPlaceholder('Loading PDF...');
        }

        // Validate page number
        final pageIndex = (widget.pageNumber - 1).clamp(0, document.pages.length - 1);
        final page = document.pages[pageIndex];

        // Load page dimensions if not already loaded
        if (_aspectRatio == null && !_isLoading) {
          scheduleMicrotask(() => _loadPageDimensions(page));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // Use actual aspect ratio if available, otherwise fallback
            final aspectRatio = _aspectRatio ?? widget.fallbackAspectRatio;

            // Calculate dimensions
            final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 200.0;
            final height = width / aspectRatio;

            // Display the page
            return SizedBox(
              width: width,
              height: height,
              child: Stack(
                children: [
                  // PDF Page
                  PdfPageView(
                    document: document,
                    pageNumber: pageIndex + 1,
                    maximumDpi: widget.maximumDpi,
                    alignment: widget.alignment,
                    backgroundColor: widget.backgroundColor,
                  ),

                  // Loading indicator overlay (only while determining dimensions)
                  if (_isLoading && _aspectRatio == null)
                    Container(
                      color: Colors.black12,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),

                  // Error message overlay
                  if (_errorMessage != null)
                    Container(
                      color: Colors.red.withValues(alpha: 0.1),
                      child: Center(
                        child: Text(
                          'Error: $_errorMessage',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
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

  Widget _buildPlaceholder(String message) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 200.0;
        final height = width / widget.fallbackAspectRatio;

        return Container(
          width: width,
          height: height,
          color: widget.backgroundColor ?? Colors.grey[200],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(message)],
            ),
          ),
        );
      },
    );
  }
}
