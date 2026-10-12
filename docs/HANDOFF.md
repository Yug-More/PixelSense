# PixelSense handoff

This is the shared, human-readable state of the project for Tejas, Yug, and any agents helping them. Read it with `README.md`, `docs/PROJECT_PLAN.md`, and `AGENTS.md` before starting work. Update the current-state summary and append a work-log entry before every handoff.

## Current state — 2026-10-12

- **Repository:** `Yug-More/PixelSense`; Codex assisting Tejas owns `feature/ios-photo-editing-proof` for the first native iPhone app and PhotoKit save-back proof. The implementation is ready for source review and a physical-device test; consult `git status` and `git log` for its final commit and merge state.
- **Shared documentation:** commit `6906e3b` on `main` contains the current README, project plan, agent guidelines, and this handoff. Consult `git log` for subsequent handoff updates.
- **Agreed product direction:** native iPhone app, Apple Photos library access, color/tone adjustment of an existing photo, save to the same visible Photos item, no added gallery item in the normal flow, no generated or reshaped content.
- **Platform constraint:** Apple Photos manages original and edited data internally. The app cannot overwrite the library's original file byte-for-byte or promise zero extra storage. This distinction must remain clear in code, docs, and demos.
- **Cost decision:** build and test on the students' own iPhones with Xcode and free Apple Accounts. No App Store or TestFlight distribution is planned for the class prototype. Free personal-team installations expire after seven days and require reinstalling.
- **Environment checked:** Xcode 15.4 is installed on Tejas's current Mac. Device iOS versions and teammate environment have not been checked.
- **Implementation status:** M0 is partial and M1 has a compiling prototype. `PixelSense.xcodeproj` targets iOS 17+, browses permitted still photos, previews exposure from -2 to +2 EV, and submits a PhotoKit edit with versioned `PHAdjustmentData` to the same `PHAsset`. No physical-device save-back has been verified. Tejas will provide his device/iOS version. No extra course requirements are known yet.
- **Verification:** generic iOS Simulator and generic iPhone builds passed with code signing disabled. A simulator launch could not be performed because the local CoreSimulator service was unavailable to this tool session. No physical iPhone was connected or tested.
- **Next action:** Tejas opens the Xcode project, selects his Personal Team, and tests the full flow on a standard still photo on his iPhone. Record whether the save updates one gallery item, whether repeat edits reopen the saved value, and whether Photos can revert. Then fix any device findings before M1 is marked done. Tejas and Yug still need to agree on ownership of later milestones.
- **Open decisions:** see “Main risks and decisions still open” in `docs/PROJECT_PLAN.md`.

## Working agreement

The two students are the only intended GitHub collaborators. An assisting agent must not invite itself, a bot, or a service account. In this session, GitHub SSH authenticated as Tejas's existing `Tejasvid29` account, and Git commits used that account's already-configured identity. No agent account was added. The repository's collaborator settings have not been independently inspected; the students should verify those settings if they need an account-level audit.

Keep this document factual. A completed acceptance check needs a reproducible result, especially for Photos save-back on a real iPhone. Record simulator-only work as simulator-only. Never attach private photos, device identifiers, or secrets.

## Work log

### 2026-10-12 — Repository import and initial review

- **Who / branch:** Codex assisting Tejas / `main`.
- **Work:** cloned `https://github.com/Yug-More/PixelSense` into the local PixelSense workspace and read the complete initial README. At import, `README.md` was the only tracked file.
- **Result:** identified the original goal of prompt-driven, region-aware photo enhancement and the absence of implementation/setup details.
- **Verification:** checked repository status, remote, tracked files, and README content. No application tests existed.

### 2026-10-12 — Scope clarification and README update

- **Who / branch / commit:** Codex assisting Tejas / `main` / `e6fd8af` (pushed).
- **Work:** rewrote `README.md` to focus on reversible exposure and color/tone settings, manual refinement, and preservation of scene content and geometry. Removed language that could imply generation or object editing.
- **Decision:** region detection may choose where adjustment settings apply, but never changes an object or scene itself.
- **Verification:** reviewed the README diff and ran `git diff --check`. The working tree was clean after push.

### 2026-10-12 — iPhone deployment decision

- **Who / branch:** Codex assisting Tejas / planning only.
- **Work:** checked Apple PhotoKit, Core Image, editing extension, and developer-account documentation. No files changed during this discussion.
- **Decision:** target the same visible Photos asset through PhotoKit and use a native iOS app. Use Xcode's free personal-device testing for the class prototype. An extension inside Photos is optional later work.
- **Constraint:** PhotoKit requires an edited rendering plus adjustment data to commit a content edit; Photos controls its internal versions. A literal overwrite of the original file is unavailable.
- **References:** [PhotoKit editing](https://developer.apple.com/documentation/photokit/editing-asset-content), [Core Image adjustments](https://developer.apple.com/documentation/coreimage/color-adjustment-filters), [free device testing](https://developer.apple.com/help/account/basics/about-your-developer-account).

### 2026-10-12 — Planning and agent handoff documents

- **Who / branch / commit:** Codex assisting Tejas / `main` / `6906e3b` (pushed).
- **Work:** updated `README.md` for the same-item Photos save flow; created `docs/PROJECT_PLAN.md` with architecture, milestones M0–M6, acceptance checks, coordination, and risks; created `AGENTS.md` with documentation, verification, Git, and account rules; created this handoff.
- **Reason:** ensure both students and their agents can resume from one written state and avoid conflicting interpretations of “no duplicate.”
- **Verification:** reviewed the documentation diff and ran `git diff --check`; both passed. No app or device test is possible yet because the iOS project has not been created.
- **Next action:** start M0 with the two students' device and course constraints.

### 2026-10-12 — First iPhone Photos editing prototype

- **Who / branch / commit:** Codex assisting Tejas / `feature/ios-photo-editing-proof` / commit containing this entry.
- **Work and files:** added `PixelSense.xcodeproj` and the `PixelSense/` SwiftUI app; added `.gitignore`; updated `README.md` with current behavior and free-device setup; updated `docs/PROJECT_PLAN.md` with the initial iOS 17/still-photo/exposure choices. `PhotoLibraryStore` handles read/write or limited Photos authorization and browses still assets. `PhotoEditorModel` loads a content editing input, renders an exposure preview with Core Image, stores a versioned recipe, and asks PhotoKit to update the selected asset. `ContentView` provides the gallery, before/edit comparison, slider, and save action.
- **Decisions and sources:** use `PHContentEditingOutput.renderedContentURL(for: .jpeg)` for the first still-photo proof; this API is available on iOS 17+. Use `PHAdjustmentData` for the exposure recipe and no asset-creation request in the save path. Apple references: [content editing](https://developer.apple.com/documentation/photokit/editing-asset-content), [editing output](https://developer.apple.com/documentation/photos/phcontenteditingoutput), [color filters](https://developer.apple.com/documentation/coreimage/color-adjustment-filters).
- **Attempts and fixes:** the first build rejected a nonexistent `CIImageRepresentationOption.lossyCompressionQuality` member; removed that option and rebuilt successfully. Added required bundle keys to `Info.plist` after inspecting the built app metadata. The simulator service could not be used for a launch test in this tool session.
- **Verification and result:** `plutil` accepted the project and Info.plist. Generic simulator build passed. Generic iPhone build passed with signing disabled. The built Info.plist contains the bundle identifier, version, iOS 17 minimum, and Photos usage description. No physical iPhone run, save-back, iCloud, metadata, orientation, or repeat-edit test has passed yet.
- **Blockers or risks:** device/iOS version and free Personal Team signing are pending Tejas's input. JPEG rendering may change format or color characteristics; save behavior and Photos revert remain unverified on hardware. Live Photos are excluded, and prompts and region edits are not implemented yet.
- **Exact next action and owner:** Tejas tests the flow on his iPhone using a still photo set aside for testing, records the observed Photos behavior, and sends any errors or screenshots. Codex then fixes device findings and continues M1/M2. Yug and Tejas assign ownership of later workstreams.

## Template for the next entry

### YYYY-MM-DD — Short task name

- **Who / branch / commit:**
- **Work and files:**
- **Decisions and sources:**
- **Verification and result:**
- **Blockers or risks:**
- **Exact next action and owner:**
