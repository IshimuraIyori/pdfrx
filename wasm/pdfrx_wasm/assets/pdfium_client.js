globalThis.pdfiumWasmSendCommand = function() {
  const worker = new Worker(globalThis.pdfiumWasmWorkerUrl);
  let requestId = 0;
  const callbacks = new Map();

  function sendCommand(command, parameters = {}, transfer = []) {
    return new Promise((resolve, reject) => {
      const id = ++requestId;
      callbacks.set(id, { resolve, reject });
      worker.postMessage({ id, command, parameters }, transfer);
    });
  };

  async function loadFontList() {
    if (!('queryLocalFonts' in window)) return;
    try {
      const permissionStatus = await navigator.permissions.query({ name: 'local-fonts' });
      const fonts = await window.queryLocalFonts();
      const fontNames = fonts.map(font => font.postscriptName).filter(font => font != null);
      sendCommand("setLocalFontList", { fonts: fontNames });
    } catch (e) {
      console.warn('Local font access failed:', e);
      sendCommand("setLocalFontList", { fonts: [] });
    }
  }

  worker.onmessage = async (event) => {
    const data = event.data;
    if (data.type === "ready") {
      console.log("PDFium WASM worker is ready");
      return;
    } else if (data.type === "loadFontList") {
      console.log("Loading local font list...");
      loadFontList();
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

  return sendCommand;
}();
