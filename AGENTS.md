# PixelSense agent guidelines

These instructions apply to all work in this repository. Read `README.md`, `docs/PROJECT_PLAN.md`, and `docs/HANDOFF.md` before changing files. Follow the user's current instructions when they supersede this document.

## Project boundaries

- Build a native iPhone photo editor that changes color and tone settings on an existing Photos library item. Do not create or replace scene content, move objects, change geometry, or add a second visible photo as the default save behavior.
- Treat “same photo” as the same visible Photos asset. PhotoKit manages the original and edited rendering internally; never claim a literal in-place overwrite or zero additional storage.
- Keep the first usable version local to the iPhone. Do not require a paid Apple Developer Program membership, cloud account, server, or image upload for the class demo.
- Preserve reversibility by keeping the adjustment recipe separate from the rendered result. Do not destroy the original or silently discard earlier edits.
- Do not add an AI agent, bot, or service account as a GitHub collaborator. Only the two student maintainers should have collaborator access. Use the maintainer's existing Git credentials; do not change `user.name`, `user.email`, remotes, or account access without a direct request. Record agent contributions in the handoff rather than adding an agent co-author trailer.

## Before and during work

1. Read the three documents named above and inspect the current branch, working tree, and recent commits. Preserve changes already in progress.
2. Choose a small task from the plan or the user's request. Note its owner and status in `docs/HANDOFF.md` so another agent can avoid overlapping edits. If simultaneous work is likely, use separate branches and coordinate file ownership with the students.
3. Keep implementation focused on the current milestone. Prefer Apple-supported APIs and cite their official documentation when recording a platform decision.
4. Document decisions, assumptions, notable attempts, failures, and fixes as work happens. Never record secrets, private photo contents, tokens, or personal device identifiers.
5. Test the behavior affected by the change. State what ran, the result, and what could not be tested. A simulator-only result does not establish that Photos save-back works on a physical iPhone.

## Handoff required for every work session

Before finishing any session, update `docs/HANDOFF.md` with:

- Date, responsible student or agent session, branch, and commit or uncommitted state.
- What changed, with file paths and a short reason.
- Decisions and assumptions, including links to any official platform source used.
- Verification performed and its result; list tests that still need a real device.
- Current blockers or risks, the exact next action, and who owns it.

Keep the “Current state” section accurate and append a dated entry to the work log. Update `docs/PROJECT_PLAN.md` when a milestone, requirement, or acceptance criterion changes. Update `README.md` when the user-facing behavior or setup changes. Documentation changes belong in the same commit as the work they describe when practical.

## Git and review

- Never force-push or rewrite shared history. Pull or fetch before pushing and resolve conflicts deliberately.
- Use descriptive commits. Review the diff and run `git diff --check` before committing.
- Do not commit credentials, provisioning profiles, personal photos, or generated build artifacts.
- Do not claim a task is complete until its acceptance checks pass or the handoff explicitly records the remaining gap.
