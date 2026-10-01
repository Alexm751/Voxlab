# INTEGRATION.md — registro Voxlab

## Come riprendere
- **Stato:** Fase 1 **chiusa** — PR [#13](https://github.com/Alexm751/Voxlab/pull/13) mergiata su `main` (`79f4ee9`); CI Flatpak verde (run 36885527321).
- **Prossimo passo:** ticket [#6](https://github.com/Alexm751/Voxlab/issues/6) (audio #1644 vs #2144) → Fase 2; deferred Handy #1568 / #1300 / #2025 solo se serve.
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

## Note
- GitNexus e Graphify vanno rieseguiti dopo merge sostanziosi.
- Artefatti CI in `VoiceLab\artifacts\`.
- Research Fase 1: vedi [issue #3](https://github.com/Alexm751/Voxlab/issues/3) / `research/fase1-pr-status.md` su branch `research/fase1-pr-status`.