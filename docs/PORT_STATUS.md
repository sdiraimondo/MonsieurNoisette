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
- `tools/audio_probe.sh` capture la sortie DSP native et vérifie qu'elle n'est
  pas silencieuse ;
- `scripts/package_release.sh` et le workflow de release sont ajoutés.

Validation de la Phase 0 : un clone frais du dépôt a été testé avec
`git clone --recurse-submodules`, `tools/regen.sh`, `./build.sh` et
`tools/smoke.sh`. Le sous-module, les pins, la génération et le build passent.

## 4. Fonctionnel validé

### Boot et jeu

| Frame | Résultat |
|---|---|
| 880 | écran titre |
| 1800 | carte « WOODY LAND JOURNEY: 1 » |
| 2500 | gameplay du niveau 1 |

- `Start` lance bien la partie depuis le titre.
- `Droite` déplace le joueur.
- 59,5–60,0 fps selon les runs ; ~50 % d'un cœur CPU.
- Exécution : 100 % LLE (interpréteur) ; `src/gen` ne contient que les
  vecteurs IRQ.

### Audio

`tools/audio_probe.sh` capture la sortie native du S-DSP (s16 stéréo,
32 040 Hz) sur le parcours titre → niveau 1 :

| Mesure | Valeur |
|---|---|
| Durée capturée | 40,2 s |
| Crête | 8107 |
| RMS | 978 |
| Secondes audibles | 21 |

La chronologie correspond aux scènes : jingle vers 2–3 s, thème du titre vers
12–16 s, carte de niveau vers 19–24 s, musique du niveau 1 vers 32–41 s. Le
chemin SDL a aussi été capturé via le pilote `disk` (rééchantillonné en
44,1 kHz) et contient le même signal. L'écoute humaine reste à faire.

### Sauvegarde / chargement

Testé avec le serveur de debug du framework (`build-trace`,
`-DSNESRECOMP_ENABLE_TRACE=ON`) :

1. sauvegarde de l'état en niveau 1 (`save0.sav`, 297 411 octets) ;
2. déplacement du joueur ;
3. chargement de l'état.

Écart visuel moyen : **2,64/255** entre l'image sauvegardée et l'image
rechargée, contre **46,35/255** après déplacement. L'état est bien restauré.

### Stabilité

Soak test headless de 30 minutes :

| Mesure | Valeur |
|---|---|
| Frames | 108 000 |
| Durée | 30 min 15 s |
| fps moyen | 59,507 |
| Code de sortie | 0 |
| RSS | 7,6 Mo au boot → 42,1 Mo au pic → 32,6 Mo stable |

Pas de fuite mémoire ni de dérive de framerate observées.

### Anciens problèmes

- **Clignotement du titre** : non reproduit. Les frames 700–1080 ont été
  capturées ; aucune frame noire après le logo et la luminosité du titre reste
  stable (108–109/255).
- **Saccades** : non observées sur le soak (59,5 fps de moyenne). Une mesure
  de gigue frame par frame n'est pas instrumentée.
- **WRAM `$10C2`** : jamais écrite pendant 2 500 frames (trace WRAM complète
  de `$0000`–`$1FFF`) et aucune référence à `$7E10C2` dans la ROM. L'ancienne
  piste n'est pas reproductible avec le framework actuel ; elle est écartée.

## 5. Non validé (nécessite une session avec écran et manette)

- boutons réels de la manette (saut, course, pause) ; la DualSense Edge est
  détectée et assignée au joueur 1 ;
- launcher, plein écran et mods ;
- rembobinage `F12` (le ring de 60 snapshots est alloué, la touche n'a pas été
  exercée) ;
- écoute humaine de l'audio ;
- parcours complet du niveau 1 (le smoke test ne joue que quelques secondes).

## 6. Prochaines étapes

1. Tests manuels ci-dessus avec écran et manette.
2. Commit de la validation Phase 1.
3. Mesurer la couverture et décider d'une promotion AOT ciblée.
4. Passer `VERSION` à 1.0.0, builder le setup pack et taguer la release.

## 7. Commandes utiles

```sh
git submodule update --init --recursive
tools/regen.sh --rom "ROM/Mr. Nutz (USA) (En,Fr).sfc"
./build.sh
tools/smoke.sh "ROM/Mr. Nutz (USA) (En,Fr).sfc"
tools/audio_probe.sh "ROM/Mr. Nutz (USA) (En,Fr).sfc"
```

Voir [`BUILD.md`](BUILD.md) pour le conteneur `distrobox`.
