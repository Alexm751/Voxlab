# INTEGRATION.md — registro Voxlab

## Come riprendere
- **Stato:** Fase 0b in corso su branch `wave/ci-flatpak` — packaging Flatpak da Handy #548/#1560 + `ci-build.yml`; workflow upstream in sola `workflow_dispatch`.
- **Prossimo passo:** merge PR CI → verificare run Flatpak verde; poi chiudere Wayfinder [Fase 0b](https://github.com/Alexm751/Voxlab/issues/2) e avanzare frontier (research #3 / decisione #1560 / Fase 1).
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
- [ ] CI Flatpak (PR `wave/ci-flatpak`)
- [ ] Merge PR Linux

## Checklist CI (Fase 0b)
- [x] Workflow upstream multi-piattaforma → solo `workflow_dispatch`
- [x] `ci-build.yml` Flatpak + `cargo check`
- [x] Manifest `src-tauri/flatpak/` + `scripts/build-flatpak.sh` + submodule `shared-modules`
- [ ] Prima build di prova verde (artefatto scaricabile)

## PR da integrare (Fase 1)
| PR | Titolo | Stato |
|----|--------|-------|
| #1909 | overlay Wayland | pending |
| #1388 | dotool / HandyKeys | pending |
| #1505 | overlay GNOME XWayland | pending |
| #1560 / #689+#1287+#548 | Wayland+Flatpak | pending (packaging #548 parziale già in CI) |
| #1568 (parziale) | fallback typing tools | pending |
| #1300 | keyboard None | pending |
| minori | #2109 #1722 #2148 #2131 #2102 #2025 | pending |

## Note
- GitNexus e Graphify vanno rieseguiti dopo merge sostanziosi.
- Artefatti CI in `VoiceLab\artifacts\`.
- Research Fase 1: vedi branch/issue [Research: rebase e conflitti delle PR Handy Fase 1](https://github.com/Alexm751/Voxlab/issues/3).
