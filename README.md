# ReaTimeline Notes

**Experimental REAPER extension — v0.1.0-dev.1**

ReaTimeline Notes is a timeline-oriented fork of [ReaNotepad](https://github.com/patch-34/reanotepad) by Aleksei Vorobev / Patch34. It aims to connect REAPER marker ruler lanes to editable groups and provide marker↔note conversion, while retaining project, track, and media-item notes.

**Development status:** G1 has been verified in REAPER 7.83 on macOS Intel and is available on `main`. G2.1 (v0.2.0-dev.2) is accepted in REAPER 7.83/OSX64, including focused-window Undo/Redo. G2.2 experimental v0.2.0-dev.3 is in branch `dev/g2-lane-controls`; native lane insert/color/order operations need REAPER validation.

## Installation (development build)

1. Download [ReaTimeline_Notes.lua](ReaTimeline_Notes.lua).
2. In REAPER open **Actions → Show action list → New action → Load ReaScript**.
3. Select the Lua file and run it.

Requires **REAPER 7.83+** for the tested marker lane API and **ReaImGui 0.10+**. SWS is not required.

## Currently implemented

- Automatically enumerate REAPER's existing markers and ruler lanes.
- Display marker groups ordered by lane and markers ordered by position.
- Detect marker position, lane and name changes while REAPER is open.
- Display time rounded to milliseconds without modifying native positions.
- Preserve the existing ReaNotepad note-editing features, including Project / Track / Item owner modes, until the unified notes view is implemented.
- Use separate interface preferences, window identifier and recovery location.

## Planned

- G2: Two-way synchronization between REAPER ruler lanes and marker groups. The experimental branch includes GUID-safe marker movement via drag/drop or the context menu, native lane renaming and Undo.
- G3: Unified Project / Track / Item notes list, retaining the native owners.
- G4: Marker ↔ note conversions and bulk marker-to-note import.
- G5: Unified UI controls and user-selectable time display.
- G6: Regression testing, hardening and release.

See [the Russian roadmap](REATIMELINE_ROADMAP_RU.md) for acceptance criteria.

## Compatibility and precautions

This is a separate application and repository. The original ReaNotepad source code and GitHub `main` branch are not modified by this fork.

**Important:** G2 changes actual REAPER markers and ruler lane names. Test on a disposable project copy. The development version intentionally reuses native REAPER note storage for compatibility with ReaNotepad. Do not edit the same note owner concurrently from both scripts. Marker display is read-only and cannot modify markers or their lanes.

## License

MIT. See [LICENSE](LICENSE). Fork source: [ReaNotepad](https://github.com/patch-34/reanotepad).

## G2 testing (experimental branch)

Download [the G2 Lua file](https://github.com/patch-34/reatimeline-notes/blob/dev/g2-lane-sync/ReaTimeline_Notes.lua) and open a **copy** of a REAPER project with at least two marker ruler lanes.

1. Verify that external marker moves, name changes and lane renames appear automatically.
2. Drag one marker onto the header of another lane's group in the ReaTimeline Notes window. Check the marker's actual lane in REAPER.
3. Right-click a marker and choose a target lane. Check the same result.
4. Right-click a lane heading in the script, change its name and save. Check the corresponding ruler lane name in REAPER.
5. With the **ReaTimeline Notes window focused**, press **Cmd+Z** (Ctrl+Z on Windows/Linux) after a marker move. **Cmd+Shift+Z** should redo it. The marker panel must be the active context; click on a marker/group first if you have been editing notes.
6. Use the explicit **REAPER Undo** and **REAPER Redo** buttons in the marker panel (or the Edit menu). These act on the **entire REAPER project history**, not just marker edits.
7. After editing a note, verify that Cmd+Z operates on the note editor's independent history. Click a marker row to return keyboard Undo/Redo to project history. Active text input retains its own Undo.
8. With the REAPER arrange window focused, verify that native Undo/Redo still works as before.
9. Verify that the marker GUID, number, name and full-precision position remain unchanged after moving lanes.

This is a partial G2 milestone. Lane color editing, lane creation/deletion and tighter unified-note integration are not implemented in this experimental build.

## G2.2 lane controls (experimental)

Use the [G2.2 development Lua](https://github.com/patch-34/reatimeline-notes/blob/dev/g2-lane-controls/ReaTimeline_Notes.lua) in **a disposable copy of the project**.

1. Click **+ Lane** in the marker panel. A new ruler lane should be created in REAPER (not just in the script).
2. Right-click an existing ruler lane group → **Lane color** → choose Red/Green/etc. Check the same color in REAPER's Ruler Lane Manager. Check **Default** to clear the lane default color.
3. Right-click a group → **Move lane up/down**. Check that the line order changes in REAPER and that marker GUIDs and exact positions remain unchanged.
4. Rename or reorder a lane directly in REAPER. The group should follow its real lane GUID.
5. Undo/Redo each operation with ReaTimeline Notes focused; check marker and lane consistency after every action.

**Deletion is deliberately not available in G2.2.** REAPER can delete markers/regions alongside a lane depending on the deletion mode; deletion and migration rules require a separately tested G2.3 workflow.

This is not a release build. Do not merge it into `main` until native tests pass.
