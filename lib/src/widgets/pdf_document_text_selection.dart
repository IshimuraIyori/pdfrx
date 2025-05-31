import 'dart:collection';
import 'dart:async';

import '../../pdfrx.dart';

/// Enum to specify the text selection mode.
enum PdfTextSelectionMode {
  /// Legacy SelectableRegion-based implementation
  legacy,
  
  /// New enhanced text selection implementation
  enhanced,
}

/// Global configuration for text selection
class PdfTextSelectionConfig {
  static PdfTextSelectionMode mode = PdfTextSelectionMode.legacy;
}

/// State of a page selection for the enhanced text selection system.
enum PdfPageSelectionState {
  /// No selection
  none,
  /// Some text selected
  partial,
  /// Entire page selected (may not be loaded)
  selectAll,
}

/// Text selection for a single page with lazy loading capability.
class PdfPageTextSelection {
  PdfPageTextSelection(this.pageNumber);

  /// Page number (1-based)
  final int pageNumber;

  /// Cached text data, loaded on demand
  PdfPageText? _text;

  /// Current selection ranges
  final List<PdfTextRange> _ranges = <PdfTextRange>[];

  /// Current selection state
  PdfPageSelectionState _state = PdfPageSelectionState.none;

  /// Get the current selection ranges
  List<PdfTextRange> get ranges => List.unmodifiable(_ranges);

  /// Get the current selection state
  PdfPageSelectionState get state => _state;

  /// Whether the text is loaded or not
  bool get isTextLoaded => _text != null;

  /// Get the loaded text (if any)
  PdfPageText? get text => _text;

  /// Explicitly load the text
  Future<PdfPageText> loadText(PdfPage page) async {
    _text ??= await page.loadText();
    return _text!;
  }

  /// Unload text but keep selection ranges
  void unloadText() {
    _text = null;
  }

  /// Set selection ranges
  void setRanges(List<PdfTextRange> ranges) {
    _ranges.clear();
    _ranges.addAll(ranges);
    _updateState();
  }

  /// Add a selection range
  void addRange(PdfTextRange range) {
    _ranges.add(range);
    _updateState();
  }

  /// Clear all selection ranges
  void clearSelection() {
    _ranges.clear();
    _state = PdfPageSelectionState.none;
  }

  /// Select all text on this page
  void selectAll() {
    _state = PdfPageSelectionState.selectAll;
    // Note: We don't set ranges here since text might not be loaded
    // Ranges will be populated when text is actually loaded
  }

  /// Update state based on current ranges
  void _updateState() {
    if (_ranges.isEmpty) {
      _state = PdfPageSelectionState.none;
    } else if (_text != null && _ranges.length == 1 && 
               _ranges.first.start == 0 && _ranges.first.end == _text!.fullText.length) {
      _state = PdfPageSelectionState.selectAll;
    } else {
      _state = PdfPageSelectionState.partial;
    }
  }

  /// Get selected text if text is loaded
  String? getSelectedText() {
    if (_text == null || _ranges.isEmpty) return null;
    
    if (_state == PdfPageSelectionState.selectAll) {
      return _text!.fullText;
    }

    final buffer = StringBuffer();
    for (final range in _ranges) {
      buffer.write(_text!.fullText.substring(range.start, range.end));
    }
    return buffer.toString();
  }

  /// Create ranges for select all when text is loaded
  void _populateSelectAllRanges() {
    if (_state == PdfPageSelectionState.selectAll && _text != null) {
      _ranges.clear();
      _ranges.add(PdfTextRange(start: 0, end: _text!.fullText.length));
    }
  }

  /// Called when text is loaded to update ranges if needed
  void _onTextLoaded() {
    if (_state == PdfPageSelectionState.selectAll) {
      _populateSelectAllRanges();
    }
  }
}

/// Document-level text selection manager for the enhanced text selection system.
class PdfDocumentTextSelection {
  PdfDocumentTextSelection(this.document);

  /// Associated PDF document
  final PdfDocument document;

  /// Page selections, indexed by page number (1-based)
  final Map<int, PdfPageTextSelection> _pages = <int, PdfPageTextSelection>{};

  /// Maximum number of pages to keep text loaded in memory
  static const int _maxLoadedPages = 5;

  /// List of currently loaded page numbers for cache management
  final Queue<int> _loadedPagesQueue = Queue<int>();

  /// Get page selections
  List<PdfPageTextSelection> get pages {
    final result = <PdfPageTextSelection>[];
    for (int i = 1; i <= document.pages.length; i++) {
      result.add(_getOrCreatePageSelection(i));
    }
    return result;
  }

  /// Get or create page selection for a specific page number
  PdfPageTextSelection _getOrCreatePageSelection(int pageNumber) {
    return _pages.putIfAbsent(pageNumber, () => PdfPageTextSelection(pageNumber));
  }

  /// Get page selection for a specific page number
  PdfPageTextSelection getPageSelection(int pageNumber) {
    return _getOrCreatePageSelection(pageNumber);
  }

  /// Clear all selections
  void clearAllSelections() {
    for (final pageSelection in _pages.values) {
      pageSelection.clearSelection();
    }
  }

  /// Select all text in the document
  void selectAll() {
    for (int i = 1; i <= document.pages.length; i++) {
      final pageSelection = _getOrCreatePageSelection(i);
      pageSelection.selectAll();
    }
  }

  /// Load text for a specific page and manage cache
  Future<PdfPageText> loadPageText(int pageNumber) async {
    final pageSelection = _getOrCreatePageSelection(pageNumber);
    final page = document.pages[pageNumber - 1];
    
    if (!pageSelection.isTextLoaded) {
      await pageSelection.loadText(page);
      pageSelection._onTextLoaded();
      
      // Add to cache queue
      _loadedPagesQueue.addLast(pageNumber);
      
      // Manage cache size
      while (_loadedPagesQueue.length > _maxLoadedPages) {
        final oldestPage = _loadedPagesQueue.removeFirst();
        final oldestPageSelection = _pages[oldestPage];
        oldestPageSelection?.unloadText();
      }
    }
    
    return pageSelection.text!;
  }

  /// Get all selected text ranges across all pages
  List<PdfTextRanges> getAllSelectedRanges() {
    final result = <PdfTextRanges>[];
    
    for (final pageSelection in _pages.values) {
      if (pageSelection.ranges.isNotEmpty && pageSelection.text != null) {
        result.add(PdfTextRanges(
          pageText: pageSelection.text!,
          ranges: pageSelection.ranges,
        ));
      }
    }
    
    return result;
  }

  /// Get all selected text
  Future<String> getAllSelectedText() async {
    final buffer = StringBuffer();
    
    for (int i = 1; i <= document.pages.length; i++) {
      final pageSelection = _pages[i];
      if (pageSelection != null && pageSelection.state != PdfPageSelectionState.none) {
        // Load text if needed
        if (!pageSelection.isTextLoaded) {
          await loadPageText(i);
        }
        
        final selectedText = pageSelection.getSelectedText();
        if (selectedText != null && selectedText.isNotEmpty) {
          if (buffer.isNotEmpty) {
            buffer.write('\n'); // Add page separator
          }
          buffer.write(selectedText);
        }
      }
    }
    
    return buffer.toString();
  }

  /// Compact cache - unload text from pages not currently visible
  void compact({Set<int>? visiblePages}) {
    if (visiblePages == null) {
      // Unload all pages
      for (final pageSelection in _pages.values) {
        pageSelection.unloadText();
      }
      _loadedPagesQueue.clear();
    } else {
      // Unload pages not in visible set
      final pagesToUnload = <int>[];
      for (final pageNumber in _loadedPagesQueue) {
        if (!visiblePages.contains(pageNumber)) {
          pagesToUnload.add(pageNumber);
        }
      }
      
      for (final pageNumber in pagesToUnload) {
        final pageSelection = _pages[pageNumber];
        pageSelection?.unloadText();
        _loadedPagesQueue.remove(pageNumber);
      }
    }
  }

  /// Check if any page has selection
  bool get hasSelection {
    return _pages.values.any((page) => page.state != PdfPageSelectionState.none);
  }

  /// Check if all visible pages are selected
  bool areAllPagesSelected({Set<int>? visiblePages}) {
    final pagesToCheck = visiblePages ?? Set.from(List.generate(document.pages.length, (i) => i + 1));
    
    for (final pageNumber in pagesToCheck) {
      final pageSelection = _pages[pageNumber];
      if (pageSelection == null || pageSelection.state != PdfPageSelectionState.selectAll) {
        return false;
      }
    }
    
    return true;
  }
}