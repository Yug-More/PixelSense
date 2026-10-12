# PixelSense project plan

Last updated: 2026-10-12

## Product decision

Build a native iPhone app that reads photos the user authorizes from Apple Photos, adjusts the photo's color and tone, and saves the result to the **same visible Photos item**. No generated content, object editing, geometry changes, or extra gallery item is part of the normal edit flow. Apple Photos retains and manages its original and edited data internally; literal overwriting of its original file is not an available app operation.

The class prototype will be built and tested on the students' own devices with Xcode and free Apple Accounts. App Store and TestFlight distribution are outside the initial scope. Free personal-team installs expire after seven days and must be rebuilt and reinstalled.

## Proposed architecture

| Part | Responsibility | Initial approach |
| --- | --- | --- |
| iPhone interface | Library selection, prompt, sliders, comparison, save confirmation | SwiftUI |
| Photos integration | Read a permitted asset, request edit input, save output to that asset | PhotoKit |
| Adjustment engine | Render exposure, contrast, saturation, warmth, and later tone controls | Core Image |
| Edit recipe | Versioned, compact adjustment values and optional region overrides | `PHAdjustmentData`; no image bytes in the recipe |
| Prompt interpretation | Turn supported phrases into recipe values and explain unsupported requests | Local rules first; evaluate a model only if rules cannot meet the agreed demo |
| Region targeting | Limit adjustments to recognized areas without changing their content | Add after global editing works; validate masks and edge quality on device |

Keep image processing on the device for the first version. A Photos editing extension, which would launch from the Photos app's Edit flow, is a later milestone after the standalone app can reliably save back to an existing asset.

## Initial implementation choices — 2026-10-12

The first prototype targets iOS 17 or later and standard still photos. It began with exposure from -2 to +2 EV as the smallest end-to-end save-back proof; contrast, saturation, and warmth controls now share the same versioned recipe and renderer. It shows up to 100 recent still photos and excludes Live Photos. Prompt parsing, region masks, and the Photos editing extension remain later milestones. These choices can be revised after Tejas provides his device/iOS version and the first physical-device test.

## Milestones and acceptance checks

### M0 — Requirements and environment

**Deliverables:** agreed MVP scope, supported photo types and iOS target, Xcode project structure, two-student task ownership, sample photos that the team has permission to use.

- Confirm both students' iPhone and macOS/Xcode versions; select a deployment target they can test.
- Decide whether the first release supports standard still photos only; defer Live Photos, RAW, HDR, and video until their behavior is tested.
- Define the first settings and ranges. Suggested start: exposure, contrast, saturation, warmth.
- Write down three demo prompts and expected slider changes before implementing prompt rules.

**Done when:** the app builds on both students' machines or an environment gap is documented, and the team agrees on the first device test.

### M1 — Library access and same-asset save proof

**Deliverables:** minimal app that selects an authorized photo, previews a simple visible adjustment, and saves through a PhotoKit content editing session.

- Request only the Photos access needed to read and edit; handle authorized, limited, denied, and revoked access.
- Fetch the selected `PHAsset` and request `PHContentEditingInput`.
- Render an adjusted full-resolution image to `PHContentEditingOutput.renderedContentURL`.
- Store a versioned adjustment recipe in `PHAdjustmentData` and commit `PHAssetChangeRequest.contentEditingOutput` through `PHPhotoLibrary.performChanges`.
- Do not create a new `PHAsset` during the normal save path.

**Done when:** a physical iPhone shows the changed photo in the same library position, with no new visible gallery item; saving can be repeated; cancel leaves the photo unchanged; errors are shown clearly. Verify whether Photos can revert the edit and record the result.

### M2 — Reversible adjustment engine

**Deliverables:** a single adjustment model used by manual controls, presets, and prompts.

- Define a `Recipe` schema with version, adjustment values, and optional per-region overrides.
- Implement pure transformations and a stable rendering order. Render previews efficiently and a full-resolution result for save.
- Load PixelSense adjustment data when reopening an edit so sliders match the saved values.
- Handle an asset already edited by another app: work from the input Photos provides and never claim those earlier settings are editable if its recipe is unknown.
- Check orientation, metadata preservation, color appearance, output type, and memory use on representative photos.

**Done when:** setting a slider to the same value gives a consistent result; reset returns to the Photos-provided baseline; a saved PixelSense edit can be reopened and refined without stacking unintended duplicate adjustments.

### M3 — Prompt interpretation and presets

**Deliverables:** local, explainable mappings from supported phrases and presets to the same recipe used by sliders.

- Define a small vocabulary and rules for warm/cool, brighter/darker, more/less contrast, and more/less saturation.
- Resolve conflicting instructions predictably; display the resulting values to the user before save.
- Add a few named presets as recipe values, not separate image generation paths.
- Make unsupported or ambiguous prompts produce a helpful message rather than silently guessing.

**Done when:** the agreed demo prompts produce documented settings, users can refine them manually, and no prompt changes image content or geometry.

### M4 — Region-aware adjustments

**Deliverables:** optional region overrides for at least one reliable case, such as subject versus background.

- Evaluate an on-device segmentation approach against team-owned sample photos. Treat sky as a separate feasibility item, not an assumed capability.
- Create a mask only to choose where the existing adjustment engine applies settings; feather boundaries to avoid visible halos.
- Provide a clear fallback to global adjustments when a region cannot be found confidently.
- Recompute or otherwise manage masks when reopening an edit; keep `PHAdjustmentData` compact.

**Done when:** a region-specific demo changes the intended area without obvious edge artifacts or content changes, and failure cases are visible and recoverable.

### M5 — Usable editor and class demo

**Deliverables:** polished selection, prompt, sliders, preset choice, before/after comparison, save, and error states.

- Make the save action explicit and show when Photos has finished the change request.
- Confirm the normal flow does not add a gallery item. Explain in the UI that saving updates the selected Photos item.
- Test limited library access, an iCloud-hosted photo, large images, cancellation, repeat edits, and permission changes where devices allow.
- Prepare a short demonstration and a comparison set covering normal and difficult photos.
- Document how object-oriented organization, functional transforms, and rule-based prompt decisions appear in the code.

**Done when:** a student can follow the demo from photo selection to same-item save on a physical iPhone without developer intervention, and the README contains setup and known limitations.

### M6 — Optional Photos editing extension

**Deliverables:** an extension that exposes the same editor from within Apple Photos.

- Share the adjustment engine and recipe format with the main app.
- Implement `PHContentEditingController` and test its host-specific lifecycle.

**Done when:** a user can start in Photos, invoke PixelSense from the editing flow, save, and reopen the edit on a physical device. Do this only after M1–M5 are reliable and the course schedule permits.

## Two-student coordination

The students should agree on owners before parallel implementation. A practical split is **Photos integration and on-device testing** versus **adjustment engine, prompt rules, and editor UI**, with shared review at each milestone. Keep interfaces and recipe schema agreed in writing before both sides code against them. Use focused branches for overlapping work, and record branch/commit references in `docs/HANDOFF.md`. No AI agent or bot needs GitHub collaborator access; students use their own accounts and review each other's changes.

## Main risks and decisions still open

1. **Physical storage:** PhotoKit updates one visible asset but Photos stores versions internally. Confirm the team accepts this as the meaning of “no duplicate.”
2. **Device compatibility:** Xcode 15.4 is installed on the current Mac as of 2026-10-12. Confirm the students' iOS versions and whether an Xcode update is needed.
3. **Photo types:** decide the first supported formats and whether Live Photos, RAW, and HDR are postponed.
4. **Region quality:** subject and sky masks may need different approaches; prove one region case before broad claims.
5. **Prompt breadth:** start with reliable rules; decide later whether more flexible language understanding is worth its cost, privacy, and testing complexity.
6. **Course constraints:** confirm the deadline, rubric, allowed libraries, and required demonstration of programming paradigms.

## Apple references

- [Editing Asset Content](https://developer.apple.com/documentation/photokit/editing-asset-content)
- [PHContentEditingOutput](https://developer.apple.com/documentation/photos/phcontenteditingoutput)
- [Photos privacy and limited access](https://developer.apple.com/documentation/PhotoKit/delivering-an-enhanced-privacy-experience-in-your-photos-app)
- [Core Image color adjustment filters](https://developer.apple.com/documentation/coreimage/color-adjustment-filters)
- [Creating Photo Editing Extensions](https://developer.apple.com/documentation/PhotoKit/creating-photo-editing-extensions)
- [Free account device-testing limits](https://developer.apple.com/help/account/basics/about-your-developer-account)
