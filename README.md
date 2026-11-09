# ReaTimeline Notes

**Experimental REAPER extension — v0.1.0-dev.1**

ReaTimeline Notes is a timeline-oriented fork of [ReaNotepad](https://github.com/patch-34/reanotepad) by Aleksei Vorobev / Patch34. It aims to connect REAPER marker ruler lanes to editable groups and provide marker↔note conversion, while retaining project, track, and media-item notes.

**Development status:** The first G1 prototype has been tested in REAPER 7.83 on macOS Intel. Markers appear automatically, grouped by their native ruler lanes. The marker browser is read-only at this stage.

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

- G2: Two-way synchronization between REAPER ruler lanes and marker groups.
- G3: Unified Project / Track / Item notes list, retaining the native owners.
- G4: Marker ↔ note conversions and bulk marker-to-note import.
- G5: Unified UI controls and user-selectable time display.
- G6: Regression testing, hardening and release.

See [the Russian roadmap](REATIMELINE_ROADMAP_RU.md) for acceptance criteria.

## Compatibility and precautions

This is a separate application and repository. The original ReaNotepad source code and GitHub `main` branch are not modified by this fork.

**Important:** The current development version intentionally reuses native REAPER note storage for compatibility with ReaNotepad. Do not edit the same note owner concurrently from both scripts. Marker display is read-only and cannot modify markers or their lanes.

## License

MIT. See [LICENSE](LICENSE). Fork source: [ReaNotepad](https://github.com/patch-34/reanotepad).
