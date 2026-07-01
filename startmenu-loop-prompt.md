Continue the Windows 11 start menu port. Phase 1 only.

## What to do this turn

1. Read `startmenu-progress.md` and `docs/STARTMENU_PLAN.md`.
2. Find the next unfinished (`[ ]`) TODO under "Active TODO — Phase 1".
   Take at most 5 TODOs this turn. Skip Phase 2 backlog entirely.
3. For each TODO: read the matching reference file under
   `/home/jeysef/Coding/kde/Windows_modern/plasmoids/startmenu/com.jeysef.windowsmodernstartmenu/contents/`
   (use offset for the large `ui/MenuRepresentation.qml`), then implement the
   ported file under `plasma/applets/org.kde.windowsmodern.startmenu/`.
4. Mark each finished TODO `[x]` in `startmenu-progress.md`. Add follow-up TODOs
   if you discover missing work.
5. After writing each file, sanity-check it:
   - `python3 -m json.tool metadata.json` (if touched)
   - balanced QML braces / matched Component blocks
   - every locally-referenced QML/JS file exists
   - run `qmllint6 <file>` if installed; treat `org.kde.plasma.private.kicker`
     import warnings as non-fatal, but FIX real syntax/type errors.

## Hard rules

- Follow conventions in `docs/STARTMENU_PLAN.md` exactly: KPlugin.Id
  `org.kde.windowsmodern.startmenu`, License `GPL-3.0-or-later`, Author
  `Jeysef`, modern Qt6 imports (no version numbers except
  `org.kde.plasma.private.kicker 0.1` and `org.kde.kitemmodels 1.0`).
- Do NOT copy `MenuRepresentation.qml` wholesale. The shell keeps only
  positioning/search-host/SwipeView/footer/reset/search-state; pages go in
  `pages/`, shared bits in `components/`.
- Phase 1 scope ONLY. Do NOT add: weather card, update checker, shell runner,
  quick actions bar, pinned/all-apps folders, launch tracking, command
  palette, smart-context labels. Those are Phase 2.
- Do NOT git commit, git reset, git clean, git push, rm -rf, or run any
  destructive command. Only the user commits.
- Do NOT touch `progress.md` — that belongs to a different (Quick Settings)
  loop. Your state file is `startmenu-progress.md` only.
- Do NOT ask questions. Make reasonable assumptions and note them as TODOs.
- Keep replies short.

## Stop condition

When every Phase 1 TODO under "Active TODO — Phase 1" is `[x]`:
- finish P1.15 (verify + docs),
- replace `STARTMENU_TIER1_PENDING` with `STARTMENU_TIER1_DONE` on its own
  line at the very end of `startmenu-progress.md`,
- then stop. Do not begin Phase 2.

If you are blocked on something real (not just a decision), add it under
"Blocked" in `startmenu-progress.md` and stop.
