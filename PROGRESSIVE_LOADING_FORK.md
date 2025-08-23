# PDFrx Progressive Loading Fork

A fork of [pdfrx](https://github.com/espresso3389/pdfrx) with added progressive loading support for better PDF rendering performance.

## 🎯 Features

This fork adds two simple but powerful features to pdfrx:

### 1. Progressive Loading (`useProgressiveLoading`)
- Renders PDF pages in two passes: low quality first (25%), then full quality
- Shows correct aspect ratio immediately
- Better user experience for large PDFs

### 2. Load Only Target Page (`loadOnlyTargetPage`)
- Optimizes memory usage by loading only the displayed page
- Useful for large PDF documents

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  pdfrx:
    git:
      url: https://github.com/YOUR_USERNAME/pdfrx.git
      path: packages/pdfrx
      ref: progressive-loading  # or use specific commit hash
```

## 🚀 Usage

### Basic Usage (same as official version)
```dart
import 'package:pdfrx/pdfrx.dart';

// Standard usage - works exactly like official pdfrx
PdfViewer.uri(
  Uri.parse('https://example.com/document.pdf'),
)
```

### Progressive Loading
```dart
// Enable progressive rendering
PdfPageView(
  document: document,
  pageNumber: 1,
  useProgressiveLoading: true,  // New feature!
)
```

### Complete Example
```dart
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class MyPdfViewer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PdfDocumentViewBuilder.uri(
      Uri.parse('https://example.com/document.pdf'),
      builder: (context, document) {
        if (document == null) {
          return Center(child: CircularProgressIndicator());
        }
        
        return PdfPageView(
          document: document,
          pageNumber: 1,
          useProgressiveLoading: true,  // Progressive rendering
          loadOnlyTargetPage: true,     // Memory optimization
        );
      },
    );
  }
}
```

## 📝 What's Changed

### Modified Files
- `packages/pdfrx/lib/src/widgets/pdf_widgets.dart` - Added progressive loading logic

### New Parameters
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `useProgressiveLoading` | `bool` | `false` | Enable progressive rendering |
| `loadOnlyTargetPage` | `bool` | `false` | Load only the current page |

## ✅ Compatibility

- ✅ **100% backward compatible** - All existing code works without changes
- ✅ **Minimal changes** - Only one file modified
- ✅ **Optional features** - New parameters are optional with defaults

## 🔄 Switching Between Versions

### Use this fork:
```yaml
pdfrx:
  git:
    url: https://github.com/YOUR_USERNAME/pdfrx.git
    path: packages/pdfrx
```

### Switch back to official:
```yaml
pdfrx: ^2.1.3
```

## 🛠️ Development

### Clone and use locally:
```bash
git clone https://github.com/YOUR_USERNAME/pdfrx.git
cd your_flutter_app
```

Then in your `pubspec.yaml`:
```yaml
pdfrx:
  path: /path/to/pdfrx/packages/pdfrx
```

### Stay updated with upstream:
```bash
git remote add upstream https://github.com/espresso3389/pdfrx.git
git fetch upstream
git merge upstream/master
```

## 📊 Performance Benefits

- **Faster initial display**: Low quality preview appears quickly
- **Correct aspect ratio**: No layout shift during loading
- **Memory efficient**: Optional single page loading
- **Smooth UX**: Progressive quality improvement

## 🐛 Troubleshooting

If you encounter build errors:
```bash
flutter clean
flutter pub cache clean
flutter pub get
```

## 📄 License

This fork maintains the same license as the original pdfrx project.

## 🙏 Credits

Original pdfrx by [@espresso3389](https://github.com/espresso3389)

## 🤝 Contributing

Feel free to open issues or submit PRs for improvements!

---

**Note**: This is an unofficial fork. For the official pdfrx, visit [https://github.com/espresso3389/pdfrx](https://github.com/espresso3389/pdfrx)