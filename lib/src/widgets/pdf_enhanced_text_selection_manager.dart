import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../pdfrx.dart';
import 'pdf_document_text_selection.dart';

/// Callback for text selection changes in the enhanced selection system
typedef PdfEnhancedTextSelectionChangeCallback = void Function(PdfDocumentTextSelection selection);

/// Enhanced text selection manager that handles document-level selection
/// without relying on Flutter's SelectableRegion
class PdfEnhancedTextSelectionManager extends ChangeNotifier {
  PdfEnhancedTextSelectionManager({
    required this.document,
    this.onSelectionChange,
  }) : _documentSelection = PdfDocumentTextSelection(document);

  /// Associated PDF document
  final PdfDocument document;

  /// Callback for selection changes
  final PdfEnhancedTextSelectionChangeCallback? onSelectionChange;

  /// Document-level text selection
  final PdfDocumentTextSelection _documentSelection;

  /// Current selection start point (in document coordinates)
  PdfSelectionPoint? _selectionStart;

  /// Current selection end point (in document coordinates)
  PdfSelectionPoint? _selectionEnd;

  /// Whether a selection is currently in progress
  bool _isSelecting = false;

  /// Whether we're in select-all mode
  bool _isSelectAllMode = false;

  /// Get the document selection
  PdfDocumentTextSelection get documentSelection => _documentSelection;

  /// Check if there's any selection
  bool get hasSelection => _documentSelection.hasSelection;

  /// Start a new selection at the given point
  void startSelection(PdfSelectionPoint point) {
    _selectionStart = point;
    _selectionEnd = point;
    _isSelecting = true;
    _isSelectAllMode = false;
    
    // Clear previous selections
    _documentSelection.clearAllSelections();
    
    _updateSelection();
  }

  /// Update the end point of the current selection
  void updateSelection(PdfSelectionPoint point) {
    if (!_isSelecting) return;
    
    _selectionEnd = point;
    _updateSelection();
  }

  /// End the current selection
  void endSelection() {
    _isSelecting = false;
    notifyListeners();
  }

  /// Select all text in the document
  void selectAll() {
    _documentSelection.selectAll();
    _isSelectAllMode = true;
    _isSelecting = false;
    _selectionStart = null;
    _selectionEnd = null;
    
    _notifySelectionChange();
    notifyListeners();
  }

  /// Clear all selections
  void clearSelection() {
    _documentSelection.clearAllSelections();
    _isSelectAllMode = false;
    _isSelecting = false;
    _selectionStart = null;
    _selectionEnd = null;
    
    _notifySelectionChange();
    notifyListeners();
  }

  /// Select text at a specific point (word selection)
  Future<void> selectWordAt(PdfSelectionPoint point) async {
    try {
      final pageSelection = _documentSelection.getPageSelection(point.pageNumber);
      final pageText = await _documentSelection.loadPageText(point.pageNumber);
      
      // Find the word boundaries at the given point
      final textIndex = _findTextIndexAtPoint(pageText, point);
      if (textIndex >= 0) {
        final wordRange = _findWordBoundaries(pageText.fullText, textIndex);
        if (wordRange != null) {
          pageSelection.clearSelection();
          pageSelection.addRange(wordRange);
          
          _notifySelectionChange();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error selecting word: $e');
    }
  }

  /// Get all selected text
  Future<String> getSelectedText() async {
    return await _documentSelection.getAllSelectedText();
  }

  /// Copy selected text to clipboard
  Future<void> copySelectedText() async {
    final selectedText = await getSelectedText();
    if (selectedText.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: selectedText));
    }
  }

  /// Update the current selection based on start/end points
  void _updateSelection() {
    if (_selectionStart == null || _selectionEnd == null) return;

    try {
      _updateSelectionRanges(_selectionStart!, _selectionEnd!);
      _notifySelectionChange();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating selection: $e');
    }
  }

  /// Update selection ranges based on start and end points
  Future<void> _updateSelectionRanges(PdfSelectionPoint start, PdfSelectionPoint end) async {
    // Ensure start comes before end
    if (start.pageNumber > end.pageNumber || 
        (start.pageNumber == end.pageNumber && start.compareTo(end) > 0)) {
      final temp = start;
      start = end;
      end = temp;
    }

    // Clear all current selections
    _documentSelection.clearAllSelections();

    // Handle single page selection
    if (start.pageNumber == end.pageNumber) {
      await _selectOnPage(start.pageNumber, start, end);
    } else {
      // Handle multi-page selection
      
      // Select from start point to end of first page
      await _selectOnPage(start.pageNumber, start, null);
      
      // Select entire middle pages
      for (int pageNum = start.pageNumber + 1; pageNum < end.pageNumber; pageNum++) {
        final pageSelection = _documentSelection.getPageSelection(pageNum);
        pageSelection.selectAll();
      }
      
      // Select from beginning of last page to end point
      await _selectOnPage(end.pageNumber, null, end);
    }
  }

  /// Select text on a specific page between two points
  Future<void> _selectOnPage(int pageNumber, PdfSelectionPoint? startPoint, PdfSelectionPoint? endPoint) async {
    try {
      final pageSelection = _documentSelection.getPageSelection(pageNumber);
      final pageText = await _documentSelection.loadPageText(pageNumber);
      
      int startIndex = 0;
      int endIndex = pageText.fullText.length;
      
      if (startPoint != null) {
        startIndex = _findTextIndexAtPoint(pageText, startPoint);
        if (startIndex < 0) startIndex = 0;
      }
      
      if (endPoint != null) {
        endIndex = _findTextIndexAtPoint(pageText, endPoint);
        if (endIndex < 0) endIndex = pageText.fullText.length;
      }
      
      if (startIndex < endIndex) {
        pageSelection.clearSelection();
        pageSelection.addRange(PdfTextRange(start: startIndex, end: endIndex));
      }
    } catch (e) {
      debugPrint('Error selecting on page $pageNumber: $e');
    }
  }

  /// Find the text index at a given point on a page
  int _findTextIndexAtPoint(PdfPageText pageText, PdfSelectionPoint point) {
    // This is a simplified implementation
    // In a real implementation, you would need to:
    // 1. Convert the point coordinates to PDF coordinates
    // 2. Find the text fragment that contains the point
    // 3. Return the text index within that fragment
    
    // For now, return a simple approximation based on point position
    final normalizedX = point.localPosition.dx / point.pageSize.width;
    final normalizedY = point.localPosition.dy / point.pageSize.height;
    
    // Very rough approximation - divide page into grid and estimate text position
    final estimatedPosition = (normalizedY * 0.8 + normalizedX * 0.2);
    return (estimatedPosition * pageText.fullText.length).round().clamp(0, pageText.fullText.length);
  }

  /// Find word boundaries around a given text index
  PdfTextRange? _findWordBoundaries(String text, int index) {
    if (index < 0 || index >= text.length) return null;
    
    // Find start of word
    int start = index;
    while (start > 0 && !_isWordBoundary(text[start - 1])) {
      start--;
    }
    
    // Find end of word
    int end = index;
    while (end < text.length && !_isWordBoundary(text[end])) {
      end++;
    }
    
    return start < end ? PdfTextRange(start: start, end: end) : null;
  }

  /// Check if a character is a word boundary
  bool _isWordBoundary(String char) {
    return char == ' ' || char == '\n' || char == '\t' || char == '.' || char == ',' || char == ';' || char == ':';
  }

  /// Notify about selection changes
  void _notifySelectionChange() {
    onSelectionChange?.call(_documentSelection);
  }

  /// Compact text cache for visible pages
  void compactCache({Set<int>? visiblePages}) {
    _documentSelection.compact(visiblePages: visiblePages);
  }

  @override
  void dispose() {
    clearSelection();
    super.dispose();
  }
}

/// Represents a selection point in the document
class PdfSelectionPoint implements Comparable<PdfSelectionPoint> {
  const PdfSelectionPoint({
    required this.pageNumber,
    required this.localPosition,
    required this.pageSize,
  });

  /// Page number (1-based)
  final int pageNumber;
  
  /// Position relative to the page widget
  final Offset localPosition;
  
  /// Size of the page widget
  final Size pageSize;

  @override
  int compareTo(PdfSelectionPoint other) {
    if (pageNumber != other.pageNumber) {
      return pageNumber.compareTo(other.pageNumber);
    }
    
    // Compare by Y position first, then X position
    final yDiff = localPosition.dy.compareTo(other.localPosition.dy);
    if (yDiff != 0) return yDiff;
    
    return localPosition.dx.compareTo(other.localPosition.dx);
  }

  @override
  bool operator ==(Object other) {
    return other is PdfSelectionPoint &&
        other.pageNumber == pageNumber &&
        other.localPosition == localPosition &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(pageNumber, localPosition, pageSize);

  @override
  String toString() => 'PdfSelectionPoint(page: $pageNumber, pos: $localPosition)';
}

/// Enhanced text selection gesture recognizer
class PdfEnhancedTextSelectionGestureRecognizer extends OneSequenceGestureRecognizer {
  PdfEnhancedTextSelectionGestureRecognizer({
    required this.selectionManager,
    required this.getSelectionPointForOffset,
  });

  final PdfEnhancedTextSelectionManager selectionManager;
  final PdfSelectionPoint? Function(Offset globalPosition) getSelectionPointForOffset;

  @override
  String get debugDescription => 'pdf_enhanced_text_selection';

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      _handlePointerDown(event);
    } else if (event is PointerMoveEvent) {
      _handlePointerMove(event);
    } else if (event is PointerUpEvent) {
      _handlePointerUp(event);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    final point = getSelectionPointForOffset(event.position);
    if (point != null) {
      selectionManager.startSelection(point);
      resolve(GestureDisposition.accepted);
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final point = getSelectionPointForOffset(event.position);
    if (point != null) {
      selectionManager.updateSelection(point);
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    selectionManager.endSelection();
    resolve(GestureDisposition.accepted);
  }
}