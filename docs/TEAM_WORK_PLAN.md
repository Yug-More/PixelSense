# PixelSense Team Work Plan

**Course:** CS 152 — Programming Paradigms, Fall 2026  
**University:** San José State University  
**Instructors / team:** Yug More (`Yug-More`), Tejas (`Tejasvid29`)  
**Document date:** October 20, 2026 (updated same day after PR #5 merge and rendering ownership rebalance)  
**Project check-in deadline:** October 22, 2026, 11:59 PM  
**Repository:** `Yug-More/PixelSense`  
**Base branch for remaining work:** `main` at `8101bc4` (merge of PR #5), then `feature/yug-rendering-improvements`

This document is the official internal engineering handoff for remaining development. It defines ownership, interfaces, milestones, and acceptance criteria so Yug and Tejas can work independently without conflicting edits. Status statements below reflect the repository after PR #5 and the transfer of Core Image reliability and preview-performance work from Tejas to Yug.

---

## 1. Project Overview

### What PixelSense does

PixelSense is a native iPhone app that adjusts **color and tone** of a still photo that already exists in Apple Photos. The user selects a photo, changes exposure, contrast, saturation, and warmth (manually, by typed instruction, by preset, or by automatic recommendation), previews the result, and can save the look back onto the **same visible Photos library item**.

The app does **not** generate new scene content, move objects, crop/rotate as a primary feature, or add a second gallery item during normal save.

### Intended users

Students and phone owners who want reversible color/tone edits on photos they already have. The first usable version must run locally on an iPhone without a paid Apple Developer Program membership, cloud account, server, or image upload.

### Main editing workflow

1. Grant Photos read/write (or limited) access.
2. Browse recent still photos (Live Photos excluded; list capped at 100).
3. Open one photo into the editor.
4. Adjust via sliders, natural-language prompt, preset, or automatic enhancement.
5. Compare before vs after; reset if needed.
6. Tap **Save to this photo** to write a JPEG rendition plus a versioned `EditRecipe` as `PHAdjustmentData`.
7. Reopen later: if PixelSense adjustment data is present, sliders restore those values.

### Technologies used

| Technology | Role |
| --- | --- |
| Swift / SwiftUI | App structure and UI |
| PhotoKit | Authorization, browsing, content editing, same-asset save |
| Core Image | Exposure, contrast, saturation, warmth rendering |
| XCTest + Swift CLI logic runner | Recipe and prompt logic tests |

No third-party packages.

### Key architectural components

| Component | File(s) | Role |
| --- | --- | --- |
| App entry | `PixelSense/App/PixelSenseApp.swift` | Hosts `ContentView` |
| Library UI + editor UI | `PixelSense/Editor/ContentView.swift` | Grid, editor screen, controls |
| Editor session | `PixelSense/Editor/PhotoEditorModel.swift` | Load, preview, prompt apply, save |
| Recipe | `PixelSense/Editor/EditRecipe.swift` | Versioned adjustment values and limits |
| Prompt rules | `PixelSense/Editor/PromptInterpreter.swift` | Deterministic phrase → recipe |
| Renderer | `PixelSense/Editor/AdjustmentRenderer.swift` | Core Image transforms |
| Library store | `PixelSense/Photos/PhotoLibraryStore.swift` | Auth + asset fetch |
| Recipe ↔ PhotoKit | `PixelSense/Photos/EditRecipePhotoKit.swift` | Decode `PHAdjustmentData` |
| Logic tests | `PixelSenseTests/` | Prompt/recipe checks |

### Project goals

- Demonstrate a working, reversible Photos editor for class check-in and final demo.
- Keep originals recoverable through Photos’ versioning (not a literal byte overwrite).
- Keep adjustment recipes separate from rendered pixels.
- Show CS 152 paradigms clearly in code and presentation.

### CS 152 programming paradigms demonstrated

| Paradigm | Where it appears |
| --- | --- |
| **Object-oriented** | `PhotoLibraryStore` and `PhotoEditorModel` own mutable session state; SwiftUI observes them |
| **Functional** | `EditRecipe` is a value; `AdjustmentRenderer.apply` and `PromptInterpreter.interpret` are pure transforms |
| **Rule-based interpretation** | Deterministic prompt matching, intensity tiers, conflict rejection — not a trained model |
| **Declarative UI** | SwiftUI views describe layout from published state |

---

## 2. Current Implementation Status

Statuses are from repository inspection on 2026-10-20 after PR #5. “Logic-tested” means the Swift CLI runner (52 tests after smart editing; rendering regression tests added on the rendering branch). “Device-tested” means a recorded physical iPhone result — **none recorded yet**.

| Feature | Relevant files | Implementation status | Verification status | Remaining work | Assigned owner |
| --- | --- | --- | --- | --- | --- |
| Photo library access | `PhotoLibraryStore.swift`, `ContentView.swift` | Implemented | Code present; not device-verified | Auth edge cases, Settings deep link check on device | Tejas |
| Photo selection / loading | `PhotoLibraryStore.swift`, `PhotoEditorModel.swift` | Implemented | Not device-verified | Large/iCloud photos, orientation | Tejas |
| Manual editing sliders | `ContentView.swift`, `PhotoEditorModel.swift`, `EditRecipe.swift` | Implemented | Logic limits tested; UI not device-verified | Visual tuning of warmth scale | Tejas (visual), shared model |
| Prompt interpretation | `PromptInterpreter.swift` | Implemented (four controls + intensity + conflicts + synonyms) | 52 logic tests on branch (includes prompts/presets/enhance) | Device UI check of prompt field | **Yug** |
| Edit recipes | `EditRecipe.swift` | Implemented (v1, clamp-on-decode) | Logic-tested | Keep format stable; no breaking schema without agreement | Shared (careful) |
| Image rendering | `AdjustmentRenderer.swift`, preview path in `PhotoEditorModel.swift` | Implemented; reliability/perf owned by Yug | Logic-tested for clamp/identity/scale; not device-verified | Device visual check of warmth direction | **Yug** (renderer), Tejas (device look) |
| Before/after comparison | `ContentView.swift` | Implemented | Not device-verified | Accessibility / clarity polish | Yug (UI), Tejas (device) |
| Reset functionality | `PhotoEditorModel.resetAdjustments`, `PromptApplication.reset` | Implemented | Logic-tested for prompt session | Ensure presets/auto-enhance reset cleanly | **Yug** |
| Photo saving | `PhotoEditorModel.save` | Implemented in code | **Not accepted** — no iPhone result | Full device checklist | **Tejas** |
| Reopening saved edits | `EditRecipe.decode`, `load()` | Implemented in code | Not device-verified | Confirm sliders restore after save | **Tejas** |
| Reverting to originals | Photos app revert (system) | Relies on Photos; app does not custom-revert | Not verified | Confirm Photos Edit → Revert | **Tejas** |
| Automatic enhancement | `ImageStatistics.swift`, `AutoEnhance.swift`, `ImageStatisticsSampler.swift` | Implemented on `feature/yug-smart-editing` | Logic-tested (synthetic stats); not device-verified visually | Device visual review | **Yug** (logic), Tejas (device look) |
| Smart presets | `EditPreset.swift` | Implemented on `feature/yug-smart-editing` | Logic-tested | Device UI check | **Yug** |
| Editor UX polish | `ContentView.swift` | Smart tools integrated | Not device-verified | Device layout check | **Yug** (UI), Tejas (device) |
| Region edits / Photos extension | Architecture notes only | Planned / out of scope for check-in | — | After M1 save is believable | Later (shared decision) |

---

## 3. Team Responsibility Matrix

Work is split by **component ownership**, not by equal task counts. Effort estimates include design, implementation, tests, and integration.

### Yug More — Smart Editing, Rendering Reliability, and Preview Performance

| # | Responsibility | Effort (est.) | Status |
| ---: | --- | --- | --- |
| 1 | Natural-language editing improvements (YUG-1) | 4–5 h | **Completed** (PR #5) |
| 2 | Rule-based automatic image enhancement (YUG-2) | 6–8 h | **Completed** (PR #5) |
| 3 | Smart editing presets (YUG-3) | 3–4 h | **Completed** (PR #5) |
| 4 | SwiftUI editor improvements (YUG-4) | 3–4 h | **Completed** (PR #5) |
| 5 | Unit tests for smart editing (YUG-5) | 2–3 h | **Completed** (PR #5) |
| 6 | Documentation for smart editing (YUG-6) | 2 h | **Completed** (PR #5) |
| 7 | Core Image rendering reliability (YUG-7; transferred from TEJ-3) | 4–5 h | In progress on rendering branch |
| 8 | Image preview / processing performance (YUG-8; transferred from TEJ-7) | 3–4 h | In progress on rendering branch |
| — | Check-in presentation / Career-Connect share (with Tejas) | 3–4 h | Outstanding |

Estimated **remaining** effort for Yug after PR #5: **~7–9 hours** of rendering work plus shared presentation prep.

### Tejas — PhotoKit Integration and Device Verification

Tejas **no longer owns** Core Image renderer reliability or preview-performance engineering. Those are YUG-7 and YUG-8.

| # | Responsibility | Effort (est.) | Status |
| ---: | --- | --- | --- |
| 1 | PhotoKit authorization and browsing hardening (TEJ-1) | 2–3 h | Outstanding |
| 2 | Photo selection and loading reliability (TEJ-2) | 2–3 h | Outstanding |
| 3 | ~~Core Image rendering reliability / performance~~ | — | **Transferred to YUG-7 / YUG-8** |
| 4 | Non-destructive photo saving verification + fixes (TEJ-4) | 5–7 h | Outstanding (P0) |
| 5 | Reopening saved edits (TEJ-5) | 2–3 h | Outstanding |
| 6 | Reverting edited photos (TEJ-6) | 1–2 h | Outstanding |
| 7 | ~~Image-processing reliability and performance~~ | — | **Transferred to YUG-8** |
| 8 | Full Xcode and device integration verification (TEJ-8) | 3–4 h | Outstanding (P0) |
| 9 | Tests for photo persistence behavior (TEJ-9; rendering tests now Yug) | 2–3 h | Outstanding |
| — | Check-in presentation / Career-Connect share (with Yug) | 3–4 h | Outstanding |

Estimated **remaining** effort for Tejas: **~15–22 hours**, dominated by hardware save verification and Xcode/device checklist work.

**Balance note:** Yug completed the smart-editing feature set and now owns the renderer. Tejas owns Photos integration risk. Neither side should edit the other’s owned files without coordination.

---

## 4. Yug — Detailed Implementation Specification

### YUG-1 — Natural-language editing improvements

| Field | Detail |
| --- | --- |
| **Task ID** | YUG-1 |
| **Title** | Improve deterministic prompt interpretation |
| **Objective** | Extend `PromptInterpreter` so common brightness/color/warmth phrases work reliably, while preserving all currently passing behaviors. |
| **Current status** | Implemented baseline: exposure/brightness, contrast, saturation, warmth; slight/standard/strong intensity; multi-clause; conflicts; unsupported; empty. 32 logic tests. |
| **Priority** | P0 for October 22 check-in demo |
| **Estimated effort** | 4–5 hours |
| **Relevant files** | `PixelSense/Editor/PromptInterpreter.swift`, `PixelSenseTests/LogicChecks.swift` |
| **Dependencies** | `EditRecipe` limits unchanged |

**Implementation requirements**

Keep the pipeline stages separated (as today):

1. Input normalization  
2. Command / phrase recognition  
3. Adjustment identification  
4. Direction interpretation  
5. Strength interpretation  
6. Conflict detection  
7. Recipe generation  
8. Error reporting  

Preserve: absolute replacement for mentioned controls; unmentioned controls unchanged; opposite directions → conflict; leftover unknown words → unsupported.

**Add / strengthen phrase coverage (examples):**

| Example input | Expected behavior |
| --- | --- |
| “Make this photo brighter.” | Increase exposure at standard intensity (`exposureEV = 1`) |
| “Reduce contrast slightly.” | `contrast = -0.125` |
| “Make the colors more vibrant.” | Increase saturation (vibrance synonym) |
| “Warm up the image.” | Increase warmth |
| “Increase brightness and reduce saturation.” | Both controls updated |
| “Make the photo a little warmer and more colorful.” | Slight warmth + saturation increase |

Add synonyms such as: vibrance/vibrant → saturation; “warm up” / “cool down”; keep brightness → exposure. Do **not** call an external model or network API.

**Note on “cinematic”:** The word remains blocked in the **prompt** interpreter (content/style request). A UI **preset** named Cinematic is separate and does not go through the prompt parser.

**Expected behavior:** Successful parse updates recipe; failure returns `PromptFailure` and leaves recipe unchanged.

**Edge cases:** Empty/punctuation-only; conflicting modifiers in one clause; warmer+cooler; mixed supported+unsupported; case/whitespace.

**Acceptance criteria**

- All previously passing logic tests still pass.  
- New synonym / multi-instruction cases covered by tests.  
- No change to PhotoKit save path or `AdjustmentRenderer`.

**Required tests:** Extend `PromptLogicChecks` for new phrases, vibrance, warm-up, multi-instruction examples above.

**Definition of done:** Tests pass via CLI logic runner; docs mention new phrases; no Tejas-owned files changed.

**Integration notes:** `PhotoEditorModel.applyPrompt` already consumes `PromptApplication`; keep that contract.

---

### YUG-2 — Rule-based automatic image enhancement

| Field | Detail |
| --- | --- |
| **Task ID** | YUG-2 |
| **Title** | Deterministic automatic enhancement |
| **Objective** | Recommend a conservative `EditRecipe` from image statistics without rewriting rendering or PhotoKit. |
| **Current status** | Not started |
| **Priority** | P1 for check-in if time; otherwise Milestone 2 (still start before final) |
| **Estimated effort** | 6–8 hours |
| **Relevant files (new/owned)** | `PixelSense/Editor/ImageStatistics.swift` (planned), `PixelSense/Editor/AutoEnhance.swift` (planned); small hooks in `PhotoEditorModel.swift` / `ContentView.swift` |
| **Dependencies** | Existing `EditRecipe`; preview `CIImage` from editor. Do **not** modify `AdjustmentRenderer` or PhotoKit save body. |

**Architecture (required separation)**

1. Image statistics extraction (downsample/sample for efficiency)  
2. Statistics representation (e.g. average luminance, contrast range proxy, average saturation)  
3. Recommendation rules with documented thresholds  
4. Edit recipe generation (clamped to existing ranges)  
5. Editor integration  

**Recommended conservative rules (document exact thresholds in code comments / ARCHITECTURE):**

| Condition | Suggested adjustment |
| --- | --- |
| Low average luminance (dark) | Modest positive exposure |
| High average luminance (bright) | Modest negative exposure or none |
| Low contrast proxy | Modest positive contrast |
| Low saturation | Modest positive saturation |
| Already balanced | Near-zero / empty recommendation |

**Application behavior**

- Applying auto-enhance **replaces** the current recipe with the recommended recipe (or merges only if documented — default: **replace** from neutral recommendation, not stack onto existing values).  
- Applying again on the same baseline must be **repeatable** (same stats → same recipe), not compounding.  
- If the user already moved sliders, auto-enhance should either (a) replace with recommendation from the **source** image stats (preferred), or (b) require Reset first — choose (a) and document it.  
- Reset returns to neutral (existing `resetAdjustments`).

**Expected behavior:** Button/action produces explainable recipe values and refreshes preview.

**Edge cases:** Missing/failed stats → clear error, no change; all-neutral image → little/no change; clamp to ranges.

**Acceptance criteria**

- Unit tests for stats/rules with synthetic statistics (no private photos).  
- Does not call PhotoKit save.  
- Does not modify renderer filter graph.

**Required tests:** Dark / bright / low-contrast / high-sat / balanced / invalid / clamp / repeatability / interaction with prior user values (replace behavior).

**Definition of done:** Logic tests pass; UI entry point present; architecture documented.

**Integration notes:** Yug now also owns renderer reliability and preview performance (YUG-7 / YUG-8). Auto-enhance still only feeds recipes into that shared path.

---

### YUG-3 — Smart editing presets

| Field | Detail |
| --- | --- |
| **Task ID** | YUG-3 |
| **Title** | Centralized smart presets |
| **Objective** | Provide named recipes (Portrait, Vibrant, Warm, Cinematic, Natural) using only supported adjustments. |
| **Current status** | Not started |
| **Priority** | P1 |
| **Estimated effort** | 3–4 hours |
| **Relevant files** | `PixelSense/Editor/EditPreset.swift` (planned), `ContentView.swift`, tests |
| **Dependencies** | `EditRecipe` ranges |

**Requirements**

Each preset defines: name, short description, `EditRecipe`, and application behavior.

**Suggested starting values (all within limits; tune if needed):**

| Preset | Exposure | Contrast | Saturation | Warmth |
| --- | ---: | ---: | ---: | ---: |
| Natural | 0 | 0 | 0 | 0 |
| Portrait | 0.3 | 0.05 | −0.1 | 0.15 |
| Vibrant | 0.1 | 0.15 | 0.45 | 0.05 |
| Warm | 0.1 | 0.05 | 0.1 | 0.55 |
| Cinematic | −0.15 | 0.25 | −0.2 | −0.1 |

**Application behavior:** Selecting a preset **replaces** the current recipe with the preset recipe. User may then refine with sliders or prompts. Reset clears to neutral (not “previous preset”).

**Edge cases:** Applying Natural equals reset of adjustments; rapid switching does not stack.

**Acceptance criteria:** Centralized definitions (no scattered magic numbers in the view); tests for definitions and replace behavior.

**Required tests:** Each preset within limits; apply replaces; Natural is neutral.

**Definition of done:** Presets selectable in editor; tests pass.

**Integration notes:** Prompt word “cinematic” remains unsupported; preset name is UI-only.

---

### YUG-4 — SwiftUI editor improvements

| Field | Detail |
| --- | --- |
| **Task ID** | YUG-4 |
| **Title** | Integrate smart editing into the editor UI |
| **Objective** | Clean SwiftUI integration of prompts, auto-enhance, presets, feedback, and accessibility without redesigning the whole app. |
| **Current status** | Prompt field + sliders + before/after + reset + save exist |
| **Priority** | P0/P1 |
| **Estimated effort** | 3–4 hours |
| **Relevant files** | `ContentView.swift`; minimal `PhotoEditorModel.swift` methods |
| **Dependencies** | YUG-1–3 |

**Include**

- Clearer prompt entry and error/success feedback  
- Automatic enhancement action  
- Preset selection (e.g. horizontal chips or menu)  
- Existing sliders, before/after, reset  
- Loading indicators and error handling (reuse existing)  
- Accessibility labels for new controls  

**Do not:** third-party UI; rewrite PhotoKit; change save semantics.

**Acceptance criteria:** User can apply prompt, preset, and auto-enhance in one editor session and still save via existing button.

**Required tests:** Prefer logic/model tests; UI is manually verified when Xcode/device available.

**Definition of done:** Integrated UI on branch; Tejas can open project without missing file references.

**Integration notes:** Coordinate any `PhotoEditorModel` API additions with Tejas (additive methods preferred).

---

### YUG-5 — Unit tests for smart editing

| Field | Detail |
| --- | --- |
| **Task ID** | YUG-5 |
| **Title** | Expand logic tests for Yug’s features |
| **Objective** | Keep CLI logic runner green; grow coverage for prompts, enhance, presets. |
| **Priority** | P0 |
| **Estimated effort** | 2–3 hours |
| **Files** | `PixelSenseTests/LogicChecks.swift`, `LogicTestMain.swift`, `PixelSenseLogicTests.swift` |

**Definition of done:** Documented command in README still works; count of tests updated honestly.

---

### YUG-6 — Documentation for smart editing

| Field | Detail |
| --- | --- |
| **Task ID** | YUG-6 |
| **Title** | Document interpreter, enhance, presets, paradigms |
| **Files** | `docs/ARCHITECTURE.md`, `README.md`, `docs/HANDOFF.md`, this plan |
| **Priority** | P1 |
| **Estimated effort** | 2 hours |

Do not claim trained AI or unverified device success.

---


### YUG-7 — Core Image rendering reliability

| Field | Detail |
| --- | --- |
| **Task ID** | YUG-7 |
| **Title** | Core Image rendering reliability |
| **Objective** | Make `AdjustmentRenderer` clamp inputs, reject invalid extents, keep deterministic filter order, and share the same transform path for preview and save. |
| **Current status** | Baseline renderer existed on `main`. Reliability improvements owned by Yug after rebalance (transferred from TEJ-3). |
| **Priority** | P0 |
| **Estimated effort** | 4–5 hours |
| **Relevant files** | `PixelSense/Editor/AdjustmentRenderer.swift`; additive preview helpers; logic tests |
| **Dependencies** | Stable `EditRecipe` v1; do not change PhotoKit save body |

**Implementation requirements**

1. Clamp every recipe through `EditRecipe.clamped()` / `AdjustmentRenderer.prepare` before Core Image parameters are set.  
2. Treat non-finite recipe values as neutral via existing clamp rules.  
3. Validate image extents (finite, non-empty, non-infinite) before filtering.  
4. Keep filter order: exposure → warmth → colorControls.  
5. Map warmth with documented Kelvin constants; keep positive warmth warmer.  
6. Provide `applyValidated` for explicit failure reporting without breaking `apply`.  
7. Do not change recipe JSON format or PhotoKit adjustment identifiers.

**Expected behavior:** Same prepared recipe yields the same CIImage graph for preview and save. Invalid images fail safely.

**Edge cases:** Neutral recipe is identity; out-of-range values clamp; infinite extent images are rejected or left unchanged by `apply`.

**Acceptance criteria**

- Logic tests cover clamp, parameter mapping, neutral identity, invalid extent, and filter-order documentation.  
- `PhotoEditorModel.save` still calls `AdjustmentRenderer.apply` on full-resolution input.  
- No PhotoKit persistence edits required for this task.

**Required tests:** Renderer regression checks in `PixelSenseTests/LogicChecks.swift`.

**Definition of done:** Tests pass; architecture notes updated if filter constants change.

**Integration notes:** Tejas continues to verify warmth direction on a physical display (TEJ-8). Yug owns the code path.

---

### YUG-8 — Image preview and processing performance

| Field | Detail |
| --- | --- |
| **Task ID** | YUG-8 |
| **Title** | Image preview / processing performance |
| **Objective** | Avoid full-resolution Core Image work on every slider update; reuse a preview-scaled source and a shared `CIContext`. |
| **Current status** | Transferred from TEJ-7. Prior preview path scaled the full image on every `updatePreview()`. |
| **Priority** | P1 |
| **Estimated effort** | 3–4 hours |
| **Relevant files** | `PreviewScaling` in `AdjustmentRenderer.swift`, `PhotoEditorModel.swift` preview path |
| **Dependencies** | YUG-7 prepare/apply behavior |

**Implementation requirements**

1. Downscale once per `load()` into a cached preview `CIImage` (cap longest side, currently 1200).  
2. Slider / prompt / preset updates render from the cached preview image only.  
3. Skip re-render when the prepared recipe has not changed.  
4. Neutral recipes reuse the cached before bitmap when possible.  
5. Keep a single `CIContext` for the editor session; use sRGB when materializing preview bitmaps.  
6. **Save must still process full-resolution** Photos input — never the preview pyramid.  
7. Auto-enhance sampling may continue to use the full source or a separate sampler; do not regress its determinism.

**Expected behavior:** Interactive edits feel responsive on large stills; save quality unchanged in intent.

**Edge cases:** Images already smaller than the preview cap; load failure clears preview caches.

**Acceptance criteria**

- Preview scale factor logic is unit-tested.  
- Code comments document that save is full resolution.  
- No fabricated millisecond benchmarks unless measured on simulator/device.

**Required tests:** `PreviewScaling` factor tests; existing renderer tests remain green.

**Definition of done:** Implementation on Yug’s branch; Tejas notes perceived lag on TEJ-8 large-photo row.

**Integration notes:** Tejas does not re-implement preview caching. Device timing belongs in TEJ-8 notes.

---

## 5. Tejas — Detailed Implementation Specification

### TEJ-1 — PhotoKit authorization and photo browsing

| Field | Detail |
| --- | --- |
| **Task ID** | TEJ-1 |
| **Title** | Harden Photos authorization and browsing |
| **Objective** | Reliable auth states and still-photo browsing on a real iPhone. |
| **Current status** | Implemented: `.readWrite`, authorized/limited treated as access, denied → Settings, refresh on appear/active, skip Live Photos, cap 100 |
| **Priority** | P0 |
| **Estimated effort** | 2–3 hours |
| **Files** | `PhotoLibraryStore.swift`, library portion of `ContentView.swift` |
| **Dependencies** | None from Yug |

**Requirements**

- Handle `.notDetermined`, `.authorized`, `.limited`, `.denied`, `.restricted`.  
- After limited access changes in Settings, refresh lists correctly.  
- Keep Live Photos excluded until a dedicated flow exists.  
- Surface empty-library messaging (already present; verify on device).

**Expected behavior:** User can grant access and see thumbnails of recent stills.

**Edge cases:** Deny then Settings; limited picker add; zero photos.

**Acceptance criteria:** Manual checklist TEJ-8 items for auth pass on Tejas’s iPhone.

**Required tests:** Prefer UI/manual; optional unit tests if mocking Photos is practical.

**Definition of done:** Results recorded in `docs/HANDOFF.md` with date and outcome (pass/fail + notes). No private photo contents.

**Integration notes:** Do not change recipe format while testing.

---

### TEJ-2 — Photo selection and loading

| Field | Detail |
| --- | --- |
| **Task ID** | TEJ-2 |
| **Title** | Reliable photo load into editor |
| **Objective** | `PhotoEditorModel.load` always gets oriented full-size input or a clear error. |
| **Current status** | Implemented with `PHContentEditingInput`, orientation, preview scale ≤1400 |
| **Priority** | P0 |
| **Estimated effort** | 2–3 hours |
| **Files** | `PhotoEditorModel.swift` (load path only), thumbnail view if needed |
| **Dependencies** | TEJ-1 |

**Requirements**

- Network access for iCloud-hosted assets already allowed (`isNetworkAccessAllowed = true`) — verify on device.  
- Clear errors for `noEditingInput` / `noImageData`.  
- Cancel or ignore stale loads if user navigates away (if feasible).

**Edge cases:** HEIC, large images, iCloud download delay, previously edited by other apps.

**Acceptance criteria:** Three different still photos load with before preview visible.

**Required tests:** Manual; optional timing notes for large images.

**Definition of done:** Handoff entry with pass/fail.

---

### TEJ-3 — Core Image rendering infrastructure — TRANSFERRED

| Field | Detail |
| --- | --- |
| **Task ID** | TEJ-3 |
| **Status** | **Transferred to YUG-7** (reliability) and **YUG-8** (preview performance) on 2026-10-20 |
| **Tejas action** | Do not implement renderer changes. On TEJ-8, visually confirm warmth direction and note any lag on large photos. |

---

### TEJ-4 — Non-destructive photo saving

| Field | Detail |
| --- | --- |
| **Task ID** | TEJ-4 |
| **Title** | Same-asset PhotoKit save verification and fixes |
| **Objective** | Prove saving updates one visible Photos item with JPEG + adjustment data; fix failures. |
| **Current status** | Code complete on `main`; **acceptance not met** (no physical result) |
| **Priority** | **P0 — blocks calling M1 done** |
| **Estimated effort** | 5–7 hours |
| **Files** | `PhotoEditorModel.save`, `EditRecipePhotoKit.swift`; avoid drive-by UI rewrites |
| **Dependencies** | TEJ-2; renderer path from YUG-7/YUG-8 on `main` |

**Detailed requirements**

1. **Authorization:** Save only when library write access is available; show clear error if revoked mid-session.  
2. **Save behavior:** Use `PHContentEditingOutput` + `renderedContentURL(for: .jpeg)` + `PHAdjustmentData` with `edu.sjsu.pixelsense.recipe` / `1`. Assign `contentEditingOutput` on existing `PHAsset` — **never** `PHAssetChangeRequest.creationRequestForAsset`.  
3. **Failure handling:** Surface `PhotoEditError` / system errors in UI; leave library unchanged on failure.  
4. **Adjustment-data compatibility:** `canHandleAdjustmentData` remains true only for PixelSense v1 decode.  
5. **Verification:** After save, gallery shows **one** updated item in place; no duplicate.

**Expected behavior:** Message “Saved to the same photo in your library.” and visible change in Photos.

**Edge cases:** JPEG unsupported → error; mid-save backgrounding; repeat save; cancel by navigating away before tap.

**Acceptance criteria:** Checklist in TEJ-8 all save-related rows pass on a test photo reserved for this purpose.

**Required tests:** Manual device script; record outcomes. Automated Photos tests are optional if environment allows.

**Definition of done:** Handoff records pass; M1 may be marked accepted only then.

**Integration notes:** Do not change prompt semantics while fixing save.

---

### TEJ-5 — Reopening saved edits

| Field | Detail |
| --- | --- |
| **Task ID** | TEJ-5 |
| **Title** | Restore PixelSense recipe on reopen |
| **Objective** | After save, reopening the asset restores slider values from adjustment data. |
| **Current status** | Implemented via `EditRecipe.decode` in `load()` |
| **Priority** | P0 after TEJ-4 |
| **Estimated effort** | 2–3 hours |
| **Files** | `PhotoEditorModel.load`, `EditRecipePhotoKit.swift` |

**Requirements:** Unknown foreign adjustment data → start from Photos baseline with neutrals; do not invent foreign settings.

**Acceptance criteria:** Save exposure +0.5 → reopen → exposure slider shows +0.5 (± rounding).

**Definition of done:** Device result recorded.

---

### TEJ-6 — Reverting edited photos

| Field | Detail |
| --- | --- |
| **Task ID** | TEJ-6 |
| **Title** | Confirm Photos revert restores original |
| **Objective** | Document whether Apple Photos “Revert to Original” works for PixelSense edits. |
| **Current status** | Relies on system Photos behavior; unverified |
| **Priority** | P1 |
| **Estimated effort** | 1–2 hours |
| **Files** | Usually documentation only unless a bug is found |

**Requirements:** After PixelSense save, use Photos Edit → Revert (wording may vary by iOS). Confirm original look returns and PixelSense reopen starts neutral or from new baseline as Photos provides.

**Acceptance criteria:** Pass/fail recorded; if fail, open issue note for follow-up (may be platform limitation).

---

### TEJ-7 — Image-processing reliability and performance — TRANSFERRED

| Field | Detail |
| --- | --- |
| **Task ID** | TEJ-7 |
| **Status** | **Transferred to YUG-8** on 2026-10-20 |
| **Tejas action** | During TEJ-8, open a large still and record whether preview stays usable. File bugs against Yug’s renderer/preview code if crashes appear. |

---

### TEJ-8 — Full Xcode and device integration verification

| Field | Detail |
| --- | --- |
| **Task ID** | TEJ-8 |
| **Title** | Xcode build + physical iPhone checklist |
| **Objective** | End-to-end verification Tejas owns. |
| **Priority** | P0 |
| **Estimated effort** | 3–4 hours |
| **Dependencies** | Latest `main` or integrated feature branch |

**Manual test checklist** (copy into handoff; fill Actual):

| # | Step | Expected | Actual | Pass? |
| ---: | --- | --- | --- | --- |
| 1 | Open project in Xcode 15.4+ | Builds for Tejas’s iPhone | | |
| 2 | Run on device | App launches | | |
| 3 | Deny Photos then allow | Auth UI correct | | |
| 4 | Browse grid | Stills only, ≤100 | | |
| 5 | Open photo | Preview loads | | |
| 6 | Move all four sliders | Preview updates | | |
| 7 | Before/after toggle | Switches correctly | | |
| 8 | Reset | Neutrals + original look | | |
| 9 | Apply demo prompt | Sliders match spec | | |
| 10 | Apply unsupported prompt | Error; no change | | |
| 11 | Save to this photo | Same item updates; no duplicate | | |
| 12 | Reopen in PixelSense | Recipe restored | | |
| 13 | Revert in Photos | Original restored | | |
| 14 | Large photo | No crash | | |
| 15 | Force-quit mid-edit before save | Library unchanged | | |

Simulator-only results do **not** clear M1 save acceptance.

---

### TEJ-9 — Tests for photo persistence

| Field | Detail |
| --- | --- |
| **Task ID** | TEJ-9 |
| **Title** | Tests for photo persistence behavior |
| **Objective** | Add automated or semi-automated checks for authorization/save/reopen behavior where practical. Renderer regression tests are Yug’s (YUG-7). |
| **Priority** | P2 |
| **Estimated effort** | 2–3 hours |
| **Files** | New tests under `PixelSenseTests/` owned by Tejas; do not break the CLI logic runner |

**Acceptance criteria:** Persistence-focused tests or a recorded manual matrix for TEJ-4/TEJ-5. Do not duplicate Yug’s renderer logic tests.

---

## 6. File Ownership and Shared Interfaces

### Ownership matrix

| File | Owner | Notes |
| --- | --- | --- |
| `PromptInterpreter.swift` | **Yug** | |
| `ContentView.swift` | **Yug** (primary) | Tejas may propose library-screen fixes via PR review |
| `ImageStatistics.swift` / `AutoEnhance.swift` (new) | **Yug** | |
| `EditPreset.swift` (new) | **Yug** | |
| Yug’s unit test additions | **Yug** | Includes renderer regression tests |
| `AdjustmentRenderer.swift` | **Yug** | Transferred from Tejas |
| `PreviewScaling` (in renderer file) | **Yug** | Preview cap and scale helpers |
| `PhotoLibraryStore.swift` | **Tejas** | |
| `EditRecipePhotoKit.swift` | **Tejas** | |
| Tejas’s persistence tests | **Tejas** | Not renderer tests |
| `PhotoEditorModel.swift` | **Shared** | Yug owns preview caching; Tejas owns `save()` / load PhotoKit details |
| `EditRecipe.swift` | **Shared** | No breaking field/format changes without agreement |
| Xcode project / scheme | **Shared** | Whoever adds a file updates `project.pbxproj` in the same commit |
| `docs/ARCHITECTURE.md` | **Shared** | Section ownership by topic |
| `docs/TEAM_WORK_PLAN.md` | **Shared** | Update status rows when tasks complete |

### Coordination rules for shared files

1. Prefer **backward-compatible** additive methods on `PhotoEditorModel` (e.g. `applyPreset`, `applyAutoEnhance`).  
2. Do not change `EditRecipe` format identifier/version or remove fields.  
3. Avoid simultaneous edits: if both need `PhotoEditorModel`, sequence PRs (Yug first for smart APIs, Tejas merges save fixes carefully).  
4. Rebase/merge `main` before opening PRs.

### How components communicate (actual)

```text
ContentView / PhotoEditorView
  → PhotoLibraryStore (auth, assets)
  → PhotoEditorModel (load, sliders, applyPrompt, save)
       → PromptInterpreter / PromptApplication (text → recipe)
       → AdjustmentRenderer.apply (recipe + CIImage → CIImage)
       → EditRecipe.encode / PHAdjustmentData (on save)
       → EditRecipe.decode (on load)
```

**Proposed (Yug):**

```text
PhotoEditorView
  → PhotoEditorModel.applyPreset(EditPreset)
  → PhotoEditorModel.applyAutoEnhance()
       → ImageStatistics.from(CIImage)
       → AutoEnhance.recommend(stats) → EditRecipe
       → set sliders + updatePreview
```

### Data contracts summary

| From → To | Contract |
| --- | --- |
| PromptInterpreter → EditRecipe | `Result<EditRecipe, PromptFailure>`; mentioned controls replaced; others kept |
| AutoEnhance → EditRecipe | Recommendation within ranges; apply replaces session recipe from source stats |
| Preset → editor state | Named `EditRecipe`; apply replaces |
| Editor → renderer | Current recipe + source `CIImage` |
| Editor → PhotoKit | Load input; save JPEG + adjustment data on same asset |

---

## 7. Integration Contracts

### Prompt interpreter → edit recipe

| Aspect | Contract |
| --- | --- |
| **Inputs** | Normalized user string; optional `current: EditRecipe` |
| **Outputs** | Success: updated recipe; Failure: `empty`, `conflict`, `conflictingModifiers`, `unsupported` |
| **Error handling** | Message via `PromptFailure.message`; recipe unchanged |
| **Bounds** | Values = direction × control limit × intensity fraction; then `clamped()` |
| **Conflicts** | Opposite directions on one control → failure |

### Automatic enhancement → edit recipe

| Aspect | Contract |
| --- | --- |
| **Inputs** | `ImageStatistics` from source preview/full image (downsampled) |
| **Outputs** | `EditRecipe` recommendation |
| **Ranges** | Must satisfy `EditRecipe` limits |
| **Application** | Replace current slider recipe; refresh preview; do not save |
| **Reset** | `resetAdjustments()` → all zeros |

### Presets → editor state

| Aspect | Contract |
| --- | --- |
| **Representation** | `EditPreset` with id, name, description, recipe |
| **Applying** | Replace current recipe |
| **Manual adjustments** | Allowed after preset |
| **Reset** | Neutral zeros (not last preset) |

### Editor → rendering

| Aspect | Contract |
| --- | --- |
| **State updates** | Published doubles → `EditRecipe` computed property |
| **Preview refresh** | `updatePreview()` after any recipe change |
| **Errors** | `errorMessage` / `promptError` as appropriate |

### Editor → PhotoKit

| Aspect | Contract |
| --- | --- |
| **Loading** | Content editing input; decode PixelSense v1 if present |
| **Save** | Same asset; JPEG; adjustment data |
| **Reopen** | Decode recipe into sliders |
| **Revert** | System Photos UI (Tejas verifies) |
| **Permissions** | Library store + runtime errors |

---

## 8. Development Milestones

### Milestone 1 — October 22 Check-In

**Goal:** Stable prototype + clear architecture explanation + course deliverables. Prefer verified behavior over new unverified features.

| Item | Owner | Notes |
| --- | --- | --- |
| Stable existing prototype (browse → edit → save code path) | Both | Tejas verifies save on device |
| Verified prompt interpretation (logic tests) | Yug | Demo phrases + conflict refusal |
| Available logic tests green | Yug | CLI runner |
| Demonstrable editor behavior | Both | Simulator or device |
| Architecture explanation | Yug (docs) + both (slides) | Paradigms |
| 8–10 slide presentation + ~10 min recording (both speak) | Both | |
| Career-Connect document | Both (agree split) | |
| Approved Oct 22 event attendance + 200–300 word reflection | Each student | Individual |
| Registration confirmation + Canvas submissions | Each student | Individual |

Do **not** mark auto-enhance or presets “complete” for the check-in unless tested. Showing them as “in progress” is acceptable if prompt + sliders + architecture are solid.

### Milestone 2 — Final Project

| Item | Owner |
| --- | --- |
| Remaining smart editing polish | Yug |
| Automatic enhancement complete + tested | Yug |
| Presets complete + tested | Yug |
| Rendering reliability | Tejas |
| PhotoKit verification complete | Tejas |
| Performance improvements | Tejas |
| Additional testing | Both |
| Final demonstration | Both |

---

## 9. Independent Development Workflow

1. Start from latest `main` (`git pull`).  
2. Create a focused branch:  
   - Yug: `feature/yug-smart-editing`  
   - Tejas: `feature/tejas-photos-verification` (or similar)  
3. Respect file ownership; shared files get additive changes and early PR description.  
4. Commit messages: imperative, clear, student-professional (`Improve natural language photo editing`).  
5. Open PR into `main`; request the other teammate as reviewer.  
6. Do not force-push shared history; no collaborator changes.  
7. After merge, update `docs/HANDOFF.md`.  
8. Conflicts: discuss on shared files before rewriting each other’s commits.  
9. Integration: Tejas runs device checklist on merged `main`.  
10. Documentation updates ship in the same PR as the behavior they describe when practical.

---

## 10. Testing Responsibilities

### Yug testing checklist

| Test | Expected | Actual | Pass? |
| --- | --- | --- | --- |
| Prompt parsing (demo phrases) | Spec values | | |
| Multiple instructions | Combined recipe | | |
| Unsupported instructions | Error, no change | | |
| Conflicts | Error, no change | | |
| Auto-enhance recommendations | Matches rules for synthetic stats | | |
| Preset application | Replaces recipe | | |
| Editor state after prompt/preset/enhance | Sliders match | | |
| Reset | All zeros | | |
| Renderer clamp / identity / invalid extent | Pass logic tests | | |
| Preview scale factors | Pass logic tests | | |

**Command (logic tests):**

```bash
swiftc -parse-as-library -D LOGIC_TEST_RUNNER -o /tmp/pixelsense-logic-tests \
  PixelSense/Editor/EditRecipe.swift \
  PixelSense/Editor/PromptInterpreter.swift \
  PixelSense/Editor/EditPreset.swift \
  PixelSense/Editor/ImageStatistics.swift \
  PixelSense/Editor/AutoEnhance.swift \
  PixelSense/Editor/AdjustmentRenderer.swift \
  PixelSenseTests/LogicChecks.swift \
  PixelSenseTests/LogicTestMain.swift
/tmp/pixelsense-logic-tests
```

(Adjust file list to match files that exist when running.)

### Tejas testing checklist

| Test | Expected | Actual | Pass? |
| --- | --- | --- | --- |
| Xcode build | Success | | |
| Simulator launch | Optional; note only | | |
| Photos permissions | Correct UI | | |
| Photo loading | Preview shown | | |
| Core Image rendering | Visible correct direction | | |
| Saving edited photos | Same item; no duplicate | | |
| Reopening edits | Sliders restored | | |
| Reverting originals | Photos revert works | | |
| Large-image handling | No crash | | |
| Error recovery | Clear messages | | |

---

## 11. Integration and Completion Checklist

### Yug must deliver

- [x] YUG-1 prompt improvements + tests  
- [x] YUG-2 auto-enhance + tests  
- [x] YUG-3 presets + tests  
- [x] YUG-4 editor UI integration  
- [x] YUG-5 expanded tests green  
- [x] YUG-6 documentation updates  
- [x] YUG-7 renderer reliability + tests  
- [x] YUG-8 preview performance  
- [ ] Rendering/README PR merge-ready  

### Tejas must deliver

- [ ] TEJ-1 auth/browsing hardening as needed from device findings  
- [ ] TEJ-2 selection/loading reliability  
- [ ] TEJ-4 same-asset save verification + fixes (**P0**)  
- [ ] TEJ-5 reopen verification  
- [ ] TEJ-6 Photos revert verification  
- [ ] TEJ-8 checklist filled in handoff (**P0**)  
- [ ] TEJ-9 persistence tests where practical  
- [ ] M1 save acceptance only after hardware pass  

Tejas should **not** pick up TEJ-3 or TEJ-7; those are Yug’s.  

### Shared verification

- [ ] `main` builds on Tejas’s Mac  
- [ ] Logic tests pass on Yug’s Mac  
- [ ] No recipe format break  
- [ ] README matches reality  

### Pull request requirements

- Clear summary, test commands/results, integration notes for the other owner  
- No secrets, provisioning profiles, or personal photos  

### Remaining blockers (as of 2026-10-20)

1. Physical iPhone save/reopen/revert unverified (Tejas).  
2. Full `xcodebuild` may be unavailable on Yug’s machine (Command Line Tools only) — Tejas owns Xcode verification.  
3. Check-in course artifacts (slides, recording, Career-Connect, event) are outside the repo but owned jointly.


### What Tejas should do next

1. Pull latest `main` after Yug’s rendering PR merges.  
2. Run TEJ-8 on a physical iPhone with a disposable test photo.  
3. Prioritize TEJ-4 (same-asset save). Record pass/fail in `docs/HANDOFF.md`.  
4. Complete TEJ-5 and TEJ-6.  
5. Fix only PhotoKit / load / save issues under Tejas-owned files.  
6. File renderer visual bugs against Yug; do not rewrite `AdjustmentRenderer`.  
7. Share check-in slides: Tejas covers Photos/device; Yug covers smart editing and renderer.

### Completion criteria for “smart editing sprint”

Yug’s features are complete when logic tests pass and UI hooks exist. Product “done” for Photos save still requires Tejas’s TEJ-8.

---

## 12. Contribution Tracking

Use this table going forward. Do not invent past history; earlier commits already exist under student accounts.

| Task ID | Owner | Completion date | PR | Test evidence | Review status |
| --- | --- | --- | --- | --- | --- |
| TEAM plan document | Yug | 2026-10-20 | `feature/yug-smart-editing` | Doc review | Pending merge |
| YUG-1 | Yug | 2026-10-20 | `feature/yug-smart-editing` | Prompt cases in 52 logic tests | Pending merge |
| YUG-2 | Yug | 2026-10-20 | `feature/yug-smart-editing` | Auto-enhance logic tests | Pending merge |
| YUG-3 | Yug | 2026-10-20 | `feature/yug-smart-editing` | Preset catalog tests | Pending merge |
| YUG-4 | Yug | 2026-10-20 | `feature/yug-smart-editing` | Code review; no device UI yet | Pending merge |
| YUG-5 | Yug | 2026-10-20 | `feature/yug-smart-editing` | `Passed 52 logic tests` | Pending merge |
| YUG-6 | Yug | 2026-10-20 | PR #5 merged | Docs updated | Merged |
| YUG-1–YUG-5 | Yug | 2026-10-20 | PR #5 merged | 52 logic tests at merge | Merged |
| YUG-7 | Yug | 2026-10-20 | `feature/yug-rendering-improvements` | Renderer regression tests in 61 logic tests | Pending merge |
| YUG-8 | Yug | 2026-10-20 | `feature/yug-rendering-improvements` | Preview scaling + cache path | Pending merge |
| TEJ-1 | Tejas | | | | Outstanding |
| TEJ-2 | Tejas | | | | Outstanding |
| TEJ-3 | — | 2026-10-20 | — | Transferred to YUG-7/YUG-8 | Transferred |
| TEJ-4 | Tejas | | | | Outstanding |
| TEJ-5 | Tejas | | | | Outstanding |
| TEJ-6 | Tejas | | | | Outstanding |
| TEJ-7 | — | 2026-10-20 | — | Transferred to YUG-8 | Transferred |
| TEJ-8 | Tejas | | | | Outstanding |
| TEJ-9 | Tejas | | | | Outstanding |

When a task finishes, update the row and append a dated entry in `docs/HANDOFF.md`.

---

## Appendix A — Existing prompt intensity semantics (do not break)

| Strength words | Fraction of control limit |
| --- | ---: |
| slightly, a bit, a little, a little bit | 0.25 |
| (none) | 0.50 |
| much, a lot, strongly, significantly | 1.00 |

| Control | Limit used for magnitude |
| --- | ---: |
| Exposure | 2 |
| Contrast | 0.5 |
| Saturation | 1 |
| Warmth | 1 |

## Appendix B — October 22 course deliverables (ownership)

| Deliverable | Owner |
| --- | --- |
| Slides (8–10) | Both — Yug drafts architecture/prompt slides; Tejas drafts Photos/device slides |
| ~10 minute recording | Both must speak |
| Career-Connect document | Agree split; both names |
| Event attendance Oct 22 | Each student |
| 200–300 word reflection | Each student |
| Registration confirmation | Each student |
| Canvas submission | Each student |

---

*End of team work plan.*
