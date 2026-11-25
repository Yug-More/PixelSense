# PixelSense handoff

This is the shared, human-readable state of the project for Tejas, Yug, and any agents helping them. Read it with `README.md`, `docs/PROJECT_PLAN.md`, and `AGENTS.md` before starting work. Update the current-state summary and append a work-log entry before every handoff.

## Current state — 2026-11-21

- **Course demo:** the browser editor is the active deliverable. Use the default branch, `main`. Run `npm ci` and `npm start` from the repository root.
- **Ownership:** The assisted release session prepared the verified browser release on `main`. Yug and Tejas own the class demo rehearsal and repository review.
- **Browser behavior:** local JPEG and PNG import with drag and drop, adaptive Auto Enhance, four sliders, five presets, typed instructions, Before/After and split comparison, undo and redo, reset, and full-resolution PNG export.
- **Verification:** 26 Vitest checks, a clean install, the production build, and three production Chrome runs passed. The studio adds a bundled sample, paste import, Auto Enhance strengths, a live histogram and clipping overlay, zoom and pan, and editing shortcuts.
- **Native prototype:** the Swift app remains available. Tejas owns any future iPhone save/reopen/revert verification. The browser demo has no dependency on that device check.

## Working agreement

The two students are the only intended GitHub collaborators. An assisting agent must not invite itself, a bot, or a service account, and must not add a co-author trailer. On 2026-10-13 the GitHub collaborators were `Yug-More` (admin) and `Tejasvid29` (write). Use the student account already authenticated on the machine. Do not change `user.name`, `user.email`, remotes, or access.

Keep this document factual. A completed acceptance check needs a reproducible result, especially for Photos save-back on a real iPhone. Record simulator-only work as simulator-only. Never attach private photos, device identifiers, or secrets.

## Work log

### 2026-10-12 — Repository import and initial review

- **Who / branch:** Assisted session for Tejas / `main`.
- **Work:** cloned `https://github.com/Yug-More/PixelSense` into the local PixelSense workspace and read the complete initial README. At import, `README.md` was the only tracked file.
- **Result:** identified the original goal of prompt-driven, region-aware photo enhancement and the absence of implementation/setup details.
- **Verification:** checked repository status, remote, tracked files, and README content. No application tests existed.

### 2026-10-12 — Scope clarification and README update

- **Who / branch / commit:** Assisted session for Tejas / `main` / `e6fd8af` (pushed).
- **Work:** rewrote `README.md` to focus on reversible exposure and color/tone settings, manual refinement, and preservation of scene content and geometry. Removed language that could imply generation or object editing.
- **Decision:** region detection may choose where adjustment settings apply, but never changes an object or scene itself.
- **Verification:** reviewed the README diff and ran `git diff --check`. The working tree was clean after push.

### 2026-10-12 — iPhone deployment decision

- **Who / branch:** Assisted session for Tejas / planning only.
- **Work:** checked Apple PhotoKit, Core Image, editing extension, and developer-account documentation. No files changed during this discussion.
- **Decision:** target the same visible Photos asset through PhotoKit and use a native iOS app. Use Xcode's free personal-device testing for the class prototype. An extension inside Photos is optional later work.
- **Constraint:** PhotoKit requires an edited rendering plus adjustment data to commit a content edit; Photos controls its internal versions. A literal overwrite of the original file is unavailable.
- **References:** [PhotoKit editing](https://developer.apple.com/documentation/photokit/editing-asset-content), [Core Image adjustments](https://developer.apple.com/documentation/coreimage/color-adjustment-filters), [free device testing](https://developer.apple.com/help/account/basics/about-your-developer-account).

### 2026-10-12 — Planning and agent handoff documents

- **Who / branch / commit:** Assisted session for Tejas / `main` / `6906e3b` (pushed).
- **Work:** updated `README.md` for the same-item Photos save flow; created `docs/PROJECT_PLAN.md` with architecture, milestones M0–M6, acceptance checks, coordination, and risks; created `AGENTS.md` with documentation, verification, Git, and account rules; created this handoff.
- **Reason:** ensure both students and their agents can resume from one written state and avoid conflicting interpretations of “no duplicate.”
- **Verification:** reviewed the documentation diff and ran `git diff --check`; both passed. No app or device test is possible yet because the iOS project has not been created.
- **Next action:** start M0 with the two students' device and course constraints.

### 2026-10-12 — First iPhone Photos editing prototype

- **Who / branch / commit:** Assisted session for Tejas / `feature/ios-photo-editing-proof` / `5c43098` (published and fast-forwarded to `main`).
- **Work and files:** added `PixelSense.xcodeproj` and the `PixelSense/` SwiftUI app; added `.gitignore`; updated `README.md` with current behavior and free-device setup; updated `docs/PROJECT_PLAN.md` with the initial iOS 17/still-photo/exposure choices. `PhotoLibraryStore` handles read/write or limited Photos authorization and browses still assets. `PhotoEditorModel` loads a content editing input, renders an exposure preview with Core Image, stores a versioned recipe, and asks PhotoKit to update the selected asset. `ContentView` provides the gallery, before/edit comparison, slider, and save action.
- **Decisions and sources:** use `PHContentEditingOutput.renderedContentURL(for: .jpeg)` for the first still-photo proof; this API is available on iOS 17+. Use `PHAdjustmentData` for the exposure recipe and no asset-creation request in the save path. Apple references: [content editing](https://developer.apple.com/documentation/photokit/editing-asset-content), [editing output](https://developer.apple.com/documentation/photos/phcontenteditingoutput), [color filters](https://developer.apple.com/documentation/coreimage/color-adjustment-filters).
- **Attempts and fixes:** the first build rejected a nonexistent `CIImageRepresentationOption.lossyCompressionQuality` member; removed that option and rebuilt successfully. Added required bundle keys to `Info.plist` after inspecting the built app metadata. The simulator service could not be used for a launch test in this tool session.
- **Verification and result:** `plutil` accepted the project and Info.plist. Generic simulator build passed. Generic iPhone build passed with signing disabled. The built Info.plist contains the bundle identifier, version, iOS 17 minimum, and Photos usage description. No physical iPhone run, save-back, iCloud, metadata, orientation, or repeat-edit test has passed yet.
- **Blockers or risks:** device/iOS version and free Personal Team signing are pending Tejas's input. JPEG rendering may change format or color characteristics; save behavior and Photos revert remain unverified on hardware. Live Photos are excluded, and prompts and region edits are not implemented yet.
- **Exact next action and owner:** Tejas tests the flow on his iPhone using a still photo set aside for testing, records the observed Photos behavior, and sends any errors or screenshots. The assisting session then fixes device findings and continues M1/M2. Yug and Tejas assign ownership of later workstreams.

### 2026-10-12 — Basic color and tone controls

- **Who / branch / commit:** Assisted session for Tejas / `feature/color-controls` / `23f2967` (published and fast-forwarded to `main`).
- **Work and files:** added `PixelSense/EditRecipe.swift` and `PixelSense/AdjustmentRenderer.swift`; updated `PixelSense/PhotoEditorModel.swift`, `PixelSense/ContentView.swift`, and the Xcode project. The editor now exposes exposure, contrast, saturation, warmth, and reset controls in a scrollable layout. The same recipe drives both preview and full-resolution save. Updated `README.md` and `docs/PROJECT_PLAN.md` to reflect the added controls.
- **Decisions and sources:** kept recipe format version 1 and decode missing new fields as zero, so exposure-only recipes remain readable. The renderer skips controls at their neutral value. Contrast and saturation use Core Image color controls; warmth uses temperature and tint. [Apple Core Image color adjustment filters](https://developer.apple.com/documentation/coreimage/color-adjustment-filters).
- **Verification and result:** generic iPhone and simulator builds passed with signing disabled. A temporary compatibility check decoded the earlier exposure-only JSON with all new controls at zero and round-tripped a four-control recipe. No on-device color, format, save-back, or performance check has been completed.
- **Blockers or risks:** Core Image warmth direction and strength, color fidelity, and large-photo responsiveness require visual review on a real device. M1 same-asset save remains unverified on hardware.
- **Exact next action and owner:** Tejas runs the README device flow and reports save behavior and appearance; The assisting session fixes any findings.

### 2026-10-13 — October 20 documentation pass

- **Who / branch / commit:** Agent session assisting Yug / `docs/check-in-architecture` / uncommitted. Git author for a later commit would be `Yug-More <yugmore20@gmail.com>`. No co-author trailer.
- **Work and files:** rewrote `README.md` so current features, setup, roadmap, and limitations match the code. Added `docs/ARCHITECTURE.md` for components, recipe and PhotoKit flow, paradigms, and the unimplemented M4 design. Updated `docs/PROJECT_PLAN.md` with milestone status, October 20 scope, ownership, and the prompt specification. Updated this handoff. No Swift files, project settings, remotes, or collaborator settings were changed.
- **Decisions and sources:** kept the existing product boundary, iOS 17 target, JPEG content edit, and version 1 recipe. Prompt intensity, conflict handling, and the four demo prompts are documented as the M3 check-in spec and are not code. Diagrams mark the prompt interpreter and region masks as planned. Apple references remain those already cited in the project plan and architecture doc.
- **Verification and result:** inspected the repository, `main` history, GitHub login `Yug-More`, and collaborators `Yug-More` and `Tejasvid29` before editing. No build, unit test, or device run was executed. `xcodebuild` is unavailable on this Mac.
- **Blockers or risks:** `main` does not yet contain these docs. Tejas's device test can still change save-path findings. Screenshots are intentionally absent.
- **Exact next action and owner:** Yug approves or corrects this documentation. Phase 3, on a new branch, adds the prompt interpreter and tests only after that approval. Tejas owns the physical-device save check.

### 2026-10-13 — October 20 prompt interpreter

- **Who / branch / commit:** Agent session assisting Yug / `feature/first-checkin-prompt-editing` / `a8e2a74`, `b515d9f`, `1ab0e78`, `a0fc4e6`, and this documentation commit. Author and committer are `Yug-More <yugmore20@gmail.com>`. No co-author trailer.
- **Work and files:** added `PixelSense/PromptInterpreter.swift`, `PixelSense/EditRecipePhotoKit.swift`, `PixelSenseTests/LogicChecks.swift`, `PixelSenseTests/PixelSenseLogicTests.swift`, `PixelSenseTests/LogicTestMain.swift`, `docs/FIRST_CHECKIN.md`, and a shared Xcode scheme. Updated `PixelSense/EditRecipe.swift` with shared limits and clamping, `PixelSense/PhotoEditorModel.swift` with `applyPrompt` only, and `PixelSense/ContentView.swift` with the prompt field and slider limits. Updated `README.md`, `docs/ARCHITECTURE.md`, `docs/PROJECT_PLAN.md`, and this handoff. Did not edit `PhotoLibraryStore.swift`, `AdjustmentRenderer.swift`, or the body of `save()`.
- **Decisions and sources:** a mentioned control is replaced from neutral; unmentioned controls stay; conflicts and unsupported sentences change nothing. Finite out-of-range JSON is clamped; non-finite values become neutral; format identifier and version stay `edu.sjsu.pixelsense.recipe` / `1`. "Strongly" uses the 100 percent tier. Contrast slider step is 0.025 so 0.125 is a detent. Apple references are unchanged from the architecture document.
- **Verification and result:** `plutil -lint PixelSense.xcodeproj/project.pbxproj` passed. `swiftc -parse` on the Swift sources passed. Logic runner command: `swiftc -parse-as-library -D LOGIC_TEST_RUNNER -o /tmp/pixelsense-logic-tests PixelSense/EditRecipe.swift PixelSense/PromptInterpreter.swift PixelSenseTests/LogicChecks.swift PixelSenseTests/LogicTestMain.swift` then `/tmp/pixelsense-logic-tests`. Result: `Passed 32 logic tests`. `xcodebuild` is unavailable. No iOS link, simulator, or iPhone test.
- **Blockers or risks:** the app may still fail to build or the prompt layout may need adjustment once Xcode is available. Photos save, reopen, and revert remain unverified. Tejas still owns that device pass.
- **Exact next action and owner:** Yug reviews the open pull request and does not merge it yet. Tejas verifies selection, prompt, slider edit, and same-item save on an iPhone.

### 2026-10-13 — Folder layout and shorter README

- **Who / branch / commit:** Agent session assisting Yug / `cleanup/project-structure` / `e7d877f` and this documentation commit. Started from `origin/main` at `9980d3a` after pull request #2 merged. Author and committer are `Yug-More <yugmore20@gmail.com>`. No co-author trailer.
- **Work and files:** `e7d877f` moved Swift sources into `PixelSense/App`, `Editor`, and `Photos`, and pointed the Xcode groups at those folders. This commit shortens `README.md` and updates paths in `docs/ARCHITECTURE.md`, `docs/PROJECT_PLAN.md`, `docs/FIRST_CHECKIN.md`, and this handoff. Did not change Swift logic, tests, signing, or bundle IDs.
- **Decisions and sources:** three folders are enough for the eight Swift files: `App` for the entry point, `Editor` for the screen, state, recipe, prompts, and rendering, and `Photos` for PhotoKit. Left older handoff entries on the paths they used at the time.
- **Verification and result:** `plutil -lint PixelSense.xcodeproj/project.pbxproj` passed. `swiftc -parse` on the moved sources and tests passed. The logic runner, using `PixelSense/Editor/EditRecipe.swift` and `PixelSense/Editor/PromptInterpreter.swift`, printed `Passed 32 logic tests`. `git diff --check` passed. Xcode is still not installed here, so the project was not opened or built.
- **Blockers or risks:** a group path mistake would show up only when someone opens the project in Xcode. Device save is still unverified.
- **Exact next action and owner:** Yug reviews the pull request and does not merge it yet. Tejas still owns the iPhone save check.

### 2026-10-13 — Course information in the README

- **Who / branch / commit:** Agent session assisting Yug / `cleanup/project-structure` / this commit. Author and committer are `Yug-More <yugmore20@gmail.com>`. No co-author trailer. Pull request #3 had already merged before this commit.
- **Work and files:** compared the README on `main` (`9980d3a`) with the shortened README. Restored a Course Information section, a short Programming Paradigms section, contributor roles, and the note that assisted work is recorded in this handoff. No Swift files, tests, folders, or Xcode settings were changed.
- **Decisions and sources:** the professor line keeps the “Dr.” title from the earlier README. The paradigm wording matches `docs/ARCHITECTURE.md` and `docs/FIRST_CHECKIN.md`: reference types for editor state, a value recipe and image transform, and a deterministic phrase interpreter. The interpreter is not described as a trained model.
- **Verification and result:** documentation only. `git diff --check` passed. README links resolve to `docs/ARCHITECTURE.md`, `docs/PROJECT_PLAN.md`, `docs/HANDOFF.md`, and `docs/FIRST_CHECKIN.md`. The logic tests were not rerun because no Swift file changed.
- **Blockers or risks:** none in the app. Because pull request #3 is already merged, this commit stays on the branch until a later review.
- **Exact next action and owner:** Yug decides how to review this commit. Tejas still owns the iPhone save check.

### 2026-10-20 — Team work plan and smart-editing sprint start

- **Who / branch / commit:** Yug More / `feature/yug-smart-editing` / `e0f3fe0`. Author and committer `Yug-More <yugmore20@gmail.com>`. No co-author trailer.
- **Work and files:** Added `docs/TEAM_WORK_PLAN.md` with ownership matrix, Yug/Tejas task specs, integration contracts, October 22 milestone checklist, and contribution tracking. Updated this current-state section. No Swift behavior change in the plan-only commit.
- **Decisions and sources:** Yug owns prompt improvements, auto-enhance, presets, editor UX, and related tests/docs. Tejas owns PhotoKit, renderer reliability, and device verification. Shared: `EditRecipe.swift`, `PhotoEditorModel.swift` (additive APIs only).
- **Verification and result:** Document review against existing sources on `main`. Logic tests not rerun for docs-only commit.
- **Blockers or risks:** `xcodebuild` unavailable here; M1 still needs Tejas’s iPhone pass.
- **Exact next action and owner:** Yug implements YUG-1 through YUG-6 on this branch. Tejas starts TEJ-8 when ready.

### 2026-10-20 — Final review hardening for Yug modules

- **Who / branch:** Yug More / `fix/yug-final-review-hardening`. Author/committer `Yug-More <yugmore20@gmail.com>`.
- **Work:** Cleared partial state on failed `load()`; clamp recipe before PhotoKit encode/save render; reject infinite extents in `ImageStatistics.sample`; auto-enhance samples preview-scaled source; added 3 regression tests (64 total).
- **Verification:** `Passed 64 logic tests`. No Xcode/simulator/device run.
- **Next:** Tejas continues TEJ-8/TEJ-4; no renderer rewrite needed for these fixes.

### 2026-10-20 — Rendering ownership rebalance and improvements

- **Who / branch / commits:** Yug More / `feature/yug-rendering-improvements`. Author and committer `Yug-More <yugmore20@gmail.com>`. No co-author trailer.
- **Work and files:** Rebalanced `docs/TEAM_WORK_PLAN.md` (TEJ-3/TEJ-7 → YUG-7/YUG-8). Hardened `AdjustmentRenderer.swift` (clamp, extent validation, documented Kelvin mapping). Cached preview scaling in `PhotoEditorModel.swift`. Expanded logic tests to 61. Rewrote `README.md`.
- **Decisions and sources:** Preview longest side capped at 1200; save remains full resolution. Filter order unchanged. PhotoKit `save()` body not rewritten beyond renderability guards.
- **Verification and result:** `Passed 61 logic tests`. `xcodebuild` / simulator / iPhone still unavailable on this Mac.
- **Blockers or risks:** Device save acceptance still Tejas TEJ-8/TEJ-4.
- **Exact next action and owner:** Merge rendering PR; Tejas runs device checklist.

### 2026-10-20 — Yug smart editing implementation

- **Who / branch / commits:** Yug More / `feature/yug-smart-editing` / `235dbf4`, `88734a1`, `7e0e348`, `64c7c28`, `f9cefcc`, plus documentation commit. Author and committer `Yug-More <yugmore20@gmail.com>`. No co-author trailer.
- **Work and files:** Extended `PromptInterpreter.swift`; added `ImageStatistics.swift`, `AutoEnhance.swift`, `ImageStatisticsSampler.swift`, `EditPreset.swift`; additive methods on `PhotoEditorModel.swift`; smart tools UI in `ContentView.swift`; expanded `LogicChecks.swift`. Did not change `PhotoLibraryStore.swift`, `AdjustmentRenderer.swift`, or the body of `save()`.
- **Decisions and sources:** Presets and auto-enhance replace the current recipe; auto-enhance measures the source image so repeats do not compound. Prompt word “cinematic” stays blocked; Cinematic is a UI preset only. Enhancement thresholds are documented in `AutoEnhance.swift` and `docs/ARCHITECTURE.md`.
- **Verification and result:** Logic runner: `Passed 52 logic tests`. `plutil -lint` on the Xcode project passed earlier in the sprint. `xcodebuild` / simulator / iPhone: not run (Command Line Tools only).
- **Blockers or risks:** Full app build and Photos save still need Tejas’s Mac and iPhone.
- **Exact next action and owner:** Open PR for review. Tejas runs TEJ-8 device checklist after merge or on this branch.

### 2026-11-20 — Browser final project

- **Who / branch / commit:** Assisted session for the student maintainers on the prior web release branch. Implementation and tests are in `30f53cf`. This handoff ships with the documentation commit.
- **Work and files:** added the React editor in `web/main.tsx` and `web/style.css`, Canvas import/render/export in `web/photo.ts`, pure image analysis and adjustments in `web/adjustments.ts`, and presets and typed instructions in `web/smart-tools.ts`. Added npm/Vite setup and `web/adjustments.test.ts`. Updated `README.md`, `AGENTS.md`, and `docs/PROJECT_PLAN.md` for the browser scope.
- **Decisions:** carried over the native adjustment ranges, preset recipes, and the analysis-to-recipe architecture. The browser version uses a percentile histogram and proportional recommendations. Browser QA exposed a case where a contrast boost offset the exposure lift for a flat dark image. The revised algorithm skips the boost on flat samples, and a regression test covers it. Export replaces PhotoKit save for the web demo. The web instruction parser supports a smaller set of phrases than the Swift parser.
- **Verification:** Vitest passed 12 tests and the production build passed. Chrome automation checked unsupported and corrupt inputs, JPEG and PNG upload, different dark/well-exposed recommendations, non-stacking enhancement, each slider, comparison, presets, accepted and rejected instructions, reset, PNG download name/dimensions/pixels, replacement, and narrow viewport overflow. A 1600 × 2400 portrait fixture displayed at reduced resolution and exported at its original dimensions. A clean npm install from the lockfile passed using the local package cache. The retained Swift CLI suite passed 64 logic checks. No iPhone run was performed.
- **Remaining checks and owner:** Yug and Tejas should rehearse with their chosen classroom photos on the presentation laptop. Tejas still owns iPhone PhotoKit checks if the native branch of work resumes. Browser exports are subject to canvas memory limits and omit EXIF metadata.

### 2026-11-20 — Auto Enhance follow-up

- **Who / branch / commit:** Assisted session on the prior web release branch, in the Auto Enhance fix commit.
- **Work and files:** `web/adjustments.ts` now weights the median more heavily than the mean to detect dark subjects against bright backgrounds. The shared renderer tapers positive exposure per pixel near white. `web/main.tsx` clarifies zero-change recommendations. `web/adjustments.test.ts` adds backlit and neutral regressions. `README.md` documents the actual algorithm, slider behavior, and local server setup.
- **Findings:** The previous highlight check could zero out exposure for a dark photo with a bright background. The earlier preview server had also been stopped, leaving the existing URL unavailable. Restarted Vite on port 5173.
- **Verification:** Ran 13 passing Vitest tests and the TypeScript/Vite build. Repeated the Chrome upload-to-export workflow, including invalid files, all sliders, comparison, presets, typed instructions, reset, and PNG pixel and dimension checks. On the macOS Mojave night JPEG, mean preview luminance rose from 44 to 58 on a 0–255 scale. The day JPEG had a smaller change, from 96 to 99. No device verification is required for the web changes.
- **Remaining checks and owner:** Yug and Tejas can check the specific classroom photos on the demo laptop. Tejas owns any separate native iPhone acceptance pass.

### 2026-11-20 — Browser editing workflow polish

- **Who / branch / commit:** Assisted session on the prior web release branch, in the editing-tools commit.
- **Work and files:** `web/main.tsx` adds drag-and-drop import, history controls, and a movable split comparison. `web/history.ts` and `web/history.test.ts` implement and cover recipe history. `web/style.css` refines the desktop toolbar and narrow layout. `README.md` and `docs/PROJECT_PLAN.md` explain the workflow and acceptance checks.
- **Decisions:** Kept Before and After as separate views alongside Split. Coalesced pointer-driven slider changes into one undo step. Kept up to 50 steps per photo and cleared history after a successful replacement. Split uses complementary clips to keep translucent PNG pixels from stacking. Export uses the current recipe regardless of comparison mode.
- **Verification:** All 16 Vitest tests and the production build passed. Chrome verified valid and invalid import, drag-and-drop, Auto Enhance, all sliders, whole-drag undo, redo, split position, Before/After, presets, instructions, undoable reset, PNG pixel and dimension checks, fresh history after import, and narrow-width layout. Reviewed a desktop screenshot with a sample JPEG. No native changes or device tests.
- **Remaining checks and owner:** Yug and Tejas own rehearsal with their chosen photos on the presentation laptop. Tejas owns any separate native iPhone acceptance pass.

### 2026-11-20 — Photo editing studio

- **Who / branch / commit:** Assisted session on the prior web release branch, in the studio redesign commit.
- **Work and files:** `web/main.tsx` and `web/style.css` redesign the studio and add sample and clipboard import, histogram and clipping controls, three Auto Enhance strengths, per-control reset, zoom and pan, and shortcuts. `web/diagnostics.ts` and `web/diagnostics.test.ts` handle diagnostic calculations and coverage. `web/photo.ts` applies warning colors to preview pixels, while the export uses unmarked pixels. `web/assets/alpine-lake.jpg` is the bundled demo JPEG. `README.md` and `docs/PROJECT_PLAN.md` describe behavior and acceptance.
- **Decisions:** The live histogram uses the small analysis sample and weights partially transparent pixels by opacity. The warning uses near-black and near-white RGB thresholds. Split shows the edited histogram. Zoom and pan apply to the preview only. Cmd/Ctrl+Z, Cmd/Ctrl+Shift+Z, and B preserve standard typing behavior in form fields.
- **Sample asset:** Created with the built-in image generation tool. Prompt: “Photorealistic landscape sample for a professional photo editing workspace. Wide cinematic landscape photograph of a rugged alpine lake at dawn, prominent jagged peaks, still teal water reflecting the mountains, a small band of pale warm sky, dark evergreen trees and shaded foreground rocks. Naturally somewhat underexposed foreground with recoverable shadow detail and varied color. Fine photographic detail, believable exposure, no people, no text, no borders, no logos.”
- **Verification:** All 19 Vitest tests and the production build passed. Chrome checked the sample, strength differences, individual reset, keyboard undo and redo, comparison shortcut, zoom and drag panning, histogram, paste import via a browser clipboard event, clipping colors, and clean PNG export with warnings active. The original import-to-export checks passed. Reviewed screenshots of both studio states and checked narrow-width overflow. No native changes or device tests.
- **Remaining checks and owner:** Yug and Tejas own the classroom rehearsal. App-level browser verification used Chrome. Tejas owns any separate native iPhone acceptance pass.

### 2026-11-20 — Auto Enhance on open

- **Who / branch / commit:** Assisted session on the prior web release branch, in the enhancement follow-up commit.
- **Work and files:** `web/adjustments.ts` targets a representative midtone with a stronger highlight-preserving curve, estimates warm and cool casts from muted midtones, and bases contrast on the corrected sample. `web/main.tsx` and `web/style.css` add the default-on import option and visible correction summary. `web/adjustments.test.ts`, `README.md`, and `docs/PROJECT_PLAN.md` cover and document the new behavior.
- **Decisions:** The earlier recommendation always set warmth to zero and required a button press. Import now records any applied recipe as an undoable first edit. The chosen strength and opt-out apply across imports in the open page. Temperature estimates are bounded because deliberate color grading can resemble a cast.
- **Verification:** All 22 Vitest tests and the TypeScript/Vite build passed. Chrome checked that the first import of a dim cool fixture changed real preview pixels, displayed the correction summary, and could be undone and redone. Chrome also checked disabled automatic import, manual enhancement switching Split to After, and the existing file import, editor, and PNG export flows. No native changes or device tests.
- **Remaining checks and owner:** The reported photo was unavailable for testing. Yug and Tejas can check the specific classroom photos. Tejas owns the separate native iPhone acceptance pass.

### 2026-11-20 — Verify and publish the browser edition

- **Who / branch / commit:** Assisted session on the prior web release branch, in the verified browser release commit. GitHub `main` was the Swift prototype at the pre-push fetch.
- **Work and files:** `web/adjustments.ts` strengthens the exposure response and looks for temperature evidence after lifting dark tones. `web/main.tsx` reports measured brightness changes, `web/photo.ts` improves HEIC and unsupported-file feedback, and `README.md` documents setup, use, architecture, tests, and limitations. `scripts/check-browser.mjs` adds repeatable browser checks. `package.json` provides a fixed-port production command, `vite.config.ts` builds relative asset URLs, and the lockfile includes test tooling and audit fixes.
- **Decisions and troubleshooting:** An initial sandboxed check could not reach port 5173. An unrestricted check found the earlier Vite development server occupying it. Replaced that server with the verified production build at the same URL. Initially published the browser release on a separate branch. The native prototype remained on the default branch at that point.
- **Verification:** Online clean install, 23 unit tests, build, and npm audit passed. The full production Chrome suite passed three times. It covered dark and backlit photos, temperature correction, invalid and unsupported files, local import, automatic and manual edit flows, and full-resolution PNG pixels, transparency, and dimensions. The supplied macOS night fixture consistently measured 17% before and 32% after. No private images, generated build files, or screenshots were committed.
- **Remaining checks and owner:** The reported photo was unavailable. Yug and Tejas own testing their chosen classroom photos. Tejas owns separate physical-iPhone acceptance for the native prototype.

### 2026-11-20 — Publish PixelSense web on main

- **Who / branch / commit:** Assisted release session / `main` / `Release PixelSense web`. Used the repository’s existing Yug-More author and committer settings.
- **Work and files:** Published the browser editor, bundled sample, and tests as one release commit. Updated `README.md` for a standard clone of the default branch and `docs/HANDOFF.md` for the current ownership and release history. Preserved the Swift project.
- **Verification:** Unit tests, production build, and production Chrome checks passed on the release contents. Checked the staged diff before committing. This release does not require a physical iPhone test.
- **Remaining checks and owner:** Yug and Tejas own classroom rehearsal. Tejas owns any separate native PhotoKit acceptance pass.

### 2026-11-24 — Flexible photo export

- **Who / branch / commit:** Assisted session on `main`.
- **Work and files:** `web/photo.ts` now exports PNG or quality-adjustable JPEG. `web/main.tsx` and `web/style.css` add export settings and format-aware download controls. The browser check verifies JPEG encoding and filename. Updated the README and project plan.
- **Verification:** Pending unit, production build, and browser checks before commit.
- **Next action and owner:** Confirm output pixels and format behavior in Chrome, then publish the verified change.

### 2026-11-21 — Reusable photo settings

- **Who / branch / commit:** Assisted implementation session / `main` / `Add reusable photo settings`. Existing Yug-More commit identity used.
- **Work and files:** `web/recipes.ts` reads and writes versioned adjustment files and validates local presets. `web/main.tsx` and `web/style.css` add named presets and recipe import and download. `web/recipes.test.ts` and `scripts/check-browser.mjs` cover validation, persistence, and reuse. Updated `README.md` and the project plan.
- **Decisions:** Presets store only adjustment numbers in browser-local storage. Recipe JSON transfers settings without image data. Imported and reapplied settings use the existing undo history.
- **Verification:** 26 unit tests, the production build, and the Chrome workflow passed. The browser suite checked preset persistence after reload, reuse on a different photo, download and import, undo, and rejection of invalid JSON. The native prototype requires its separate device test.
- **Next action and owner:** Yug and Tejas can try sharing a recipe during the classroom demo. Tejas owns the separate native PhotoKit acceptance pass.

## Template for the next entry

### YYYY-MM-DD — Short task name

- **Who / branch / commit:**
- **Work and files:**
- **Decisions and sources:**
- **Verification and result:**
- **Blockers or risks:**
- **Exact next action and owner:**
