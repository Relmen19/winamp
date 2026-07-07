/* global Webamp */

const webamp = new Webamp();

webamp.renderWhenReady(document.getElementById("app"));

// Bring tracks in from the native OS picker (File > Open files… / Ctrl+L).
async function openNative() {
  const files = await window.native.openFiles();
  if (!files.length) return;
  const tracks = files.map((f) => {
    const blob = new Blob([f.buffer]);
    return {
      url: URL.createObjectURL(blob),
      metaData: { title: f.name },
    };
  });
  webamp.appendTracks(tracks);
}

window.native.onMenuOpenFiles(openNative);
