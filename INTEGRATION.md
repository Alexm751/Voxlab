# INTEGRATION.md — registro Voxlab

## Come riprendere
- **Stato:** Fase 2 in corso su `wave/stt-robustness` — 9 PR Handy mergeate (#2144 + mergeable).
- **Prossimo passo:** CI verde sulla PR interna → merge su `main`; conflicting (#1875/#1713/#1501/#1503/#1028) restano deferred.
- **Artefatto testabile (Fase 1):** `artifacts/fase1-36885527321/handy_0.9.7_x86_64.flatpak`. ID ancora `com.pais.handy`.
- **Workspace:** `C:\Users\Alessandro\OneDrive\Sviluppo\VoiceLab`
- **Repo locale:** `VoiceLab\Voxlab` → https://github.com/Alexm751/Voxlab
- **Upstream (sola lettura):** https://github.com/cjpais/Handy
- **CI:** `.github/workflows/ci-build.yml` — `workflow_dispatch` + PR verso `main`; artefatto `voxlab-flatpak-x86_64`.
- **Download artefatto:** `gh run download <run-id> -R Alexm751/Voxlab -D artifacts`

## Decisioni
| Voce | Scelta |
|------|--------|
| Nome | Voxlab |
| Flatpak ID | io.github.alexm751.Voxlab (rinomina in Fase 5; ora packaging ancora `com.pais.handy`) |
| Formato CI | Solo Flatpak x86_64 (Linux) |
| Target test | Ubuntu 26.04 GNOME 50 Wayland |
| PR verso Handy | No |
| Packaging Flatpak CI | Manifest/script da Handy #548 + script SDK build da #1560 (SPIRV/transcribe); senza merge del resto delle PR |
| Ayatana su x86_64 | `PKG_CONFIG_PATH` + `ldflags -L/app/lib64` + `LIBRARY_PATH`/`LD_LIBRARY_PATH` (lib64) |
| Wayland/Flatpak input | **split** #548→#1287→#689 (non #1560) |
| Audio Fase 2 (#1644 vs #2144) | **#2144** (default input config); **#1644** (cpal 0.17 / macOS 26) rimandata a post-collaudo Linux / effort macOS |

## Checklist setup
- [x] Clone Handy → `Voxlab/`
- [x] Repo GitHub `Alexm751/Voxlab` (pubblico)
- [x] `upstream` fetch-only, `origin` = Alexm751
- [x] Branch `upstream-mirror`
- [x] `.cursorignore` / `.gitignore` in VoiceLab
- [x] Chiavi `.ssh` spostate fuori workspace → `OneDrive\Sviluppo\_secrets\VoiceLab-ssh`
- [x] RTK init (`-g --agent cursor`)
- [x] GitNexus `setup -c cursor`
- [x] GitNexus `analyze` su Voxlab
- [x] Graphify skill/rule installata in `Voxlab/.cursor/rules/`
- [x] Graphify grafo (`graphify-out/`)
- [x] CI Flatpak (PR [#12](https://github.com/Alexm751/Voxlab/pull/12) mergiata)
- [x] Merge PR Linux (Fase 1 — PR [#13](https://github.com/Alexm751/Voxlab/pull/13) `wave/linux-gnome`)

## Checklist CI (Fase 0b)
- [x] Workflow upstream multi-piattaforma → solo `workflow_dispatch` (disabilitati via `gh workflow disable`)
- [x] `ci-build.yml` Flatpak + `cargo check`
- [x] Manifest `src-tauri/flatpak/` + `scripts/build-flatpak.sh` + submodule `shared-modules`
- [x] Prima build di prova verde (artefatto `voxlab-flatpak-x86_64`, run 36865258709)

## PR da integrare (Fase 1)
| PR | Titolo | Stato |
|----|--------|-------|
| #1909 | overlay Wayland | merged on wave |
| #1388 | dotool / HandyKeys | merged on wave |
| #1505 | overlay GNOME XWayland | merged on wave (conflitti risolti) |
| #548 | Flatpak packaging | merged on wave (packaging CI già collaudato; + portal autostart/tray) |
| #1287 | portal GlobalShortcuts | merged on wave |
| #689 | RemoteDesktop | merged on wave |
| #2109 | X11 Shift+Insert | merged on wave |
| #1722 | X11 Enigo keymap | merged on wave |
| #1568 (parziale) | fallback typing tools | deferred (conflitti; meno rilevante in Flatpak) |
| #1300 | keyboard None | deferred (Plan B; conflitti i18n) |
| minori | #2148 #2131 #2102 #2025 | tentati / vedi log |
| #1774 | PipeWire | fog — solo se mic problematico |

## PR da integrare (Fase 2)
| PR | Titolo | Stato |
|----|--------|-------|
| #2144 | default input config | merged on wave |
| #2110 | don't abort startup if always-on mic fails | merged on wave |
| #2155 | time out hung post-processing | merged on wave |
| #2159 | autostart off startup thread | merged on wave (lib.rs → reconcile_autostart) |
| #2108 | settings listeners once | merged on wave |
| #2150 | warn digital silence | merged on wave |
| #2097 | tap vs hold by key event time | merged on wave |
| #2130 | numpad keys in shortcuts | merged on wave |
| #2168 | mute immediately option | merged on wave |
| #1644 | cpal 0.17 / macOS 26 | deferred (decisione #6) |
| #1875 | follow changed default mic | deferred (conflict managers/audio.rs) |
| #1713 | transcription hang + audio_feedback | deferred (conflict recorder.rs vs #2144) |
| #1501 | mute-while-recording strand | deferred (conflicts) |
| #1503 / #1028 | volume/pause while recording | deferred (conflicts + scope) |

## Note
- GitNexus e Graphify vanno rieseguiti dopo merge sostanziosi.
- Artefatti CI in `VoiceLab\artifacts\`.
- Research Fase 1: vedi [issue #3](https://github.com/Alexm751/Voxlab/issues/3) / `research/fase1-pr-status.md` su branch `research/fase1-pr-status`.