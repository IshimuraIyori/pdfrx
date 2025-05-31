import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../pdfrx.dart';
import 'pdf_document_text_selection.dart';
import 'pdf_enhanced_text_selection_manager.dart';

/// Enhanced text selection overlay that handles visual selection rendering
/// for the new text selection system
class PdfEnhancedTextSelectionOverlay extends StatefulWidget {
  const PdfEnhancedTextSelectionOverlay({
    required this.page,
    required this.pageRect,
    required this.selectionManager,
    required this.selectionColor,
    required this.enabled,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final PdfPage page;
  final Rect pageRect;
  final PdfEnhancedTextSelectionManager selectionManager;
  final Color selectionColor;
  final bool enabled;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<PdfEnhancedTextSelectionOverlay> createState() => _PdfEnhancedTextSelectionOverlayState();
}

class _PdfEnhancedTextSelectionOverlayState extends State<PdfEnhancedTextSelectionOverlay> {
  PdfPageTextSelection? _pageSelection;
  List<Rect> _selectionRects = [];
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _updatePageSelection();
    widget.selectionManager.addListener(_onSelectionChanged);
  }

  @override
  void didUpdateWidget(PdfEnhancedTextSelectionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.page != oldWidget.page || widget.selectionManager != oldWidget.selectionManager) {
      oldWidget.selectionManager.removeListener(_onSelectionChanged);
      widget.selectionManager.addListener(_onSelectionChanged);
      _updatePageSelection();
    }
  }

  @override
  void dispose() {
    widget.selectionManager.removeListener(_onSelectionChanged);
    super.dispose();
  }

  void _updatePageSelection() {
    _pageSelection = widget.selectionManager.documentSelection.getPageSelection(widget.page.pageNumber);
    _updateSelectionRects();
  }

  void _onSelectionChanged() {
    if (mounted) {
      _updateSelectionRects();
      setState(() {});
    }
  }

  void _updateSelectionRects() {
    _selectionRects.clear();
    
    if (_pageSelection == null || !widget.enabled) return;
    
    // Handle different selection states
    switch (_pageSelection!.state) {
      case PdfPageSelectionState.none:
        break;
        
      case PdfPageSelectionState.selectAll:
        // Show full page selection
        _selectionRects.add(Rect.fromLTWH(0, 0, widget.pageRect.width, widget.pageRect.height));
        break;
        
      case PdfPageSelectionState.partial:
        // Calculate selection rectangles from text ranges
        _calculateSelectionRects();
        break;
    }
  }

  void _calculateSelectionRects() {
    if (_pageSelection?.text == null || _pageSelection!.ranges.isEmpty) return;
    
    final pageText = _pageSelection!.text!;
    final pageSize = widget.pageRect.size;
    
    for (final range in _pageSelection!.ranges) {
      final textRange = range.toTextRangeWithFragments(pageText);
      if (textRange != null) {
        // Convert PDF coordinates to Flutter coordinates
        final pdfRect = textRange.bounds;
        final flutterRect = pdfRect.toRect(page: widget.page, scaledPageSize: pageSize);
        _selectionRects.add(flutterRect);
      }
    }
  }

  PdfSelectionPoint? _createSelectionPoint(Offset localPosition) {
    if (!widget.enabled) return null;
    
    return PdfSelectionPoint(
      pageNumber: widget.page.pageNumber,
      localPosition: localPosition,
      pageSize: widget.pageRect.size,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || widget.page.document.permissions?.allowsCopying == false) {
      return const SizedBox.expand();
    }

    return Positioned.fromRect(
      rect: widget.pageRect,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onLongPressStart: _onLongPressStart,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: MouseRegion(
          cursor: _isHovering ? SystemMouseCursors.text : MouseCursor.defer,
          onHover: _onHover,
          onExit: (_) => setState(() => _isHovering = false),
          child: CustomPaint(
            size: widget.pageRect.size,
            painter: _SelectionPainter(
              selectionRects: _selectionRects,
              selectionColor: widget.selectionColor,
            ),
            child: Container(
              width: widget.pageRect.width,
              height: widget.pageRect.height,
              color: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    
    final point = _createSelectionPoint(details.localPosition);
    if (point != null) {
      // Clear selection on tap
      widget.selectionManager.clearSelection();
      widget.onTap?.call();
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (!widget.enabled) return;
    
    final point = _createSelectionPoint(details.localPosition);
    if (point != null) {
      // Select word at point
      widget.selectionManager.selectWordAt(point);
      widget.onLongPress?.call();
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.enabled) return;
    
    final point = _createSelectionPoint(details.localPosition);
    if (point != null) {
      widget.selectionManager.startSelection(point);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enabled) return;
    
    final point = _createSelectionPoint(details.localPosition);
    if (point != null) {
      widget.selectionManager.updateSelection(point);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.enabled) return;
    
    widget.selectionManager.endSelection();
  }

  void _onHover(PointerHoverEvent event) {
    // Check if hovering over text area
    // For now, show text cursor everywhere
    setState(() => _isHovering = true);
  }
}

/// Custom painter for rendering text selection highlights
class _SelectionPainter extends CustomPainter {
  const _SelectionPainter({
    required this.selectionRects,
    required this.selectionColor,
  });

  final List<Rect> selectionRects;
  final Color selectionColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (selectionRects.isEmpty) return;

    final paint = Paint()
      ..color = selectionColor
      ..style = PaintingStyle.fill;

    for (final rect in selectionRects) {
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_SelectionPainter oldDelegate) {
    return selectionRects != oldDelegate.selectionRects ||
           selectionColor != oldDelegate.selectionColor;
  }
}