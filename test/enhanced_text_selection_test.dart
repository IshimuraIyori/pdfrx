import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
  group('Enhanced Text Selection', () {
    test('PdfDocumentTextSelection basic functionality', () {
      // Mock document for testing
      final mockDocument = _MockPdfDocument();
      final documentSelection = PdfDocumentTextSelection(mockDocument);

      // Test initial state
      expect(documentSelection.hasSelection, false);
      expect(documentSelection.pages.length, 3); // Mock has 3 pages

      // Test select all
      documentSelection.selectAll();
      expect(documentSelection.hasSelection, true);

      // Test clear
      documentSelection.clearAllSelections();
      expect(documentSelection.hasSelection, false);
    });

    test('PdfPageTextSelection state management', () {
      final pageSelection = PdfPageTextSelection(1);

      // Test initial state
      expect(pageSelection.pageNumber, 1);
      expect(pageSelection.state, PdfPageSelectionState.none);
      expect(pageSelection.isTextLoaded, false);
      expect(pageSelection.ranges, isEmpty);

      // Test select all
      pageSelection.selectAll();
      expect(pageSelection.state, PdfPageSelectionState.selectAll);

      // Test partial selection
      pageSelection.clearSelection();
      pageSelection.addRange(PdfTextRange(start: 0, end: 10));
      expect(pageSelection.state, PdfPageSelectionState.partial);
      expect(pageSelection.ranges.length, 1);

      // Test clear
      pageSelection.clearSelection();
      expect(pageSelection.state, PdfPageSelectionState.none);
      expect(pageSelection.ranges, isEmpty);
    });

    test('PdfTextSelectionMode enum', () {
      expect(PdfTextSelectionMode.legacy, isA<PdfTextSelectionMode>());
      expect(PdfTextSelectionMode.enhanced, isA<PdfTextSelectionMode>());
    });

    test('PdfSelectionPoint comparison', () {
      final point1 = PdfSelectionPoint(
        pageNumber: 1,
        localPosition: const Offset(10, 20),
        pageSize: const Size(100, 200),
      );

      final point2 = PdfSelectionPoint(
        pageNumber: 1,
        localPosition: const Offset(15, 20),
        pageSize: const Size(100, 200),
      );

      final point3 = PdfSelectionPoint(
        pageNumber: 2,
        localPosition: const Offset(10, 20),
        pageSize: const Size(100, 200),
      );

      expect(point1.compareTo(point2), lessThan(0)); // Same Y, but X is smaller
      expect(point1.compareTo(point3), lessThan(0)); // Different page
      expect(point2.compareTo(point1), greaterThan(0));
    });
  });
}

// Mock classes for testing
class _MockPdfDocument extends PdfDocument {
  _MockPdfDocument() : super(sourceName: 'test.pdf');

  @override
  List<PdfPage> get pages => [
    _MockPdfPage(1),
    _MockPdfPage(2),
    _MockPdfPage(3),
  ];

  @override
  PdfPermissions? get permissions => const PdfPermissions(4, 1); // Allow copying

  @override
  bool get isEncrypted => false;

  @override
  Future<void> dispose() async {}

  @override
  Future<List<PdfOutlineNode>> loadOutline() async => [];

  @override
  bool isIdenticalDocumentHandle(Object? other) => false;
}

class _MockPdfPage extends PdfPage {
  _MockPdfPage(this._pageNumber);

  final int _pageNumber;

  @override
  PdfDocument get document => _MockPdfDocument();

  @override
  int get pageNumber => _pageNumber;

  @override
  double get width => 612.0; // Standard A4 width

  @override
  double get height => 792.0; // Standard A4 height

  @override
  PdfPageRotation get rotation => PdfPageRotation.none;

  @override
  Future<PdfImage?> render({
    int x = 0,
    int y = 0,
    int? width,
    int? height,
    double? fullWidth,
    double? fullHeight,
    ui.Color? backgroundColor,
    PdfAnnotationRenderingMode annotationRenderingMode = PdfAnnotationRenderingMode.annotationAndForms,
    PdfPageRenderCancellationToken? cancellationToken,
  }) async => null;

  @override
  PdfPageRenderCancellationToken createCancellationToken() => _MockCancellationToken();

  @override
  Future<PdfPageText> loadText() async => _MockPdfPageText(_pageNumber);

  @override
  Future<List<PdfLink>> loadLinks({bool compact = false}) async => [];
}

class _MockPdfPageText extends PdfPageText {
  _MockPdfPageText(this._pageNumber);

  final int _pageNumber;

  @override
  int get pageNumber => _pageNumber;

  @override
  String get fullText => 'Sample text for page $_pageNumber';

  @override
  List<PdfPageTextFragment> get fragments => [
    PdfPageTextFragment.fromParams(
      0,
      fullText.length,
      const PdfRect(0, 100, 200, 80),
      fullText,
    ),
  ];
}

class _MockCancellationToken extends PdfPageRenderCancellationToken {
  bool _canceled = false;

  @override
  void cancel() => _canceled = true;

  @override
  bool get isCanceled => _canceled;
}