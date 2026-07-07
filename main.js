const { app, BrowserWindow, ipcMain, dialog, Menu } = require("electron");
const fs = require("fs/promises");
const path = require("path");

// Local personal player: skip the Chromium SUID sandbox so `npm start` works
// without root-owning chrome-sandbox after every reinstall. Safe here because
// we only load bundled local files; revisit if remote/untrusted URLs are added.
app.commandLine.appendSwitch("no-sandbox");

function createWindow() {
  const win = new BrowserWindow({
    // Size the web content to the default Webamp cluster (main+EQ+playlist,
    // 275px wide, 3 x 116px tall). Webamp centers itself in #app, so an
    // exact-fit container fills the window with no black void.
    useContentSize: true,
    width: 275,
    height: 348,
    minWidth: 275,
    minHeight: 116,
    backgroundColor: "#000000",
    title: "Winamp",
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  const menu = Menu.buildFromTemplate([
    {
      label: "File",
      submenu: [
        {
          label: "Open files…",
          accelerator: "CmdOrCtrl+L",
          click: () => win.webContents.send("menu-open-files"),
        },
        { type: "separator" },
        { role: "quit" },
      ],
    },
    { role: "viewMenu" },
  ]);
  Menu.setApplicationMenu(menu);

  win.loadFile("index.html");
}

app.whenReady().then(() => {
  createWindow();
  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});

// Native OS file picker -> return raw bytes to the renderer.
ipcMain.handle("open-files", async () => {
  const { canceled, filePaths } = await dialog.showOpenDialog({
    properties: ["openFile", "multiSelections"],
    filters: [
      {
        name: "Audio",
        extensions: ["mp3", "flac", "aac", "m4a", "ogg", "oga", "opus", "wav", "wv", "webm"],
      },
      { name: "All files", extensions: ["*"] },
    ],
  });
  if (canceled) return [];
  return Promise.all(
    filePaths.map(async (fp) => ({
      name: path.basename(fp),
      buffer: await fs.readFile(fp),
    }))
  );
});
