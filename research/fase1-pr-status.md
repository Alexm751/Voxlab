# Research: Handy Fase 1 PR status (rebase / conflicts)

**Ticket:** [Alexm751/Voxlab#3](https://github.com/Alexm751/Voxlab/issues/3)  
**Branch:** `research/fase1-pr-status`  
**Snapshot:** 2026-10-01 (Europe/Rome)  
**Base tip checked:** `29bd2c0d6b4b705df5fd6d2f387e5db5ecc27480`  
**Remotes at snapshot:** `origin/main` (Alexm751/Voxlab) == `upstream/main` (cjpais/Handy) == local `HEAD`

Because Voxlab `main` currently tracks the same commit as Handy `main`, **conflict status vs upstream main and vs our main is identical** for this snapshot.

## Method / sources

| Source | Use |
|--------|-----|
| `gh pr view <n> --repo cjpais/Handy --json …` | state, mergeable, mergeStateStatus, size, base, URLs |
| `gh api repos/cjpais/Handy/pulls/<n>` | mergeable_state cross-check |
| `git fetch upstream pull/<n>/head` + `git merge-tree --write-tree --name-only HEAD refs/tmp/pr-<n>` | conflict file paths vs current main |
| PR #1560 body / commits | confirms it is a **combined** build of Flatpak + GlobalShortcuts + RemoteDesktop |

Primary PR URLs: `https://github.com/cjpais/Handy/pull/<n>`.

### mergeStateStatus legend (GitHub)

- **CLEAN** — mergeable, checks green enough for GitHub’s merge button heuristics  
- **UNSTABLE** — mergeable, but some checks failing  
- **DIRTY** — conflicting / not auto-mergeable  

---

## Summary table (Fase 1 scope)

| PR | Title (short) | State | mergeable | mergeStateStatus | Size (Δ / files) | Base | Conflicts vs main (local merge-tree) | Risk notes |
|----|---------------|-------|-----------|------------------|------------------|------|--------------------------------------|------------|
| [#1909](https://github.com/cjpais/Handy/pull/1909) | overlay Wayland stale pixels | **OPEN** | MERGEABLE | CLEAN | +1009/−121 / 7 | main | none | Low. Touches `overlay.rs`, `actions.rs`, `lib.rs`, bindings, overlay UI. |
| [#1388](https://github.com/cjpais/Handy/pull/1388) | dotool latency + HandyKeys fd leak | **OPEN** | MERGEABLE | CLEAN | +243/−49 / 4 | main | none | Low. `clipboard.rs`, `shortcut/*`, README. |
| [#1505](https://github.com/cjpais/Handy/pull/1505) | GNOME Wayland overlay | **OPEN** | CONFLICTING | DIRTY | +290/−3 / 5 | main | `Cargo.toml`, `overlay.rs` | Medium. Overlaps overlay work with #1909; Cargo.toml churn. |
| [#1560](https://github.com/cjpais/Handy/pull/1560) | Linux Wayland + Flatpak mega-PR | **OPEN** | CONFLICTING | DIRTY | +4368/−150 / **60** | main | **31 files** (see below) | **High.** Stale (~Jul 2026 update); combines #548+#1287+#689 lineages. |
| [#689](https://github.com/cjpais/Handy/pull/689) | Remote Desktop direct mode (Wayland) | **OPEN** | CONFLICTING | DIRTY | +2625/−65 / 42 | main | **30 files** (hot: Cargo.*, clipboard, lib, settings, shortcut/mod, bindings, i18n×N, settingsStore) | High. Core Wayland input; same hot files as #1560’s hard half. Updated more recently (2026-09-17). |
| [#1287](https://github.com/cjpais/Handy/pull/1287) | portal GlobalShortcuts | **OPEN** | CONFLICTING | DIRTY | +496/−1 / 6 | main | `Cargo.toml`, `shortcut/mod.rs` | Medium-low conflict surface; functionally critical for Flatpak GNOME. |
| [#548](https://github.com/cjpais/Handy/pull/548) | Flatpak packaging | **OPEN** | CONFLICTING | DIRTY | +949/−76 / 38 | main | 9 files (`autostart`, `clipboard`, `lib`, `shortcut/mod`, `tray`, 3 i18n, overlay CSS) | Medium. Needed early for CI Flatpak (PLAN Fase 0b/1). |
| [#1568](https://github.com/cjpais/Handy/pull/1568) | GNOME shortcuts/paste (Ubuntu 26) | **OPEN** | CONFLICTING | DIRTY | +162/−51 / 7 | main | `BUILD.md`, `README.md`, `clipboard.rs`, `utils.rs`, `tauri.conf.json` | Partial for Fase 1: tool-fallback paste less relevant inside Flatpak (no `/dev/uinput`). |
| [#1300](https://github.com/cjpais/Handy/pull/1300) | keyboard implementation “None” | **OPEN** | CONFLICTING | DIRTY | +152/−29 / 25 | main | `shortcut/mod.rs`, `bindings.ts`, `GeneralSettings.tsx`, many i18n | Plan B if GlobalShortcuts fails; i18n-heavy conflicts. |
| [#2109](https://github.com/cjpais/Handy/pull/2109) | X11 Shift+Insert paste | **OPEN** | MERGEABLE | UNSTABLE | +98/−2 / 2 | main | none | Low rebase risk; CI unstable. X11-focused minor. |
| [#1722](https://github.com/cjpais/Handy/pull/1722) | X11 stale enigo keymap | **OPEN** | CONFLICTING | DIRTY | +45/−8 / 2 | main | `clipboard.rs` | Small but conflicts on hot `clipboard.rs`. |
| [#2148](https://github.com/cjpais/Handy/pull/2148) | audio feedback lock bound | **OPEN** | MERGEABLE | UNSTABLE | +20/−2 / 1 | main | none | Low. |
| [#2131](https://github.com/cjpais/Handy/pull/2131) | baseline ONNX Runtime Linux | **OPEN** | MERGEABLE | UNSTABLE | +162/−3 / 2 | main | none | Low rebase; build/runtime concern. |
| [#2102](https://github.com/cjpais/Handy/pull/2102) | CBLAS shim for transcribe-cpp | **OPEN** | MERGEABLE | UNSTABLE | +150/−0 / 1 | main | none | Low. |
| [#2025](https://github.com/cjpais/Handy/pull/2025) | docs Ubuntu GNOME ydotool | **OPEN** | CONFLICTING | DIRTY | +28/−8 / 1 | main | `README.md` | Docs-only; low product risk, README conflict. |
| [#1774](https://github.com/cjpais/Handy/pull/1774) *(optional)* | PipeWire capture backend | **OPEN** | CONFLICTING | DIRTY | +1797/−72 / 46 | main | `Cargo.toml` (+ large i18n/settings surface in PR files) | Informative only for mic strategy; **not** required to decide #1560 vs split. Large. |

**None of the scoped PRs are merged or closed** as of this snapshot; all remain **OPEN**.

### #1560 conflict files (local merge-tree vs `29bd2c0`)

`Cargo.lock`, `Cargo.toml`, `autostart.rs`, `clipboard.rs`, `lib.rs`, `settings.rs`, `shortcut/mod.rs`, `bindings.ts`, `AccessibilityOnboarding.tsx`, `Dropdown.tsx`, 19× `translation.json`, `settingsStore.ts` → **31 paths**.

Overlaps almost 1:1 with #689’s conflict set; #548 and #1287 add smaller disjoint slices (`tray`, overlay CSS, portal shortcut wiring).

---

## #1560 vs split (#689 + #1287 + #548)

### What #1560 is

Per its own description ([PR body](https://github.com/cjpais/Handy/pull/1560)): it is a **central test build** that **combines previously separate PRs** for a Wayland-native Flatpak Handy — explicitly GlobalShortcuts portal, Remote Desktop input pipeline, and Flatpak theming/packaging. Commit history includes “Merge PR #548…” and portal/GlobalShortcuts commits. It is not an independent fourth design; it is the **bundled** form of the split.

| Metric | #1560 | Split sum (#689+#1287+#548) |
|--------|-------|------------------------------|
| Additions | 4368 | 2625+496+949 = **4070** |
| Files | 60 | 42+6+38 (overlapping paths → less unique than sum) |
| Commits | 15 | 6+1+19 |
| GitHub mergeable | CONFLICTING | all three CONFLICTING |
| Local conflict paths | 31 | 30 + 2 + 9 (overlapping hot files) |
| Last updated (GitHub) | 2026-07-30 | #689 **2026-09-17**; others 2026-07-30 |

### Factual recommendation (not a product decision)

**Prefer integrating the split (#548 → #1287 → #689) over rebasing #1560 as a single unit**, given current tip `29bd2c0`:

1. **#1560’s conflict surface is essentially #689’s**, plus Flatpak/autostart pieces — there is no evidence that the mega-PR rebases *easier* than its parts; it concentrates the same hot files (`settings.rs`, `bindings.ts`, `clipboard.rs`, `shortcut/mod.rs`, i18n) into one resolution session.
2. **#1287 alone** only conflicts on `Cargo.toml` and `shortcut/mod.rs` — cheap to land after (or with) packaging.
3. **#548** has a moderate 9-file conflict set and is the packaging spine PLAN already wants early.
4. **#689** remains the expensive rebase either way; doing it *after* Flatpak+GlobalShortcuts on our fork lets conflicts be resolved against a known intermediate tree instead of a stale 15-commit bundle last touched 2026-07-30.
5. #1560 remains useful as a **reference/test-build map** (which patches belong together), not as the preferred apply vehicle.

If a single cherry-pick experiment on #1560 finishes cleanly in practice, that would overturn (1); at API/`merge-tree` level it does **not** look more rebaseable than the split.

---

## Suggested apply order (informational)

Aligned with PLAN.md / INTEGRATION.md, not a binding decision:

1. Easy CLEAN minors useful on Linux: #1909, #1388 (then #2148/#2131/#2102 as needed).  
2. #1505 (2-file conflict) carefully vs #1909 overlay overlap.  
3. Split: **#548** → **#1287** → **#689**.  
4. #1568 only for residual paste/docs bits still valuable post-Flatpak.  
5. #1300 as plan B.  
6. X11 minors #2109/#1722 when X11 collaudo is in scope.  
7. Keep #1774 deferred (map issue “Not yet specified”).

---

## Citations (commands / APIs used)

```text
gh pr view <n> --repo cjpais/Handy --json number,title,state,mergeable,mergeStateStatus,baseRefName,additions,deletions,changedFiles,url,updatedAt
gh api repos/cjpais/Handy/pulls/<n>
git fetch upstream main
git fetch upstream pull/<n>/head:refs/tmp/pr-<n>
git merge-tree --write-tree --name-only --no-messages HEAD refs/tmp/pr-<n>
# tip: 29bd2c0d6b4b705df5fd6d2f387e5db5ecc27480 (origin/main == upstream/main)
```

Issue under resolution: https://github.com/Alexm751/Voxlab/issues/3  
Parent map: https://github.com/Alexm751/Voxlab/issues/1  
Upstream Handy: https://github.com/cjpais/Handy  
