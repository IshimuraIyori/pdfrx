globalThis.pdfiumWasmSendCommand = function() {
  const worker = new Worker(globalThis.pdfiumWasmWorkerUrl);
  let requestId = 0;
  const callbacks = new Map();
  let localFontManager = null;
  let workerReady = false;
  
  worker.onmessage = (event) => {
      const data = event.data;
      if (data.type === "ready") {
        console.log("PDFium WASM worker is ready");
        workerReady = true;
        
        // Auto-initialize Local Font Access if available
        initializeLocalFontAccess();
        return;
      }
      // For command responses, match using the request id.
      if (data.id) {
        const callback = callbacks.get(data.id);
        if (callback) {
          if (data.status === "success") {
            callback.resolve(data.result);
          } else {
            callback.reject(new Error(data.error, data.cause != null ? { cause: data.cause } : undefined));
          }
          callbacks.delete(data.id);
        }
      }
    };
  
  worker.onerror = (err) => {
      console.error("Worker error:", err);
    };

  // Initialize Local Font Access API if available
  async function initializeLocalFontAccess() {
    try {
      // Check if Local Font Access API is available
      if (!('fonts' in navigator && 'query' in navigator.fonts)) {
        console.log('Local Font Access API not available');
        return false;
      }

      // Check if LocalFontManager is available
      if (!window.localFontManager) {
        console.log('LocalFontManager not loaded');
        return false;
      }

      localFontManager = window.localFontManager;
      const success = await localFontManager.initialize(worker);
      
      if (success) {
        // Enable Local Font Access in worker
        worker.postMessage({ type: 'enableLocalFontAccess' });
        console.log('Local Font Access enabled for PDFium WASM');
        return true;
      } else {
        console.log('Failed to initialize Local Font Access');
        return false;
      }
    } catch (error) {
      console.warn('Local Font Access initialization failed:', error);
      return false;
    }
  }

  // Expose function to manually initialize Local Font Access
  globalThis.pdfiumInitializeLocalFontAccess = initializeLocalFontAccess;

  // Expose function to get available fonts
  globalThis.pdfiumGetAvailableFonts = function() {
    return localFontManager ? localFontManager.getAvailableFonts() : [];
  };

  // Expose function to check if font is available
  globalThis.pdfiumIsFontAvailable = function(fontName) {
    return localFontManager ? localFontManager.isFontAvailable(fontName) : false;
  };

  return function(command, parameters = {}, transfer = []) {
    return new Promise((resolve, reject) => {
      const id = ++requestId;
      callbacks.set(id, { resolve, reject });
      worker.postMessage({ id, command, parameters }, transfer);
    });};
}();
