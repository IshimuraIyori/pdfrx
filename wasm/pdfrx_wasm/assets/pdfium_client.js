
async function getLocalFontData(fontName) {
  if (!('queryLocalFonts' in window)) return null;
  try {
    const fonts = await window.queryLocalFonts();
    for (const font of fonts) {
      if (font.fullName === fontName || font.postscriptName === fontName || font.family === fontName) {
        const blob = await font.blob();
        return await blob.arrayBuffer();
      }
    }
  } catch (e) {
    console.warn('Local font access failed:', e);
  }
  return null;
}

globalThis.pdfiumWasmSendCommand = function() {
  const worker = new Worker(globalThis.pdfiumWasmWorkerUrl);
  let requestId = 0;
  const callbacks = new Map();

  // Font request handler
  worker.fontRequestSync = function(fontName) {
    // This is a synchronous stub. In practice, you may want to implement a sync/async bridge if needed.
    // For now, we only support async font loading via message passing.
    // This function is not used directly in the client, but the worker expects it.
    return null;
  };


  worker.onmessage = async (event) => {
    const data = event.data;
    if (data.type === "ready") {
      console.log("PDFium WASM worker is ready");
      return;
    }
    // Handle font data requests from the worker
    if (data.type === 'font-request' && data.fontName && data.buffer) {
      const fontData = await getLocalFontData(data.fontName);
      if (fontData && data.buffer) {
        // Write font data into the provided SharedArrayBuffer
        const fontBytes = new Uint8Array(fontData);
        const view = new Uint8Array(data.buffer);
        view.set(fontBytes, 4); // leave first 4 bytes for status/length
        // Write length to first 4 bytes (as Int32)
        new Int32Array(data.buffer, 0, 1)[0] = fontBytes.length;
        Atomics.notify(new Int32Array(data.buffer, 0, 1), 0);
      } else {
        // No font data found, set status to 0
        new Int32Array(data.buffer, 0, 1)[0] = 0;
        Atomics.notify(new Int32Array(data.buffer, 0, 1), 0);
      }
      // Also send a message for fallback (not strictly needed)
      worker.postMessage({ type: 'font-response', fontName: data.fontName, fontData });
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
    });
  };
}();
