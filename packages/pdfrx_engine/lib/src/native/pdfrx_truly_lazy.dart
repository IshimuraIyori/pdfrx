import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';

import '../pdfrx_api.dart';
import 'pdfium_bindings.dart' as pdfium_bindings;
import 'pdfrx_pdfium.dart';
import 'worker.dart';

/// Factory for creating truly lazy-loaded PDF documents
class PdfDocumentTrulyLazyFactory {
  /// Open a PDF with true lazy loading - no page sizes are loaded initially
  static Future<PdfDocument> openUriTrulyLazy(
    Uri uri, {
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    Map<String, String>? headers,
  }) async {
    Uint8List data;
    
    if (uri.isScheme('file')) {
      final file = File(uri.toFilePath());
      data = await file.readAsBytes();
    } else {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode != 200) {
        throw PdfException('Failed to download PDF: ${response.statusCode}');
      }
      data = response.bodyBytes;
    }
    
    return await openDataTrulyLazy(
      data,
      passwordProvider: passwordProvider,
      firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
      sourceName: uri.toString(),
    );
  }

  /// Open PDF from data with true lazy loading
  static Future<PdfDocument> openDataTrulyLazy(
    Uint8List data, {
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    String? sourceName,
  }) async {
    _initPdfiumIfNeeded();
    
    // Open document but don't load any pages
    final result = await _openDocumentOnly(
      data,
      passwordProvider: passwordProvider,
      firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
    );
    
    if (result.document == nullptr) {
      throw const PdfException('Failed to open PDF document');
    }
    
    // Get only the page count
    final pageCount = await (await backgroundWorker).compute(
      (docAddress) {
        final doc = pdfium_bindings.FPDF_DOCUMENT.fromAddress(docAddress);
        return pdfium.FPDF_GetPageCount(doc);
      },
      result.document.address,
    );
    
    return _PdfDocumentTrulyLazy(
      document: result.document,
      sourceName: sourceName ?? 'memory.pdf',
      pageCount: pageCount,
      securityHandlerRevision: result.securityHandlerRevision,
      permissions: result.permissions,
      formHandle: result.formHandle,
      formInfo: result.formInfo,
    );
  }
}

void _initPdfiumIfNeeded() {
  if (!_initialized) {
    using((arena) {
      final config = arena.allocate<pdfium_bindings.FPDF_LIBRARY_CONFIG>(
          sizeOf<pdfium_bindings.FPDF_LIBRARY_CONFIG>());
      config.ref.version = 2;
      config.ref.m_pUserFontPaths = nullptr;
      config.ref.m_pIsolate = nullptr;
      config.ref.m_v8EmbedderSlot = 0;
      pdfium.FPDF_InitLibraryWithConfig(config);
    });
    _initialized = true;
  }
}

bool _initialized = false;

/// Helper to open document only (no page loading)
Future<({
  pdfium_bindings.FPDF_DOCUMENT document,
  int securityHandlerRevision,
  PdfPermissions? permissions,
  pdfium_bindings.FPDF_FORMHANDLE formHandle,
  Pointer<pdfium_bindings.FPDF_FORMFILLINFO> formInfo,
})> _openDocumentOnly(
  Uint8List data, {
  PdfPasswordProvider? passwordProvider,
  bool firstAttemptByEmptyPassword = true,
}) async {
  return await (await backgroundWorker).compute(
    (params) => using((arena) {
      // Allocate memory for PDF data
      final dataPtr = arena.allocate<Uint8>(params.data.length);
      dataPtr.asTypedList(params.data.length).setAll(0, params.data);
      
      // Try with empty password first if requested
      String? password = params.password;
      if (password == null && params.firstAttemptByEmptyPassword) {
        password = '';
      }
      
      final passwordPtr = password != null 
          ? password.toNativeUtf8(allocator: arena).cast<Char>()
          : nullptr;
      
      final doc = pdfium.FPDF_LoadMemDocument(
        dataPtr.cast<Void>(),
        params.data.length,
        passwordPtr,
      );
      
      if (doc == nullptr) {
        final error = pdfium.FPDF_GetLastError();
        if (error == pdfium_bindings.FPDF_ERR_PASSWORD) {
          throw PdfPasswordException('Password required');
        }
        throw PdfException('Failed to open PDF: error $error');
      }
      
      final securityHandlerRevision = pdfium.FPDF_GetSecurityHandlerRevision(doc);
      final docPermissions = pdfium.FPDF_GetDocPermissions(doc);
      final permissions = securityHandlerRevision != -1
          ? PdfPermissions(docPermissions, securityHandlerRevision)
          : null;
      
      // Initialize form fill - use calloc for persistent memory
      final formInfo = calloc.allocate<pdfium_bindings.FPDF_FORMFILLINFO>(
          sizeOf<pdfium_bindings.FPDF_FORMFILLINFO>());
      formInfo.ref.version = 1;
      
      final formHandle = pdfium.FPDFDOC_InitFormFillEnvironment(doc, formInfo);
      
      return (
        document: doc,
        securityHandlerRevision: securityHandlerRevision,
        permissions: permissions,
        formHandle: formHandle,
        formInfo: formInfo,
      );
    }),
    (
      data: data,
      password: null,
      firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
    ),
  );
}

/// Truly lazy PDF document implementation
class _PdfDocumentTrulyLazy extends PdfDocument {
  final pdfium_bindings.FPDF_DOCUMENT document;
  final int pageCount;
  final int securityHandlerRevision;
  final pdfium_bindings.FPDF_FORMHANDLE formHandle;
  final Pointer<pdfium_bindings.FPDF_FORMFILLINFO> formInfo;
  final subject = BehaviorSubject<PdfDocumentEvent>();
  
  bool isDisposed = false;
  late final List<_TrulyLazyPdfPage> _pages;
  
  _PdfDocumentTrulyLazy({
    required this.document,
    required super.sourceName,
    required this.pageCount,
    required this.securityHandlerRevision,
    required PdfPermissions? permissions,
    required this.formHandle,
    required this.formInfo,
  }) : super() {
    // Create placeholder pages - no size information at all
    _pages = List.generate(
      pageCount,
      (index) => _TrulyLazyPdfPage(
        document: this,
        pageNumber: index + 1,
      ),
    );
  }
  
  @override
  List<PdfPage> get pages => _pages;
  
  @override
  bool get isEncrypted => securityHandlerRevision != -1;
  
  @override
  PdfPermissions? get permissions => securityHandlerRevision != -1
      ? PdfPermissions(
          pdfium.FPDF_GetDocPermissions(document),
          securityHandlerRevision,
        )
      : null;
  
  @override
  Stream<PdfDocumentEvent> get events => subject.stream;
  
  @override
  Future<bool> loadPageDynamically(int pageNumber) async {
    if (isDisposed) return false;
    if (pageNumber < 1 || pageNumber > pageCount) return false;
    
    final page = _pages[pageNumber - 1];
    if (page._isLoaded) return true;
    
    // Load page dimensions for the first time
    final pageData = await _loadPageDimensions(pageNumber - 1);
    if (pageData == null) return false;
    
    // Update page with actual dimensions
    page._setDimensions(
      width: pageData.width,
      height: pageData.height,
      rotation: PdfPageRotation.values[pageData.rotation],
    );
    
    // Notify listeners
    subject.add(PdfDocumentPageStatusChangedEvent(this, [page]));
    
    return true;
  }
  
  @override
  Future<Map<int, bool>> loadPagesDynamically(List<int> pageNumbers) async {
    final results = <int, bool>{};
    
    // Load pages in parallel
    final futures = <Future<bool>>[];
    for (final pageNum in pageNumbers) {
      if (pageNum >= 1 && pageNum <= pageCount) {
        futures.add(loadPageDynamically(pageNum).then((success) {
          results[pageNum] = success;
          return success;
        }));
      } else {
        results[pageNum] = false;
      }
    }
    
    await Future.wait(futures, eagerError: false);
    return results;
  }
  
  /// Load dimensions for a specific page
  Future<({double width, double height, int rotation})?> _loadPageDimensions(int pageIndex) async {
    try {
      return await (await backgroundWorker).compute(
        (params) {
          final doc = pdfium_bindings.FPDF_DOCUMENT.fromAddress(params.docAddress);
          final page = pdfium.FPDF_LoadPage(doc, params.pageIndex);
          if (page == nullptr) return null;
          
          try {
            return (
              width: pdfium.FPDF_GetPageWidthF(page),
              height: pdfium.FPDF_GetPageHeightF(page),
              rotation: pdfium.FPDFPage_GetRotation(page),
            );
          } finally {
            pdfium.FPDF_ClosePage(page);
          }
        },
        (docAddress: document.address, pageIndex: pageIndex),
      );
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> loadPagesProgressively<T>({
    PdfPageLoadingCallback<T>? onPageLoadProgress,
    T? data,
    Duration loadUnitDuration = const Duration(milliseconds: 250),
  }) async {
    for (int i = 0; i < pageCount; i++) {
      if (isDisposed) return;
      
      if (!_pages[i]._isLoaded) {
        await loadPageDynamically(i + 1);
        
        if (onPageLoadProgress != null) {
          final shouldContinue = await onPageLoadProgress(i + 1, pageCount, data);
          if (!shouldContinue) return;
        }
      }
    }
  }
  
  @override
  Future<List<PdfOutlineNode>> loadOutline() async {
    if (isDisposed) return [];
    
    return await (await backgroundWorker).compute(
      (docAddress) => using((arena) {
        final doc = pdfium_bindings.FPDF_DOCUMENT.fromAddress(docAddress);
        final rootBookmark = pdfium.FPDFBookmark_GetFirstChild(doc, nullptr);
        return _loadOutlineNodes(doc, rootBookmark, arena);
      }),
      document.address,
    );
  }
  
  static List<PdfOutlineNode> _loadOutlineNodes(
    pdfium_bindings.FPDF_DOCUMENT doc,
    pdfium_bindings.FPDF_BOOKMARK bookmark,
    Arena arena,
  ) {
    final nodes = <PdfOutlineNode>[];
    while (bookmark != nullptr) {
      final titleSize = pdfium.FPDFBookmark_GetTitle(bookmark, nullptr, 0);
      final titleBuf = arena.allocate<Void>(titleSize);
      pdfium.FPDFBookmark_GetTitle(bookmark, titleBuf, titleSize);
      
      nodes.add(PdfOutlineNode(
        title: titleBuf.cast<Utf16>().toDartString(),
        dest: null, // Simplified
        children: _loadOutlineNodes(
          doc,
          pdfium.FPDFBookmark_GetFirstChild(doc, bookmark),
          arena,
        ),
      ));
      
      bookmark = pdfium.FPDFBookmark_GetNextSibling(doc, bookmark);
    }
    return nodes;
  }
  
  @override
  bool isIdenticalDocumentHandle(Object? other) =>
      other is _PdfDocumentTrulyLazy && document.address == other.document.address;
  
  @override
  Future<void> dispose() async {
    if (!isDisposed) {
      isDisposed = true;
      subject.close();
      
      await (await backgroundWorker).compute((params) {
        final formHandle = pdfium_bindings.FPDF_FORMHANDLE.fromAddress(params.formHandle);
        final formInfo = Pointer<pdfium_bindings.FPDF_FORMFILLINFO>.fromAddress(params.formInfo);
        pdfium.FPDFDOC_ExitFormFillEnvironment(formHandle);
        calloc.free(formInfo);
        
        final doc = pdfium_bindings.FPDF_DOCUMENT.fromAddress(params.document);
        pdfium.FPDF_CloseDocument(doc);
      }, (
        formHandle: formHandle.address,
        formInfo: formInfo.address,
        document: document.address,
      ));
    }
  }
}

/// Truly lazy PDF page - no dimensions until explicitly loaded
class _TrulyLazyPdfPage extends PdfPage {
  @override
  final _PdfDocumentTrulyLazy document;
  @override
  final int pageNumber;
  
  // Dimensions are completely unknown until loaded
  double? _width;
  double? _height;
  PdfPageRotation? _rotation;
  bool _isLoaded = false;
  
  _TrulyLazyPdfPage({
    required this.document,
    required this.pageNumber,
  });
  
  @override
  double get width {
    if (!_isLoaded) {
      // Return default A4 width if not loaded
      // In production, this could trigger async load
      return 595.0;
    }
    return _width!;
  }
  
  @override
  double get height {
    if (!_isLoaded) {
      // Return default A4 height if not loaded
      return 842.0;
    }
    return _height!;
  }
  
  @override
  PdfPageRotation get rotation => _rotation ?? PdfPageRotation.none;
  
  @override
  bool get isLoaded => _isLoaded;
  
  void _setDimensions({
    required double width,
    required double height,
    required PdfPageRotation rotation,
  }) {
    _width = width;
    _height = height;
    _rotation = rotation;
    _isLoaded = true;
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
    if (!_isLoaded) {
      await document.loadPageDynamically(pageNumber);
    }
    
    // Simplified render implementation
    // In production, this would use PDFium to render the page
    return null;
  }
  
  @override
  PdfPageRenderCancellationToken createCancellationToken() {
    return _SimpleCancellationToken();
  }
  
  @override
  Future<String> loadText() async {
    if (!_isLoaded) {
      await document.loadPageDynamically(pageNumber);
    }
    
    return await (await backgroundWorker).compute(
      (params) {
        final doc = pdfium_bindings.FPDF_DOCUMENT.fromAddress(params.docAddress);
        final page = pdfium.FPDF_LoadPage(doc, params.pageIndex);
        if (page == nullptr) return '';
        
        try {
          final textPage = pdfium.FPDFText_LoadPage(page);
          final charCount = pdfium.FPDFText_CountChars(textPage);
          
          final buffer = using((arena) {
            final buf = arena.allocate<Uint16>(charCount + 1);
            pdfium.FPDFText_GetText(textPage, 0, charCount, buf.cast<UnsignedShort>());
            return buf.cast<Utf16>().toDartString();
          });
          
          pdfium.FPDFText_ClosePage(textPage);
          return buffer;
        } finally {
          pdfium.FPDF_ClosePage(page);
        }
      },
      (docAddress: document.document.address, pageIndex: pageNumber - 1),
    );
  }
  
  @override
  Future<List<PdfLink>> loadLinks({
    bool compact = false,
    bool enableAutoLinkDetection = false,
  }) async {
    if (!_isLoaded) {
      await document.loadPageDynamically(pageNumber);
    }
    
    // Link loading implementation
    return [];
  }
  
  @override
  Future<List<PdfRect>> loadTextCharRects() async {
    if (!_isLoaded) {
      await document.loadPageDynamically(pageNumber);
    }
    
    // Text char rects loading implementation
    return [];
  }
}

/// Simple cancellation token implementation
class _SimpleCancellationToken extends PdfPageRenderCancellationToken {
  bool _isCancelled = false;
  
  @override
  bool get isCanceled => _isCancelled;
  
  @override
  void cancel() {
    _isCancelled = true;
  }
}