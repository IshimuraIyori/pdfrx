/**
 * Client-side Local Font Access API manager for PDFium WASM
 * 
 * This module manages font access using the Local Font Access API on the main thread
 * and communicates font data to the worker thread when requested.
 */

class LocalFontManager {
  constructor() {
    this.availableFonts = new Map(); // fontName -> FontData
    this.fontDataCache = new Map(); // fontName -> ArrayBuffer
    this.pendingFontRequests = new Map(); // requestId -> {resolve, reject}
    this.worker = null;
    this.requestId = 0;
    this.isInitialized = false;
    this.permissionGranted = false;
  }

  /**
   * Initialize the Local Font Access API
   * @param {Worker} worker - The PDFium worker instance
   * @returns {Promise<boolean>} - True if successfully initialized
   */
  async initialize(worker) {
    this.worker = worker;
    
    if (!this.isLocalFontAccessSupported()) {
      console.warn('Local Font Access API is not supported in this browser');
      return false;
    }

    try {
      // Request permission and get available fonts
      const fonts = await navigator.fonts.query();
      
      for (const font of fonts) {
        this.availableFonts.set(font.postscriptName, font);
        // Also index by family name for easier lookup
        this.availableFonts.set(font.family, font);
      }
      
      this.permissionGranted = true;
      this.isInitialized = true;
      
      // Set up message handler for font requests from worker
      this.setupWorkerMessageHandler();
      
      console.log(`Local Font Access initialized with ${fonts.length} fonts`);
      return true;
    } catch (error) {
      console.warn('Failed to initialize Local Font Access API:', error);
      return false;
    }
  }

  /**
   * Check if Local Font Access API is supported
   * @returns {boolean}
   */
  isLocalFontAccessSupported() {
    return 'fonts' in navigator && 'query' in navigator.fonts;
  }

  /**
   * Set up message handler to intercept font requests from worker
   */
  setupWorkerMessageHandler() {
    if (!this.worker) return;

    // Store original onmessage handler
    const originalOnMessage = this.worker.onmessage;
    
    this.worker.onmessage = (event) => {
      const data = event.data;
      
      // Check if this is a font request from our modified FileSystemEmulator
      if (data && data.type === 'fontRequest') {
        this.handleFontRequest(data);
        return;
      }
      
      // Forward all other messages to original handler
      if (originalOnMessage) {
        originalOnMessage.call(this.worker, event);
      }
    };
  }

  /**
   * Handle font data request from worker
   * @param {Object} data - Font request data
   */
  async handleFontRequest(data) {
    const { requestId, fontPath } = data;
    
    try {
      const fontData = await this.getFontData(fontPath);
      
      this.worker.postMessage({
        type: 'fontResponse',
        requestId,
        success: true,
        data: fontData
      }, [fontData]); // Transfer ownership
      
    } catch (error) {
      this.worker.postMessage({
        type: 'fontResponse',
        requestId,
        success: false,
        error: error.message
      });
    }
  }

  /**
   * Get font data for a given font path
   * @param {string} fontPath - Path like /usr/share/fonts/fontname.ttf
   * @returns {Promise<ArrayBuffer>} - Font data
   */
  async getFontData(fontPath) {
    if (!this.isInitialized || !this.permissionGranted) {
      throw new Error('Local Font Access not initialized or permission denied');
    }

    // Extract font name from path
    const fontName = this.extractFontNameFromPath(fontPath);
    
    // Check cache first
    if (this.fontDataCache.has(fontName)) {
      const cachedData = this.fontDataCache.get(fontName);
      // Return a copy since we transfer ownership
      return cachedData.slice();
    }

    // Find the font in available fonts
    const font = this.availableFonts.get(fontName);
    if (!font) {
      throw new Error(`Font not found: ${fontName}`);
    }

    try {
      // Get font data using Local Font Access API
      const fontData = await font.blob();
      const arrayBuffer = await fontData.arrayBuffer();
      
      // Cache the data
      this.fontDataCache.set(fontName, arrayBuffer);
      
      // Return a copy since we transfer ownership
      return arrayBuffer.slice();
    } catch (error) {
      throw new Error(`Failed to load font data for ${fontName}: ${error.message}`);
    }
  }

  /**
   * Extract font name from file path
   * @param {string} fontPath - Full path like /usr/share/fonts/Arial.ttf
   * @returns {string} - Font name like Arial
   */
  extractFontNameFromPath(fontPath) {
    // Remove directory and extension
    const fileName = fontPath.split('/').pop();
    const fontName = fileName.replace(/\.(ttf|otf|woff|woff2)$/i, '');
    return fontName;
  }

  /**
   * Get list of available fonts
   * @returns {Array<string>} - Array of font names
   */
  getAvailableFonts() {
    return Array.from(this.availableFonts.keys());
  }

  /**
   * Check if a specific font is available
   * @param {string} fontName - Font name to check
   * @returns {boolean}
   */
  isFontAvailable(fontName) {
    return this.availableFonts.has(fontName);
  }
}

// Global instance
window.localFontManager = new LocalFontManager();

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
  module.exports = LocalFontManager;
}