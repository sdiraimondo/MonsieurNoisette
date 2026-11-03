# Point de situation — portage Mr. Nutz sur snesrecomp

Date : 2026-11-03

## 1. Objectif

Stabiliser le jeu (Mr. Nutz, USA, ROM `Mr. Nutz (USA) (En,Fr).sfc`) sous Linux.
Hors périmètre de la v1.0 : musique MP3, niveaux personnalisés, Windows,
netplay.

## 2. Framework

| Élément | Valeur |
|---|---|
| Dépôt | https://github.com/RetroPortingToolKit/snesrecomp |
| Commit pinné | `98f41838443a7cd7f9d56bec41387a6ebfc3bcbc` |
| Date du commit | 2026-10-30 |
| Sous-module | `snesrecomp/` |
| Pins | `framework_pins.txt` |

Le commit `98f41838` est celui qui a généré et validé le port actuel. Le
`main` amont a depuis avancé de 14 commits (dont HD Mode 7, netplay, captures
DSP). La mise à jour du framework est une tâche séparée, à faire avec
régénération, rebuild et smoke test complet.

Procédure : [`FRAMEWORK.md`](FRAMEWORK.md).

## 3. État du dépôt

Nettoyage effectué :

- `snesrecomp` est un sous-module Git au commit `98f41838` ;
- `framework_pins.txt` enregistre le framework et ses sous-modules ;
- `config.ini`, `keybinds.ini`, `rom.cfg` ne sont plus suivis ;
- `STATUS_REPORT.txt` et `models` ont été supprimés ;
- l'ancien host (`src/app`, `src/platform`, `src/overlay`) et l'ancien driver
  (`src/mrnutz/frame`, `game`, `ppu_render`) ont été retirés ;
- les stubs MP3 (`src/audio`), niveaux (`src/levels`), `third_party/minimp3*`
  et le lecteur SPC maison ont été retirés ;
- `src/variables.h` est revenu à un fichier minimal ; les adresses WRAM non
  vérifiées sont documentées dans [`PORT_NOTES.md`](PORT_NOTES.md) ;
- `build.sh` ne force plus un chemin `SDL3_DIR` local ;
- `tools/smoke.sh` teste boot → titre → niveau 1 ;
- `scripts/package_release.sh` et le workflow de release sont ajoutés.

Validation de la Phase 0 : un clone frais du dépôt a été testé avec
`git clone --recurse-submodules`, `tools/regen.sh`, `./build.sh` et
`tools/smoke.sh`. Le sous-module, les pins, la génération et le build passent.

## 4. Fonctionnel validé

Test headless avec le binaire d'avant nettoyage :

| Frame | Résultat |
|---|---|
| 900 | écran titre |
| 1800 | carte « WOODY LAND JOURNEY: 1 » |
| 2500 | gameplay du niveau 1 |

- `Start` lance bien la partie depuis le titre.
- `Droite` déplace le joueur.
- ~59,98 fps, ~20 s de CPU pour 44 s de temps réel.
- Exécution : 100 % LLE (interpréteur) ; `src/gen` ne contient que les
  vecteurs IRQ.

## 5. Non validé

- audio réel (musique + SFX) ;
- manette réelle et boutons saut/course/pause ;
- sauvegarde/chargement d'état et rembobinage ;
- launcher, plein écran, mods ;
- soak test 30–60 minutes ;
- anciens problèmes : clignotement du titre, saccades, WRAM `$10C2`.

## 6. Prochaines étapes

1. Rebuild propre avec le sous-module et `tools/smoke.sh`.
2. Valider clavier, manette, audio, sauvegardes et launcher.
3. Soak test et test du niveau 1 complet.
4. Re-tester les anciens problèmes ; les corriger ou les documenter.
5. Mesurer la couverture et décider d'une promotion AOT ciblée.
6. Passer `VERSION` à 1.0.0, builder le setup pack et taguer la release.

## 7. Commandes utiles

```sh
git submodule update --init --recursive
tools/regen.sh --rom "ROM/Mr. Nutz (USA) (En,Fr).sfc"
./build.sh
tools/smoke.sh "ROM/Mr. Nutz (USA) (En,Fr).sfc"
```

Voir [`BUILD.md`](BUILD.md) pour le conteneur `distrobox`.
