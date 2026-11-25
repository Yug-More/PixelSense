# PixelSense

PixelSense is a local photo editor for making quick, reversible color and lighting adjustments. Open an image to get an automatic first pass, compare it with the original, then fine-tune the result and download a full-resolution PNG.

**CS 152 · Programming Paradigms · San José State University**

Yug More and Tejas · Fall 2026 · Dr. Saptarshi Sengupta

## Run the demo

Install Node.js 22.18 or a later 22.x release, or Node.js 24 or later.

```bash
git clone https://github.com/Yug-More/PixelSense.git
cd PixelSense
npm ci
npm start
```

Open **http://127.0.0.1:5173/** in Chrome. Keep the terminal running while you use the editor. `npm start` builds and serves the production version locally. Use `npm run dev` for hot reload while working on the source. Both commands use the same port and stop with an error if it is already occupied. If the page stops responding, restart the command and reload the tab.

## Edit a photo

1. **Open, drop, or paste a JPEG or PNG.** Choose **Try sample** for a bundled alpine lake image. For HEIC or another format, export a JPEG or PNG first.
2. **Review the first pass.** Enhance on open is enabled by default. The status lists the applied corrections and shows the estimated brightness change when it is measurable. Choose **Before** to see what changed, or turn off **Enhance on open** to start the next image with neutral controls.
3. **Fine-tune the edit.** Select **Subtle**, **Moderate**, or **Full**, then click **Auto Enhance** to reapply at that strength. Adjust Exposure, Contrast, Saturation, and Warmth individually, click a value to reset that control, or try a preset or a short instruction such as “Make this photo brighter and warmer.”
4. **Check the details.** Use Split to compare both versions, zoom up to 300%, and drag to pan. The histogram tracks the visible image, or the edited side in Split. Clipping marks near-black pixels in blue and near-white pixels in red.
5. **Save a look.** Open **Saved looks and recipes** to name the current adjustments or download them as a JSON recipe. Open a different photo and apply the saved preset or import the recipe. Both actions are undoable.
6. **Export your photo.** Choose PNG to preserve transparency or JPEG to create a smaller shareable file. JPEG quality is adjustable. Both formats use the current edits and preserve the browser-decoded dimensions. Zoom, comparison, and clipping marks apply only to the workspace.

**Keyboard shortcuts** · Cmd/Ctrl+Z to undo, Cmd/Ctrl+Shift+Z to redo, and B to switch Before/After outside form fields. Automatic enhancement is undoable. A new image starts a fresh history with up to 50 undo steps.

## How Auto Enhance works

PixelSense analyzes an opacity-weighted sample from the original image, at up to 128 pixels on its longest side. It combines median and mean luminance to estimate a representative midtone. Underexposed images get a bounded lift toward a midtone target. The lift tapers near white to retain detail in bright parts of the image.

The editor checks for a warm or cool cast in muted midtones **after adjusting exposure**, which can reveal color evidence that was too dark to measure originally. It then estimates contrast and makes a modest saturation correction where appropriate. Each run uses the original sample and replaces the current slider values. Reapplying the same strength produces the same edit.

Auto Enhance is rule-based. A photograph with intentional shadows or warm lighting may look better with a gentler correction. The editor can brighten existing detail, but it cannot reconstruct detail lost in completely black, blown-out, or blurry areas.

## Architecture and course concepts

PixelSense uses **React, TypeScript, Vite, and Canvas 2D**. Image decoding, analysis, preview, and export run on the device. The app has no account requirement or photo upload service.

- **Pure transformations** · `web/adjustments.ts` analyzes pixels and returns a recipe or a new pixel buffer. The original pixels stay available for comparison.
- **Function composition** · Exposure, temperature, contrast, and saturation share one pipeline in preview and export.
- **Immutable state** · `web/history.ts` keeps recipe snapshots for undo and redo. Edits do not copy the original photo into history.
- **Separation of concerns** · `web/photo.ts` handles files and Canvas. `web/main.tsx` handles user interaction. `web/diagnostics.ts` computes the histogram and clipping indicators.

## Reuse an edit

Named presets are stored in the current browser and remain available after a reload. PixelSense supports up to 20 custom presets. A downloaded recipe contains only the four adjustment values and a format version. It can be backed up or opened on another device without sharing the photo.

## Verify the project

```bash
npm test
npm run build
npx playwright-core install chromium
npm run test:browser
```

The unit suite covers adaptive exposure, cast correction, highlight preservation, transparent pixels, history, recipe validation, and file utilities. The browser suite builds the app, starts a temporary local server, and verifies file import, automatic and manual edits, comparison, history, preset persistence, recipe round trips, diagnostic overlays, and the pixels and dimensions in PNG exports and JPEG encoding. To use an existing Chrome installation, set `CHROME_PATH` to its executable when running `npm run test:browser`.

Large photos are subject to browser memory and Canvas limits. PNG exports omit the original EXIF metadata, and edit history lives in the current session. The bundled sample is a generated demo image.

## Original iPhone prototype

The SwiftUI, Core Image, and PhotoKit project remains in `PixelSense/`, `PixelSenseTests/`, and `PixelSense.xcodeproj`. See the [original iOS architecture](docs/ARCHITECTURE.md), [project plan](docs/PROJECT_PLAN.md), and [maintainer handoff](docs/HANDOFF.md).
