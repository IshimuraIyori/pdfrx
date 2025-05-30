# Local Font Access API Integration for PDFium WASM

This implementation provides integration between PDFium WASM and the browser's Local Font Access API, allowing PDF documents to use fonts installed locally on the user's system.

## Features

- **Client-side font access**: Uses Local Font Access API on the main thread (not in worker)
- **Seamless integration**: Modifies FileSystemEmulator directly without inheritance
- **Safe message handling**: Carefully handles onmessage to avoid conflicts with PDFium processing
- **Automatic font detection**: Intercepts font requests to `/usr/share/fonts/` and redirects to local fonts
- **Permission handling**: Properly requests and manages Local Font Access API permissions
- **Fallback support**: Gracefully falls back when API is not supported

## Browser Requirements

- **Chrome 103+** with Local Font Access API support
- **HTTPS or localhost** (required for Local Font Access API)
- **Origin Trial Token** or **Feature Flag** enabled (depending on browser version)

## Usage

### 1. Include the Local Font Manager

```html
<script src="local_font_manager.js"></script>
```

### 2. Initialize Local Font Access

```javascript
// Create PDFium worker
const worker = new Worker('pdfium_worker.js');

// Wait for worker to be ready
await new Promise((resolve) => {
    worker.onmessage = function(e) {
        if (e.data.type === 'ready') {
            resolve();
        }
    };
});

// Initialize Local Font Manager
const localFontManager = window.localFontManager;
const success = await localFontManager.initialize(worker);

if (success) {
    // Enable Local Font Access in worker
    worker.postMessage({ type: 'enableLocalFontAccess' });
    console.log('Local Font Access enabled');
} else {
    console.warn('Local Font Access not available');
}
```

### 3. Load PDF Documents

Once initialized, PDF documents that reference fonts in `/usr/share/fonts/` will automatically use locally installed fonts:

```javascript
// Load PDF document (existing API)
const response = await fetch('document.pdf');
const pdfData = await response.arrayBuffer();

// The PDF will automatically use local fonts when available
const result = await callWorker('loadDocumentFromData', {
    data: pdfData
});
```

## Implementation Details

### Architecture

```
Main Thread                    Worker Thread
┌─────────────────┐           ┌─────────────────┐
│ Local Font      │  ◄────────┤ FileSystem      │
│ Manager         │           │ Emulator        │
└─────────────────┘           └─────────────────┘
         │                             │
         ▼                             ▼
┌─────────────────┐           ┌─────────────────┐
│ Local Font      │           │ PDFium WASM     │
│ Access API      │           │                 │
└─────────────────┘           └─────────────────┘
```

### Font Request Flow

1. **PDFium requests font**: PDFium tries to open `/usr/share/fonts/Arial.ttf`
2. **FileSystemEmulator intercepts**: Detects font path pattern
3. **Worker requests font**: Sends `fontRequest` message to main thread
4. **Main thread handles**: LocalFontManager queries Local Font Access API
5. **Font data returned**: ArrayBuffer transferred back to worker
6. **PDFium receives font**: Font data is available for rendering

### Key Components

#### LocalFontManager (Client-side)
- Manages Local Font Access API permissions
- Enumerates available fonts
- Handles font data requests from worker
- Caches font data for performance

#### FileSystemEmulator (Worker-side)
- Intercepts font file requests
- Creates special file descriptors for font files
- Asynchronously loads font data on demand
- Maintains compatibility with existing PDFium code

## Error Handling

The implementation includes comprehensive error handling:

- **API not supported**: Graceful fallback without Local Font Access
- **Permission denied**: Clear error messages and fallback behavior
- **Font not found**: Proper error reporting when requested font is unavailable
- **Timeout handling**: Prevents hanging on slow font requests

## Security Considerations

- **Same-origin policy**: Local Font Access API respects same-origin restrictions
- **User permission**: Users must grant permission to access local fonts
- **Privacy**: Font enumeration is limited to prevent fingerprinting
- **Sandboxing**: Worker thread remains sandboxed

## Performance Optimizations

- **Font caching**: Font data is cached to avoid repeated API calls
- **Lazy loading**: Font data is loaded only when requested by PDFium
- **Transfer objects**: ArrayBuffers are transferred (not copied) between threads
- **Async processing**: Font loading doesn't block PDFium operations

## Debugging

Enable debug logging by setting:

```javascript
// In browser console
localStorage.setItem('pdfrx_debug', 'true');
```

This will show:
- Font request/response cycles
- Local Font Access API calls
- Error conditions and fallbacks

## Limitations

- **Browser support**: Limited to browsers with Local Font Access API
- **Font formats**: Depends on fonts supported by both browser and PDFium
- **Permission UI**: Browser may show permission prompts to users
- **API stability**: Local Font Access API is still evolving

## Example

See `local_font_example.html` for a complete working example demonstrating:
- Browser capability detection
- Local Font Access initialization
- Font enumeration display
- PDF loading with local fonts

## Troubleshooting

### "Local Font Access API not supported"
- Use Chrome 103+ or compatible browser
- Enable Local Font Access feature flag if needed
- Ensure HTTPS or localhost origin

### "Permission denied"
- User needs to grant font access permission
- Check browser's site settings for font permissions

### "Font request timeout"
- Font may not be available locally
- Check font name mapping between PDF and system fonts
- Verify Local Font Access API is working correctly

### "Worker initialization failed"
- Check browser console for detailed error messages
- Ensure all required files are accessible
- Verify web server supports proper MIME types for .wasm files