import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../pdfrx.dart';

/// A widget that loads PDF document.
///
/// The following fragment shows how to display a PDF document from an asset:
///
/// ```dart
/// PdfDocumentViewBuilder.asset(
///   'assets/sample.pdf',
///   builder: (context, document) => ListView.builder(
///     itemCount: document?.pages.length ?? 0,
///     itemBuilder: (context, index) {
///       return Container(
///         margin: const EdgeInsets.all(8),
///         height: 240,
///         child: Column(
///           children: [
///             SizedBox(
///               height: 220,
///               child: PdfPageView(
///                 document: document,
///                 pageNumber: index + 1,
///               ),
///             ),
///             Text('${index + 1}'),
///           ],
///         ),
///       );
///     },
///   ),
/// ),
/// ```
class PdfDocumentViewBuilder extends StatefulWidget {
  const PdfDocumentViewBuilder({
    required this.documentRef,
    required this.builder,
    this.targetPageNumber,
    super.key,
  });

  PdfDocumentViewBuilder.asset(
    String assetName, {
    required this.builder,
    super.key,
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    bool useProgressiveLoading = false,
    bool autoDispose = true,
    this.targetPageNumber,
  }) : documentRef = PdfDocumentRefAsset(
         assetName,
         passwordProvider: passwordProvider,
         firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
         useProgressiveLoading: useProgressiveLoading,
         autoDispose: autoDispose,
       );

  PdfDocumentViewBuilder.file(
    String filePath, {
    required this.builder,
    super.key,
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    bool useProgressiveLoading = false,
    bool autoDispose = true,
    this.targetPageNumber,
  }) : documentRef = PdfDocumentRefFile(
         filePath,
         passwordProvider: passwordProvider,
         firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
         useProgressiveLoading: useProgressiveLoading,
         autoDispose: autoDispose,
       );

  PdfDocumentViewBuilder.uri(
    Uri uri, {
    required this.builder,
    super.key,
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    bool useProgressiveLoading = false,
    bool autoDispose = true,
    bool preferRangeAccess = false,
    Map<String, String>? headers,
    bool withCredentials = false,
    this.targetPageNumber,
  }) : documentRef = PdfDocumentRefUri(
         uri,
         passwordProvider: passwordProvider,
         firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
         useProgressiveLoading: useProgressiveLoading,
         autoDispose: autoDispose,
         preferRangeAccess: preferRangeAccess,
         headers: headers,
         withCredentials: withCredentials,
       );

  /// A reference to the PDF document.
  final PdfDocumentRef documentRef;

  /// A builder that builds a widget tree with the PDF document.
  final PdfDocumentViewBuilderFunction builder;

  /// Target page number to load (1-based).
  ///
  /// When specified with useProgressiveLoading, only this page will be loaded
  /// from the PDF document.
  final int? targetPageNumber;

  @override
  State<PdfDocumentViewBuilder> createState() => _PdfDocumentViewBuilderState();

  static PdfDocumentViewBuilder? maybeOf(BuildContext context) {
    return context.findAncestorWidgetOfExactType<PdfDocumentViewBuilder>();
  }
}

class _PdfDocumentViewBuilderState extends State<PdfDocumentViewBuilder> {
  StreamSubscription<PdfDocumentEvent>? _updateSubscription;

  @override
  void initState() {
    super.initState();
    pdfrxFlutterInitialize();
    widget.documentRef.resolveListenable()
      ..addListener(_onDocumentChanged)
      ..load();
  }

  @override
  void didUpdateWidget(covariant PdfDocumentViewBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget == oldWidget) {
      return;
    }

    oldWidget.documentRef.resolveListenable().removeListener(_onDocumentChanged);
    widget.documentRef.resolveListenable()
      ..addListener(_onDocumentChanged)
      ..load();
    _onDocumentChanged();
  }

  @override
  void dispose() {
    _updateSubscription?.cancel();
    widget.documentRef.resolveListenable().removeListener(_onDocumentChanged);
    super.dispose();
  }

  void _onDocumentChanged() {
    if (mounted) {
      _updateSubscription?.cancel();
      final document = widget.documentRef.resolveListenable().document;
      _updateSubscription = document?.events.listen((event) {
        if (mounted && event.type == PdfDocumentEventType.pageStatusChanged) {
          setState(() {});
        }
      });
      
      // If targetPageNumber is specified, load only that page
      // Otherwise, load all pages progressively
      if (widget.targetPageNumber != null && document != null) {
        // Load specific page if it exists
        if (widget.targetPageNumber! <= document.pages.length && widget.targetPageNumber! > 0) {
          final targetPage = document.pages[widget.targetPageNumber! - 1];
          if (!targetPage.isLoaded) {
            document.loadPagesProgressively();
          }
        }
      } else {
        document?.loadPagesProgressively();
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.documentRef.resolveListenable().document);
  }
}

/// A function that builds a widget tree with the PDF document.
typedef PdfDocumentViewBuilderFunction = Widget Function(BuildContext context, PdfDocument? document);

/// Function to calculate the size of the page based on the size of the widget.
///
/// [biggestSize] is the size of the widget.
/// [page] is the page to be displayed.
///
/// The function returns the size of the page.
typedef PdfPageViewSizeCallback = Size Function(Size biggestSize, PdfPage page);

/// Function to build a widget that wraps the page image.
///
/// It is often used to decorate the page image with a border or a shadow,
/// to set the page background color, etc.
///
/// [context] is the build context.
/// [pageSize] is the size of the page.
/// [page] is the page to be displayed.
/// [pageImage] is the page image; it is null if the page is not rendered yet.
/// The image size may be different from [pageSize] because of the screen DPI
/// or some other reasons.
typedef PdfPageViewDecorationBuilder =
    Widget Function(BuildContext context, Size pageSize, PdfPage page, RawImage? pageImage);

/// A widget that displays a page of a PDF document.
class PdfPageView extends StatefulWidget {
  const PdfPageView({
    required this.document,
    required this.pageNumber,
    this.maximumDpi = 300,
    this.alignment = Alignment.center,
    this.decoration,
    this.backgroundColor,
    this.pageSizeCallback,
    this.decorationBuilder,
    this.useProgressiveLoading = false,
    this.loadOnlyTargetPage = false,
    super.key,
  });

  /// The PDF document.
  final PdfDocument? document;

  /// The page number to be displayed. (The first page is 1).
  final int pageNumber;

  /// The maximum DPI of the page image. The default value is 300.
  ///
  /// The value is used to limit the actual image size to avoid excessive memory usage.
  final double maximumDpi;

  /// The alignment of the page image within the widget.
  final AlignmentGeometry alignment;

  /// The decoration of the page image.
  ///
  /// To disable the default drop-shadow, set [decoration] to `BoxDecoration(color: Colors.white)` or such.
  final Decoration? decoration;

  /// The background color of the page.
  final Color? backgroundColor;

  /// The callback to calculate the size of the page based on the size of the widget.
  final PdfPageViewSizeCallback? pageSizeCallback;

  /// The builder to build a widget that wraps the page image.
  ///
  /// It replaces the default decoration builder such as background color
  /// and drop-shadow.
  final PdfPageViewDecorationBuilder? decorationBuilder;

  /// Whether to use progressive loading for the page.
  ///
  /// When true, the page will render progressively using the page's actual
  /// aspect ratio from the start.
  final bool useProgressiveLoading;

  /// Whether to load only the target page.
  ///
  /// When true with useProgressiveLoading, only the specified page will be loaded
  /// from the PDF document, which is more efficient for large PDFs when you only
  /// need to display a single page.
  final bool loadOnlyTargetPage;

  @override
  State<PdfPageView> createState() => _PdfPageViewState();
}

class _PdfPageViewState extends State<PdfPageView> {
  ui.Image? _image;
  Size? _pageSize;
  PdfPageRenderCancellationToken? _cancellationToken;

  @override
  void initState() {
    super.initState();
    pdfrxFlutterInitialize();
    
    // If loadOnlyTargetPage is enabled, ensure the target page is loaded
    if (widget.loadOnlyTargetPage && widget.document != null) {
      _ensureTargetPageLoaded();
    }
  }
  
  void _ensureTargetPageLoaded() {
    final document = widget.document;
    if (document != null && widget.pageNumber > 0 && widget.pageNumber <= document.pages.length) {
      final targetPage = document.pages[widget.pageNumber - 1];
      if (!targetPage.isLoaded) {
        // Load pages progressively starting from the target page
        document.loadPagesProgressively();
      }
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    _cancellationToken?.cancel();
    super.dispose();
  }

  Widget _defaultDecorationBuilder(BuildContext context, Size pageSize, PdfPage page, RawImage? pageImage) {
    return Align(
      alignment: widget.alignment,
      child: AspectRatio(
        aspectRatio: pageSize.width / pageSize.height,
        child: Stack(
          children: [
            Container(
              decoration:
                  widget.decoration ??
                  BoxDecoration(
                    color: pageImage == null ? widget.backgroundColor ?? Colors.white : Colors.transparent,
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(2, 2))],
                  ),
            ),
            if (pageImage != null) pageImage,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final query = MediaQuery.of(context);
        
        if (widget.useProgressiveLoading) {
          _updateImageProgressive(constraints.biggest * query.devicePixelRatio);
        } else {
          _updateImage(constraints.biggest * query.devicePixelRatio);
        }

        if (_pageSize != null) {
          final decorationBuilder = widget.decorationBuilder ?? _defaultDecorationBuilder;
          final scale = min(constraints.maxWidth / _pageSize!.width, constraints.maxHeight / _pageSize!.height);
          return decorationBuilder(
            context,
            _pageSize!,
            widget.document!.pages[widget.pageNumber - 1],
            _image != null
                ? RawImage(
                  image: _image,
                  width: _pageSize!.width * scale,
                  height: _pageSize!.height * scale,
                  fit: BoxFit.fill,
                )
                : null,
          );
        }
        return const SizedBox();
      },
    );
  }

  Future<void> _updateImage(Size size) async {
    final document = widget.document;
    if (document == null || widget.pageNumber < 1 || widget.pageNumber > document.pages.length || size.isEmpty) {
      return;
    }
    final page = document.pages[widget.pageNumber - 1];

    final Size pageSize;
    if (widget.pageSizeCallback != null) {
      pageSize = widget.pageSizeCallback!(size, page);
    } else {
      final scale = min(widget.maximumDpi / 72, min(size.width / page.width, size.height / page.height));
      pageSize = Size(page.width * scale, page.height * scale);
    }

    if (pageSize == _pageSize) return;
    _pageSize = pageSize;

    _cancellationToken?.cancel();
    _cancellationToken = page.createCancellationToken();
    final pageImage = await page.render(
      fullWidth: pageSize.width,
      fullHeight: pageSize.height,
      cancellationToken: _cancellationToken,
    );
    if (pageImage == null) return;
    try {
      final newImage = await pageImage.createImage();
      pageImage.dispose();
      _image = newImage;
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      developer.log('Error creating image: $e');
      pageImage.dispose();
    }
  }

  Future<void> _updateImageProgressive(Size size) async {
    final document = widget.document;
    if (document == null || widget.pageNumber < 1 || widget.pageNumber > document.pages.length || size.isEmpty) {
      return;
    }
    final page = document.pages[widget.pageNumber - 1];

    // Calculate page size based on the page's actual aspect ratio
    final Size pageSize;
    if (widget.pageSizeCallback != null) {
      pageSize = widget.pageSizeCallback!(size, page);
    } else {
      final scale = min(widget.maximumDpi / 72, min(size.width / page.width, size.height / page.height));
      pageSize = Size(page.width * scale, page.height * scale);
    }

    // Always set the page size immediately to ensure correct aspect ratio
    if (_pageSize == null) {
      _pageSize = pageSize;
      if (mounted) {
        setState(() {});
      }
    }

    if (pageSize == _pageSize) return;
    _pageSize = pageSize;

    // Cancel previous loading
    _cancellationToken?.cancel();
    _cancellationToken = page.createCancellationToken();

    // Render the page with progressive approach (multiple quality levels)
    _renderPageProgressive(page, pageSize);
  }

  Future<void> _renderPageProgressive(PdfPage page, Size pageSize) async {
    // First render a low quality preview quickly
    final lowQualityScale = 0.25;
    final lowQualitySize = Size(
      pageSize.width * lowQualityScale,
      pageSize.height * lowQualityScale,
    );
    
    try {
      final lowQualityImage = await page.render(
        fullWidth: lowQualitySize.width,
        fullHeight: lowQualitySize.height,
        cancellationToken: _cancellationToken,
      );
      
      if (lowQualityImage != null && !_cancellationToken!.isCanceled) {
        final image = await lowQualityImage.createImage();
        lowQualityImage.dispose();
        _image?.dispose();
        _image = image;
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      developer.log('Error rendering low quality image: $e');
    }

    // Then render full quality
    if (!_cancellationToken!.isCanceled) {
      try {
        final fullQualityImage = await page.render(
          fullWidth: pageSize.width,
          fullHeight: pageSize.height,
          cancellationToken: _cancellationToken,
        );
        
        if (fullQualityImage != null && !_cancellationToken!.isCanceled) {
          final image = await fullQualityImage.createImage();
          fullQualityImage.dispose();
          _image?.dispose();
          _image = image;
          if (mounted) {
            setState(() {});
          }
        }
      } catch (e) {
        developer.log('Error rendering full quality image: $e');
      }
    }
  }
}
