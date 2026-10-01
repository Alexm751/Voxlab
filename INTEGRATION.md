# INTEGRATION.md — registro Voxlab

## Come riprendere
- **Stato:** Fase 0b **chiusa** — CI Flatpak-only su `main` (PR [#12](https://github.com/Alexm751/Voxlab/pull/12), run verde [36865258709](https://github.com/Alexm751/Voxlab/actions/runs/36865258709)).
- **Prossimo passo:** frontier Wayfinder — [Decidere: #1560 vs split](https://github.com/Alexm751/Voxlab/issues/4) poi [Fase 1: ondata Linux GNOME](https://github.com/Alexm751/Voxlab/issues/5). Research #3 già chiusa (preferire split #548→#1287→#689).
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
- [ ] Merge PR Linux (Fase 1+)

## Checklist CI (Fase 0b)
- [x] Workflow upstream multi-piattaforma → solo `workflow_dispatch` (disabilitati via `gh workflow disable`)
- [x] `ci-build.yml` Flatpak + `cargo check`
- [x] Manifest `src-tauri/flatpak/` + `scripts/build-flatpak.sh` + submodule `shared-modules`
- [x] Prima build di prova verde (artefatto `voxlab-flatpak-x86_64`, run 36865258709)

## PR da integrare (Fase 1)
| PR | Titolo | Stato |
|----|--------|-------|
| #1909 | overlay Wayland | pending |
| #1388 | dotool / HandyKeys | pending |
| #1505 | overlay GNOME XWayland | pending |
| #1560 / #689+#1287+#548 | Wayland+Flatpak | pending (packaging #548 parziale già in CI; research: preferire split) |
| #1568 (parziale) | fallback typing tools | pending |
| #1300 | keyboard None | pending |
| minori | #2109 #1722 #2148 #2131 #2102 #2025 | pending |

## Note
- GitNexus e Graphify vanno rieseguiti dopo merge sostanziosi.
- Artefatti CI in `VoiceLab\artifacts\`.
- Research Fase 1: vedi [issue #3](https://github.com/Alexm751/Voxlab/issues/3) / `research/fase1-pr-status.md` su branch `research/fase1-pr-status`.
