globalThis.pdfiumWasmSendCommand = function() {
  const worker = new Worker(globalThis.pdfiumWasmWorkerUrl);
  let requestId = 0;
  const callbacks = new Map();
  
  // Local Font Access API support
  let localFontAccessSupported = false;
  let localFontsCache = null;
  
  // Check if Local Font Access API is supported
  if ('queryLocalFonts' in window) {
    localFontAccessSupported = true;
    console.log('Local Font Access API is supported');
  }
  
  async function enumerateLocalFonts() {
    if (!localFontAccessSupported) {
      console.warn('Local Font Access API not supported');
      return [];
    }
    
    if (localFontsCache) {
      return localFontsCache;
    }
    
    try {
      const availableFonts = await window.queryLocalFonts();
      const fontPromises = availableFonts.map(async (fontData) => {
        try {
          const blob = await fontData.blob();
          const arrayBuffer = await blob.arrayBuffer();
          return {
            name: fontData.fullName || fontData.family,
            data: arrayBuffer
          };
        } catch (err) {
          console.warn(`Failed to load font ${fontData.fullName}:`, err);
          return null;
        }
      });
      
      const fonts = (await Promise.all(fontPromises)).filter(font => font !== null);
      localFontsCache = fonts;
      console.log(`Enumerated ${fonts.length} local fonts`);
      return fonts;
    } catch (err) {
      console.error('Failed to enumerate local fonts:', err);
      return [];
    }
  }
  
  worker.onmessage = (event) => {
      const data = event.data;
      
      // Handle local font enumeration request from worker
      if (data.type === "enumerateLocalFonts") {
        enumerateLocalFonts().then(fonts => {
          worker.postMessage({
            type: 'localFontsResponse',
            fonts: fonts
          }, fonts.map(f => f.data));
        });
        return;
      }
      
      if (data.type === "ready") {
        console.log("PDFium WASM worker is ready");
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

  return function(command, parameters = {}, transfer = []) {
    return new Promise((resolve, reject) => {
      const id = ++requestId;
      callbacks.set(id, { resolve, reject });
      worker.postMessage({ id, command, parameters }, transfer);
    });};
}();
