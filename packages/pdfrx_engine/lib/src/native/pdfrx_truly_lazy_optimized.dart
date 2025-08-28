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

/// Optimized factory for truly lazy-loaded PDF documents
class PdfDocumentTrulyLazyOptimized {
  /// Open a local file with true lazy loading using file path directly
  static Future<PdfDocument> openFileTrulyLazy(
    String filePath, {
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
  }) async {
    _initPdfiumIfNeeded();
    
    // Open file directly with PDFium (no memory loading)
    final result = await _openFileDirectly(
      filePath,
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
    
    return _PdfDocumentTrulyLazyOptimized(
      document: result.document,
      sourceName: filePath,
      pageCount: pageCount,
      securityHandlerRevision: result.securityHandlerRevision,
      permissions: result.permissions,
      formHandle: result.formHandle,
      formInfo: result.formInfo,
      filePath: filePath,  // Keep file path for range access
    );
  }

  /// Open a URI with true lazy loading
  static Future<PdfDocument> openUriTrulyLazy(
    Uri uri, {
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    Map<String, String>? headers,
    bool preferRangeAccess = false,
  }) async {
    // For local files, use direct file access
    if (uri.isScheme('file')) {
      return openFileTrulyLazy(
        uri.toFilePath(),
        passwordProvider: passwordProvider,
        firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
      );
    }
    
    // For network files with range access
    if (preferRangeAccess) {
      return await _openNetworkWithRangeAccess(
        uri,
        passwordProvider: passwordProvider,
        firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
        headers: headers,
      );
    }
    
    // Fallback: download entire file
    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw PdfException('Failed to download PDF: ${response.statusCode}');
    }
    
    return await openDataTrulyLazy(
      response.bodyBytes,
      passwordProvider: passwordProvider,
      firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
      sourceName: uri.toString(),
    );
  }

  /// Open PDF from memory with true lazy loading
  static Future<PdfDocument> openDataTrulyLazy(
    Uint8List data, {
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    String? sourceName,
  }) async {
    _initPdfiumIfNeeded();
    
    final result = await _openMemoryDocument(
      data,
      passwordProvider: passwordProvider,
      firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
    );
    
    if (result.document == nullptr) {
      throw const PdfException('Failed to open PDF document');
    }
    
    final pageCount = await (await backgroundWorker).compute(
      (docAddress) {
        final doc = pdfium_bindings.FPDF_DOCUMENT.fromAddress(docAddress);
        return pdfium.FPDF_GetPageCount(doc);
      },
      result.document.address,
    );
    
    return _PdfDocumentTrulyLazyOptimized(
      document: result.document,
      sourceName: sourceName ?? 'memory.pdf',
      pageCount: pageCount,
      securityHandlerRevision: result.securityHandlerRevision,
      permissions: result.permissions,
      formHandle: result.formHandle,
      formInfo: result.formInfo,
      memoryData: data,  // Keep data for memory-based access
    );
  }
  
  /// Open network PDF with HTTP Range support
  static Future<PdfDocument> _openNetworkWithRangeAccess(
    Uri uri, {
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    Map<String, String>? headers,
  }) async {
    // First, get just the header to determine file size
    final headResponse = await http.head(uri, headers: headers);
    if (headResponse.statusCode != 200) {
      throw PdfException('Failed to access PDF: ${headResponse.statusCode}');
    }
    
    final contentLength = int.tryParse(
      headResponse.headers['content-length'] ?? '0'
    ) ?? 0;
    
    if (contentLength == 0) {
      throw const PdfException('Cannot determine PDF size');
    }
    
    // Check if server supports range requests
    final acceptRanges = headResponse.headers['accept-ranges'];
    if (acceptRanges != 'bytes') {
      // Fallback to full download
      final response = await http.get(uri, headers: headers);
      return openDataTrulyLazy(
        response.bodyBytes,
        passwordProvider: passwordProvider,
        firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
        sourceName: uri.toString(),
      );
    }
    
    // Download just the header (first 1KB)
    final rangeHeaders = {...?headers, 'Range': 'bytes=0-1023'};
    final headerResponse = await http.get(uri, headers: rangeHeaders);
    
    // Create a custom loader that fetches ranges on demand
    return _PdfDocumentWithRangeAccess(
      uri: uri,
      headers: headers,
      fileSize: contentLength,
      headerData: headerResponse.bodyBytes,
      passwordProvider: passwordProvider,
      firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
    );
  }
}

/// Initialize PDFium if needed
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

/// Open file directly using PDFium's file API (no memory loading)
Future<({
  pdfium_bindings.FPDF_DOCUMENT document,
  int securityHandlerRevision,
  PdfPermissions? permissions,
  pdfium_bindings.FPDF_FORMHANDLE formHandle,
  Pointer<pdfium_bindings.FPDF_FORMFILLINFO> formInfo,
})> _openFileDirectly(
  String filePath, {
  PdfPasswordProvider? passwordProvider,
  bool firstAttemptByEmptyPassword = true,
}) async {
  return await (await backgroundWorker).compute(
    (params) => using((arena) {
      // Try with empty password first if requested
      String? password = params.password;
      if (password == null && params.firstAttemptByEmptyPassword) {
        password = '';
      }
      
      final pathPtr = params.filePath.toNativeUtf8(allocator: arena).cast<Char>();
      final passwordPtr = password != null 
          ? password.toNativeUtf8(allocator: arena).cast<Char>()
          : nullptr;
      
      // Use FPDF_LoadDocument for direct file access (no memory loading)
      final doc = pdfium.FPDF_LoadDocument(pathPtr, passwordPtr);
      
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
      
      // Initialize form fill
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
      filePath: filePath,
      password: null,
      firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
    ),
  );
}

/// Open memory document
Future<({
  pdfium_bindings.FPDF_DOCUMENT document,
  int securityHandlerRevision,
  PdfPermissions? permissions,
  pdfium_bindings.FPDF_FORMHANDLE formHandle,
  Pointer<pdfium_bindings.FPDF_FORMFILLINFO> formInfo,
})> _openMemoryDocument(
  Uint8List data, {
  PdfPasswordProvider? passwordProvider,
  bool firstAttemptByEmptyPassword = true,
}) async {
  return await (await backgroundWorker).compute(
    (params) => using((arena) {
      // Allocate memory for PDF data
      final dataPtr = arena.allocate<Uint8>(params.data.length);
      dataPtr.asTypedList(params.data.length).setAll(0, params.data);
      
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

/// Optimized truly lazy PDF document
class _PdfDocumentTrulyLazyOptimized extends PdfDocument {
  final pdfium_bindings.FPDF_DOCUMENT document;
  final int pageCount;
  final int securityHandlerRevision;
  final pdfium_bindings.FPDF_FORMHANDLE formHandle;
  final Pointer<pdfium_bindings.FPDF_FORMFILLINFO> formInfo;
  final String? filePath;  // For local files
  final Uint8List? memoryData;  // For memory-based documents
  final subject = BehaviorSubject<PdfDocumentEvent>();
  
  bool isDisposed = false;
  late final List<_TrulyLazyPdfPage> _pages;
  
  _PdfDocumentTrulyLazyOptimized({
    required this.document,
    required super.sourceName,
    required this.pageCount,
    required this.securityHandlerRevision,
    required PdfPermissions? permissions,
    required this.formHandle,
    required this.formInfo,
    this.filePath,
    this.memoryData,
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
    // Simplified implementation
    return [];
  }
  
  @override
  bool isIdenticalDocumentHandle(Object? other) =>
      other is _PdfDocumentTrulyLazyOptimized && 
      document.address == other.document.address;
  
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

/// Truly lazy PDF page
class _TrulyLazyPdfPage extends PdfPage {
  @override
  final _PdfDocumentTrulyLazyOptimized document;
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
  double get width => _width ?? 595.0;  // A4 default
  
  @override
  double get height => _height ?? 842.0;  // A4 default
  
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
    return '';
  }
  
  @override
  Future<List<PdfLink>> loadLinks({
    bool compact = false,
    bool enableAutoLinkDetection = false,
  }) async {
    if (!_isLoaded) {
      await document.loadPageDynamically(pageNumber);
    }
    return [];
  }
  
  @override
  Future<List<PdfRect>> loadTextCharRects() async {
    if (!_isLoaded) {
      await document.loadPageDynamically(pageNumber);
    }
    return [];
  }
}

/// Simple cancellation token
class _SimpleCancellationToken extends PdfPageRenderCancellationToken {
  bool _isCancelled = false;
  
  @override
  bool get isCanceled => _isCancelled;
  
  @override
  void cancel() {
    _isCancelled = true;
  }
}

/// Document with HTTP Range access support
class _PdfDocumentWithRangeAccess extends PdfDocument {
  final Uri uri;
  final Map<String, String>? headers;
  final int fileSize;
  final Uint8List headerData;
  
  _PdfDocumentWithRangeAccess({
    required this.uri,
    required this.headers,
    required this.fileSize,
    required this.headerData,
    required PdfPasswordProvider? passwordProvider,
    required bool firstAttemptByEmptyPassword,
  }) : super(sourceName: uri.toString());
  
  // Implementation would fetch page data on demand using HTTP Range requests
  
  @override
  List<PdfPage> get pages => throw UnimplementedError();
  
  @override
  bool get isEncrypted => false;
  
  @override
  PdfPermissions? get permissions => null;
  
  @override
  Stream<PdfDocumentEvent> get events => const Stream.empty();
  
  @override
  Future<bool> loadPageDynamically(int pageNumber) async {
    // Fetch page data using Range request
    throw UnimplementedError();
  }
  
  @override
  Future<Map<int, bool>> loadPagesDynamically(List<int> pageNumbers) async {
    throw UnimplementedError();
  }
  
  @override
  Future<void> loadPagesProgressively<T>({
    PdfPageLoadingCallback<T>? onPageLoadProgress,
    T? data,
    Duration loadUnitDuration = const Duration(milliseconds: 250),
  }) async {
    throw UnimplementedError();
  }
  
  @override
  Future<List<PdfOutlineNode>> loadOutline() async => [];
  
  @override
  bool isIdenticalDocumentHandle(Object? other) => false;
  
  @override
  Future<void> dispose() async {}
}