const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("native", {
  openFiles: () => ipcRenderer.invoke("open-files"),
  onMenuOpenFiles: (cb) => ipcRenderer.on("menu-open-files", () => cb()),
});
