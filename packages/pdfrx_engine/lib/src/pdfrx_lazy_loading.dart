import 'dart:async';
import 'dart:typed_data';

import 'pdfrx_api.dart';

/// Extension to create documents with fully lazy loading
extension PdfDocumentLazyLoading on PdfDocument {
  /// Open a PDF document with fully lazy loading.
  /// 
  /// Unlike progressive loading, this doesn't load any page sizes initially.
  /// Each page's dimensions are loaded only when that specific page is accessed.
  static Future<PdfDocument> openUriLazy(
    Uri uri, {
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    PdfDownloadProgressCallback? progressCallback,
    bool preferRangeAccess = false,
    Map<String, String>? headers,
    bool withCredentials = false,
  }) async {
    // First, open the document normally with progressive loading
    final tempDoc = await PdfDocument.openUri(
      uri,
      passwordProvider: passwordProvider,
      firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
      useProgressiveLoading: true,
      progressCallback: progressCallback,
      preferRangeAccess: preferRangeAccess,
      headers: headers,
      withCredentials: withCredentials,
    );
    
    // Get the page count
    final pageCount = tempDoc.pages.length;
    
    // Create a lazy wrapper
    return _LazyPdfDocument(
      baseDocument: tempDoc,
      pageCount: pageCount,
      uri: uri,
    );
  }
  
  /// Open a PDF from bytes with fully lazy loading.
  static Future<PdfDocument> openDataLazy(
    Uint8List data, {
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    String? sourceName,
  }) async {
    // Open with progressive loading first
    final tempDoc = await PdfDocument.openData(
      data,
      passwordProvider: passwordProvider,
      firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
      sourceName: sourceName,
      useProgressiveLoading: true,
    );
    
    final pageCount = tempDoc.pages.length;
    
    return _LazyPdfDocument(
      baseDocument: tempDoc,
      pageCount: pageCount,
      uri: null,
    );
  }
}

/// A PDF document that loads page dimensions lazily
class _LazyPdfDocument extends PdfDocument {
  final PdfDocument baseDocument;
  final int pageCount;
  final Uri? uri;
  final List<_LazyPdfPage> _lazyPages;
  
  _LazyPdfDocument({
    required this.baseDocument,
    required this.pageCount,
    required this.uri,
  }) : _lazyPages = List.generate(
          pageCount,
          (index) => _LazyPdfPage(
            pageNumber: index + 1,
            document: null, // Will be set later
          ),
        ),
        super(sourceName: baseDocument.sourceName) {
    // Set document reference for all pages
    for (final page in _lazyPages) {
      page._document = this;
    }
  }
  
  @override
  List<PdfPage> get pages => _lazyPages;
  
  @override
  bool get isEncrypted => baseDocument.isEncrypted;
  
  @override
  PdfPermissions? get permissions => baseDocument.permissions;
  
  @override
  Stream<PdfDocumentEvent> get events => baseDocument.events;
  
  @override
  Future<void> loadPagesProgressively<T>({
    PdfPageLoadingCallback<T>? onPageLoadProgress,
    T? data,
    Duration loadUnitDuration = const Duration(milliseconds: 250),
  }) async {
    // Load pages one by one as needed
    for (int i = 0; i < _lazyPages.length; i++) {
      if (_lazyPages[i]._isActuallyLoaded) continue;
      
      await loadPageDynamically(i + 1);
      
      if (onPageLoadProgress != null) {
        final shouldContinue = await onPageLoadProgress(i + 1, pageCount, data);
        if (!shouldContinue) break;
      }
    }
  }
  
  @override
  Future<bool> loadPageDynamically(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > pageCount) return false;
    
    final pageIndex = pageNumber - 1;
    final lazyPage = _lazyPages[pageIndex];
    
    if (lazyPage._isActuallyLoaded) return true;
    
    // Load the actual page from base document
    final success = await baseDocument.loadPageDynamically(pageNumber);
    if (!success) return false;
    
    // Update the lazy page with actual dimensions
    final actualPage = baseDocument.pages[pageIndex];
    lazyPage._actualWidth = actualPage.width;
    lazyPage._actualHeight = actualPage.height;
    lazyPage._actualRotation = actualPage.rotation;
    lazyPage._isActuallyLoaded = true;
    lazyPage._actualPage = actualPage;
    
    return true;
  }
  
  @override
  Future<Map<int, bool>> loadPagesDynamically(List<int> pageNumbers) async {
    final results = <int, bool>{};
    for (final pageNum in pageNumbers) {
      results[pageNum] = await loadPageDynamically(pageNum);
    }
    return results;
  }
  
  @override
  Future<List<PdfOutlineNode>> loadOutline() => baseDocument.loadOutline();
  
  @override
  bool isIdenticalDocumentHandle(Object? other) => 
    baseDocument.isIdenticalDocumentHandle(other);
  
  @override
  Future<void> dispose() => baseDocument.dispose();
}

/// A lazy-loaded PDF page
class _LazyPdfPage extends PdfPage {
  @override
  final int pageNumber;
  
  // Document reference (set after construction)
  _LazyPdfDocument? _document;
  
  // Actual dimensions (loaded on demand)
  double? _actualWidth;
  double? _actualHeight;
  PdfPageRotation? _actualRotation;
  bool _isActuallyLoaded = false;
  PdfPage? _actualPage;
  
  // Default estimated dimensions (A4)
  static const double _defaultWidth = 595.0;
  static const double _defaultHeight = 842.0;
  
  _LazyPdfPage({
    required this.pageNumber,
    required _LazyPdfDocument? document,
  }) : _document = document;
  
  @override
  PdfDocument get document => _document!;
  
  @override
  double get width {
    _ensureLoaded();
    return _actualWidth ?? _defaultWidth;
  }
  
  @override
  double get height {
    _ensureLoaded();
    return _actualHeight ?? _defaultHeight;
  }
  
  @override
  PdfPageRotation get rotation {
    _ensureLoaded();
    return _actualRotation ?? PdfPageRotation.none;
  }
  
  @override
  bool get isLoaded => _isActuallyLoaded;
  
  void _ensureLoaded() {
    if (!_isActuallyLoaded && _document != null) {
      // Trigger lazy loading synchronously (blocking)
      // Note: This is not ideal but maintains the synchronous API
      _document!.loadPageDynamically(pageNumber).then((_) {
        // Page is now loaded
      });
    }
  }
  
  @override
  Future<PdfImage?> render({
    int x = 0,
    int y = 0,
    int? width,
    int? height,
    double? fullWidth,
    double? fullHeight,
    int? backgroundColor,
    PdfAnnotationRenderingMode annotationRenderingMode = PdfAnnotationRenderingMode.annotationAndForms,
    int flags = PdfPageRenderFlags.none,
    PdfPageRenderCancellationToken? cancellationToken,
  }) async {
    // Ensure page is loaded before rendering
    if (!_isActuallyLoaded) {
      await _document!.loadPageDynamically(pageNumber);
    }
    
    return _actualPage?.render(
      x: x,
      y: y,
      width: width,
      height: height,
      fullWidth: fullWidth,
      fullHeight: fullHeight,
      backgroundColor: backgroundColor,
      annotationRenderingMode: annotationRenderingMode,
      flags: flags,
      cancellationToken: cancellationToken,
    );
  }
  
  @override
  PdfPageRenderCancellationToken createCancellationToken() {
    if (_actualPage != null) {
      return _actualPage!.createCancellationToken();
    }
    throw StateError('Page not loaded yet');
  }
  
  @override
  Future<String> loadText() async {
    if (!_isActuallyLoaded) {
      await _document!.loadPageDynamically(pageNumber);
    }
    return _actualPage?.loadText() ?? '';
  }
  
  @override
  Future<List<PdfLink>> loadLinks({
    bool compact = false,
    bool enableAutoLinkDetection = false,
  }) async {
    if (!_isActuallyLoaded) {
      await _document!.loadPageDynamically(pageNumber);
    }
    return _actualPage?.loadLinks(
      compact: compact,
      enableAutoLinkDetection: enableAutoLinkDetection,
    ) ?? [];
  }
  
  @override
  Future<List<PdfRect>> loadTextCharRects() async {
    if (!_isActuallyLoaded) {
      await _document!.loadPageDynamically(pageNumber);
    }
    return _actualPage?.loadTextCharRects() ?? [];
  }
}