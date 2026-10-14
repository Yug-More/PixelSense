# PixelSense

PixelSense is a native iPhone editor that changes the color and tone of a photo already in Apple Photos.

Users adjust exposure, contrast, saturation, and warmth, preview the result, and save it back to the same library item. A rule-based prompt will eventually fill those same controls. The app does not generate a new scene, move objects, or change geometry.

- **Course:** CS 152 — Programming Paradigms, San José State University, Fall 2026
- **Instructor:** Dr. Saptarshi Sengupta
- **First check-in:** October 20, 2026

## Product overview

PixelSense is for someone who wants a clearer or warmer photo without learning a full editing suite. The user picks a still photo they already have, changes a small set of color and tone settings, and keeps the result on that same Photos item.

The adjustment is stored as a versioned recipe, separate from the rendered image. Apple Photos keeps its own original and edited renditions. PixelSense cannot overwrite the library file in place, and it does not promise that an edit uses no extra storage.

## Problem

Manual color controls are precise, but the first choice of settings is slow when a person only knows the look they want in words. PixelSense keeps the controls, and will translate a short supported phrase into those controls so the person can review them before saving.

The check-in version solves the library, preview, and save path. Prompt interpretation is specified and not yet in the app.

## Key features

| Feature | Status |
| --- | --- |
| Choose an authorized still photo from the library | Implemented |
| Preview exposure, contrast, saturation, and warmth | Implemented |
| Compare the unadjusted and adjusted preview | Implemented |
| Reset sliders to the neutral recipe | Implemented |
| Save a JPEG rendition and recipe onto the same Photos item | Implemented in code; not verified on a physical iPhone |
| Reopen a PixelSense recipe and continue editing it | Implemented in code; not verified on a physical iPhone |
| Natural-language prompt that fills the same recipe | Planned for the October 20 check-in |
| Named presets | Planned |
| Region-specific adjustments | Planned; design only until a later milestone |
| Launch from the Photos app as an editing extension | Deferred |

## Current development status

`main` contains the first iPhone prototype: a SwiftUI library browser and an editor for four global controls. There is no prompt parser, no segmentation, and no unit-test target yet.

As of October 12, 2026, generic iOS Simulator and generic iPhone builds were reported with code signing disabled. That result does not show that Photos save-back works on hardware. No physical iPhone run is recorded.

Device screenshots are pending. After a real-device pass, captures belong in `docs/assets/`. This repository does not include product images.

Details and acceptance checks are in the [project plan](docs/PROJECT_PLAN.md). Session notes are in the [handoff](docs/HANDOFF.md). Component boundaries are in the [architecture](docs/ARCHITECTURE.md).

## Technology stack

| Layer | Choice |
| --- | --- |
| Language | Swift 5 |
| Interface | SwiftUI |
| Photos access and save | PhotoKit |
| Color and tone | Core Image |
| Recipe storage | Versioned JSON in `PHAdjustmentData` |
| Minimum system | iOS 17, iPhone |
| Distribution for class | Xcode with a free Apple Account Personal Team |
| Services | None. Photos stay on the device. |

The Xcode project has no third-party packages.

## System architecture

Solid boxes are on `main` today. Dashed boxes are planned and are not in the build.

```mermaid
flowchart TD
    subgraph now [Implemented]
        ui[SwiftUI interface]
        library[PhotoLibraryStore]
        editor[PhotoEditorModel]
        recipe[EditRecipe]
        renderer[AdjustmentRenderer]
        photos[PhotoKit save on the same asset]
    end

    subgraph later [Planned]
        prompt[Prompt interpreter]
        regions[Region masks]
    end

    ui --> library
    ui --> editor
    library --> photos
    editor --> recipe
    recipe --> renderer
    editor --> photos
    prompt -.-> recipe
    regions -.-> renderer
```

The prompt interpreter, when added, will only produce an `EditRecipe`. It will not render pixels and will not call a model. Region masks, when added, will only choose where the existing renderer applies settings.

## How PixelSense works

Implemented path:

1. The user allows read/write or limited Photos access and selects a still photo. Live Photos are skipped.
2. The editor loads a PhotoKit content-editing input and shows the photo.
3. Slider changes update one `EditRecipe`. The same recipe drives the preview and the full-size save.
4. The user compares **Show before** and **Show edit**, then taps **Save to this photo**.
5. PixelSense writes a JPEG rendition and the recipe, then commits that output on the selected asset. The save path does not create a new asset.

Planned path for the check-in: a text prompt is parsed into recipe values, the sliders update, and the user can change those values before the same save action. Unsupported phrases return an explanation and leave the current sliders alone.

```mermaid
flowchart LR
    select[Select a still photo] --> adjust[Adjust the four sliders]
    prompt[Enter a supported prompt] -.-> adjust
    adjust --> recipe[Build one EditRecipe]
    recipe --> preview[Preview the adjusted pixels]
    preview --> confirm[Confirm save]
    confirm --> update[Update the same Photos item]
```

The dashed step is the planned prompt. Sliders, preview, and save are the current app.

## Installation and setup

1. Install Xcode 15.4 or later. The deployment target is iOS 17.
2. Clone this repository and open `PixelSense.xcodeproj`.
3. Select the PixelSense target. Under **Signing & Capabilities**, choose the Personal Team for your own Apple Account.
4. Connect an iPhone running iOS 17 or later. If Xcode does not support that iOS version, update Xcode before running.
5. A free Personal Team install expires after seven days. Rebuild and reinstall after it expires. App Store and TestFlight distribution are outside the class prototype.

## Running the app

1. Build and run PixelSense on the connected iPhone.
2. Allow access to the photos you intend to edit.
3. Select a standard still photo. The browser shows up to 100 recent stills and excludes Live Photos.
4. Move exposure, contrast, saturation, or warmth. Use **Show before** and **Show edit** to compare.
5. Tap **Save to this photo**.
6. In the Photos app, confirm that the same library item shows the edit and that no second gallery item appeared.

Use a photo set aside for testing until save, reopen, and revert behavior have been checked on a device. The app does not upload the photo.

## Testing

The Xcode project does not yet include a test target. Recipe bounds, reset behavior, and the prompt parser are planned tests for the check-in. They are not in the tree, and this document does not treat them as passing.

What still needs a physical iPhone:

- Save updates one visible library item.
- Cancel or a failed save leaves the photo unchanged.
- A saved PixelSense edit reopens with the stored slider values.
- Photos revert behavior, orientation, metadata, JPEG appearance, iCloud downloads, and large photos.

A simulator build cannot establish those results.

## Programming paradigms

The course asks the project to use more than one paradigm where it fits the work.

**Object-oriented.** `PhotoLibraryStore` and `PhotoEditorModel` own library access, editor state, and the PhotoKit save request. The views observe those objects and do not perform the edit themselves.

**Functional.** `EditRecipe` is a value. `AdjustmentRenderer.apply` takes a recipe and a `CIImage` and returns another image. The preview and the save call that same function.

**Rule-based.** The check-in prompt parser will map a small phrase list onto recipe values, including intensity words and a fixed response to contradictory instructions. That parser is not in the app yet. It is not an AI model. Region rules are a later milestone.

## Development roadmap

| Milestone | Intent | Check-in position |
| --- | --- | --- |
| M0 Planning | Scope, platform, and ownership | Partial. Docs exist; device versions are still open |
| M1 Photos | Authorized selection and same-asset save | Code on `main`; physical-device acceptance is open |
| M2 Adjustments | One recipe for preview and save | Four controls on `main`; automated tests are open |
| M3 Prompts | Local phrases and presets mapped to that recipe | Specified for October 20; not implemented |
| M4 Regions | Masks that limit where settings apply | Design only for the check-in |
| M5 Demo polish | A full class demonstration | After the check-in |
| M6 Extension | The same editor inside Photos | Optional, after M1–M5 |

## Known limitations

- Only standard still photos are in scope. Live Photos, RAW, HDR, and video are deferred.
- The library browser lists at most 100 recent supported photos.
- Warmth is a fixed Core Image temperature shift. Its visual strength has not been judged on a device.
- Recipe numbers are limited by the sliders. The recipe type does not yet clamp values on its own.
- An edit made by another app is a baseline PixelSense does not try to reverse-engineer.
- Prompt interpretation, presets, and region masks are not available.
- Photos may download an iCloud original during editing. That network use is PhotoKit's, not an upload to a PixelSense server.
- There is no automated test suite in the project yet.

## Team and contributions

**Yug Amol More** (GitHub: [Yug-More](https://github.com/Yug-More)) — repository owner, check-in documentation, and the upcoming prompt work.

**Tejas** (GitHub: [Tejasvid29](https://github.com/Tejasvid29)) — project plan, iPhone prototype, and physical-device verification of the Photos save path.

The two students are the only GitHub collaborators. Session notes, including assisted work, are recorded in [docs/HANDOFF.md](docs/HANDOFF.md). Commits stay on the student accounts that make them.

## License and course use

PixelSense is a university project. Do not commit personal photos, signing certificates, or provisioning profiles.
