# PixelSense

PixelSense is a browser-based photo editor for quick, reversible lighting and color adjustments. Open a photo to get an automatic first pass, refine it with familiar controls, compare it with the original, then export a full-resolution image.

Photos stay in your browser. PixelSense does not upload them to a server.

## Run locally

Requirements: Node.js 22.18 or later in the 22.x series, or Node.js 24 or later.

```bash
git clone https://github.com/Yug-More/PixelSense.git
cd PixelSense
npm ci
npm start
```

Open [http://127.0.0.1:5173](http://127.0.0.1:5173). Keep the terminal open while using the app. To stop the local server, press Ctrl+C.

For source development with hot reload, run `npm run dev`. To build and serve the production files separately, run `npm run build` followed by `npm run preview`.

## Edit a photo

1. Open, drop, or paste a JPEG or PNG. Select **Try sample** to use the included alpine lake photo.
2. **Enhance on open** automatically analyzes each new photo. Turn it off if you want to start with neutral adjustments.
3. Choose **Subtle**, **Moderate**, or **Full** and select **Auto Enhance** to apply a fresh recommendation. The status message lists the changes and shows the estimated brightness shift.
4. Adjust exposure, contrast, saturation, and warmth. Use the named presets or enter a supported instruction, such as “Make this photo brighter and warmer.”
5. Compare **Before**, **After**, or **Split**. Zoom to inspect details, drag to pan, and check the histogram. **Clipping** marks near-black pixels in blue and near-white pixels in red.
6. Use **Undo** or **Redo** to revisit edits. Save a named look in this browser, or download and import a recipe JSON file to reuse the settings on another device.
7. Select **Download PNG** or **Download JPEG**. PNG retains transparency. JPEG offers an adjustable quality setting.

Keyboard shortcuts are **Cmd/Ctrl+Z** to undo, **Cmd/Ctrl+Shift+Z** to redo, and **B** to switch between Before and After when focus is outside a form field.

PixelSense accepts JPEG and PNG files. Convert HEIC, HEIF, WebP, or AVIF files to JPEG or PNG before opening them.

## Automatic enhancement

Auto Enhance samples the original photo at up to 128 pixels on its longest side. It measures luminance, tonal range, and saturation. It uses the median and average brightness to estimate a representative midtone, lifts dark images while tapering the lift near white, and slightly lowers exposure for very bright photos.

After adjusting exposure, PixelSense checks muted midtones for warm or cool color casts. It then considers a restrained contrast and saturation correction. The recommendation replaces the current slider values and is scaled by the chosen strength. Reapplying the same strength to the same original photo produces the same recipe.

Auto Enhance is a deterministic image-processing rule set, not machine learning. It can improve existing detail, but it cannot recover detail that is completely black, blown out, or out of focus. Compare with Before and tune the sliders when a photo has intentional lighting or color grading.

## Settings and saved looks

Named presets are stored locally in the current browser, up to 20 presets. They remain available after reload in that browser. Download a recipe JSON file to back up or transfer adjustment values. A recipe contains the four adjustment values and format version, not the photo itself.

The editing history is session-only and holds up to 50 undo steps. Opening another photo starts a fresh history.

## Technology and project structure

PixelSense uses React, TypeScript, Vite, and the browser Canvas 2D API.

- `web/adjustments.ts` contains image analysis, automatic recommendations, and pure pixel transformations.
- `web/photo.ts` handles photo decoding, preview rendering, and PNG/JPEG export.
- `web/diagnostics.ts` calculates histogram and clipping information.
- `web/history.ts` provides immutable undo and redo state.
- `web/recipes.ts` validates portable edit recipes and saved presets.
- `web/main.tsx` connects the editing interface to those functions.

The project demonstrates pure functions, function composition, higher-order functions, immutable state updates, and separation between image processing and the user interface.

## Tests

Run the unit tests and production build:

```bash
npm test
npm run build
```

The browser workflow also checks imports, Auto Enhance, editing controls, presets and recipe transfer, diagnostics, and exported image formats:

```bash
npx playwright-core install chromium
npm run test:browser
```

To use an installed Chrome instead of installing Chromium, set `CHROME_PATH` to the Chrome executable when running `npm run test:browser`.

## Known limitations

- Editing applies globally to the full image. There are no crop, layer, or local retouch tools.
- JPEG and PNG are the supported input formats.
- Large photos depend on browser canvas and memory limits.
- JPEG output is lossy. PNG preserves transparency.
- PNG and JPEG exports omit the source image’s EXIF metadata.
- Named presets stay in the current browser. Transfer them with recipe JSON.
- The original iPhone prototype remains in `PixelSense/`, `PixelSenseTests/`, and `PixelSense.xcodeproj`. Its Photos save path still needs physical iPhone acceptance.

## Course project

CS 152 · Programming Paradigms · San José State University

Yug More and Tejas · Fall 2026 · Dr. Saptarshi Sengupta

See the [project plan](docs/PROJECT_PLAN.md), [iOS architecture](docs/ARCHITECTURE.md), and [team handoff](docs/HANDOFF.md).
