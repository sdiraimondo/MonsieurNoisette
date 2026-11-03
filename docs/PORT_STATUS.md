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
- `recomp-ui` est un sous-module au commit `a956157` ; il fournit le launcher
  ImGui, le picker de ROM et « Generate & rebuild » ;
- `framework_pins.txt` enregistre le framework, `recomp-ui` et leurs
  sous-modules ;
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
- `scripts/package_release.sh` produit un setup pack (`dist/*-linux-x64.zip`) :
  hôte de setup, recompilateur, analyseur natif et arbre source, sans ROM ;
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

### Setup pack

`scripts/package_release.sh build-setup linux-x64` produit
`dist/MrNutz-0.1.0-linux-x64.zip` (18 Mo) :

- hôte de setup construit avec `-DSNESRECOMP_SETUP_HOST=ON` (sans code
  recompilé) ;
- arbre source complet, sous-modules compris, pour que « Generate & rebuild »
  recompile le jeu chez le joueur ;
- analyseur natif précompilé, polices du launcher, README et VERSION ;
- aucune ROM, aucun `src/gen`, aucun `recomp/funcs.h`, aucune bibliothèque
  externe à installer.

Le packager a exécuté son smoke test SDK et l'a validé. Le parcours complet a
aussi été exercé depuis le zip décompressé, avec le pack de toolchain
`cmake-clang-v1` v1.0.14 :

1. le launcher du setup host s'ouvre, reconnaît la ROM et affiche
   « ROM verified » ;
2. « Generate & rebuild » régénère les sources, configure et compile
   (27,7 s), puis relance le binaire reconstruit ;
3. le launcher du binaire reconstruit affiche `PLAY`, et le jeu atteint
   l'écran titre.

Sans pack de toolchain, l'hôte retombe sur le cmake/compilateur du système :
il faut alors les en-têtes OpenGL de développement (`mesa-libGL-devel`), sinon
la configuration échoue. Le workflow de release télécharge et embarque le pack
par défaut (`--embed-toolchain`), ce qui évite cette dépendance.

### Launcher

Validé sous Xvfb (`SDL_VIDEODRIVER=x11`, rendu llvmpipe) :

- la fenêtre « Mr. Nutz — Launcher » s'ouvre en 1100×880 ;
- la ROM est reconnue (« ROM verified », région USA, nom du fichier) ;
- la DualSense Edge est détectée et assignée au joueur 1 ;
- `PLAY` ferme le launcher et ouvre la fenêtre de jeu 960×720 sur l'écran
  titre.

Les panneaux `Settings` et `Mods` ont été ouverts et exercés sous Xvfb :

- `Settings` affiche les blocs Display (échelle 3x, renderer Auto, plein
  écran, filtrage linéaire, frame blending, VSync, run-ahead), Audio (32 000 Hz,
  volume 100 %) et Hotkeys. La case « Linear filtering » bascule à l'on/off et
  `Back` ramène au tableau de bord.
- `Mods` affiche les onglets `Features` et `Installed packages`, l'arbre des
  fonctionnalités et le paquet `High-resolution Mode 7` (snesrecomp). Le
  multiplicateur de résolution passe de 8 à 9 puis revient à 8, et `Back`
  ramène au tableau de bord.

En mode headless sans écran, le launcher se rabat sur le résolveur console et
le smoke test continue de passer.

### Entrées, pause et overlays

- `Droite` + `X` (bouton A) déplacent et font sauter le joueur ; le score est
  passé de 250 à 850 et les pièces ont été ramassées.
- `Shift+P` met le jeu en pause : deux captures à 2 s d'intervalle sont
  identiques au pixel près.
- Le self-test du framework
  (`SNESRECOMP_OVERLAY_SELFTEST_PAD=1200`) attache une manette virtuelle et
  ouvre/ferme le navigateur de sauvegardes puis la bande de rembobinage avec
  les gestes Select+R et Select+R3. Résultat : `ok`, les deux panneaux
  s'ouvrent et se ferment depuis la manette.
- Captures : le navigateur affiche les 13 slots (`NEW SLOT`, LOAD / SAVE /
  BACK, raccourcis clavier) ; la bande de rembobinage affiche `REWIND`,
  l'offset (`-0.1s`) et six vignettes avec la sélection courante.
- `Alt+Return` bascule l'état plein écran et le persiste (`Fullscreen = 1`
  dans `config.ini`) ; Xvfb n'a pas de gestionnaire de fenêtres, donc le
  redimensionnement bureau n'a pas pu être observé.

### Anciens problèmes

- **Clignotement du titre** : non reproduit. Les frames 700–1080 ont été
  capturées ; aucune frame noire après le logo et la luminosité du titre reste
  stable (108–109/255).
- **Saccades** : non observées sur le soak (59,5 fps de moyenne). Une mesure
  de gigue frame par frame n'est pas instrumentée.
- **WRAM `$10C2`** : jamais écrite pendant 2 500 frames (trace WRAM complète
  de `$0000`–`$1FFF`) et aucune référence à `$7E10C2` dans la ROM. L'ancienne
  piste n'est pas reproductible avec le framework actuel ; elle est écartée.

### Couverture

Capture sur 6 974 frames (titre → niveau 1, marche/sauts/courses) :
98,4 M instructions interprétées, 331 sites de transfert, 0 routine RAM,
0 avertissement. Les deux PCs les plus chauds (`80:822E` et `80:8231`)
représentent ~49 % des cycles invités.

Décision : **pas de promotion AOT pour la v1.0**. Le jeu tient 59,5 fps en
100 % LLE à ~50 % d'un cœur ; une promotion demanderait analyse, régénération,
comparaison de replay et validation du gameplay. Détails et commandes de
reproduction : [`COVERAGE.md`](COVERAGE.md).

## 5. Non validé (nécessite une session avec écran et manette)

- boutons physiques de la DualSense Edge (saut, course, pause) et hot-plug ;
  la détection, le mapping et les gestes sont validés avec une manette
  virtuelle ;
- écoute humaine de l'audio ;
- parcours complet du niveau 1 (le smoke test ne joue que quelques secondes) ;
- plein écran sur un vrai gestionnaire de fenêtres (le drapeau bascule, la
  géométrie bureau n'a pas pu être vérifiée sous Xvfb).

## 6. Prochaines étapes

1. Tests manuels restants avec écran et manette.
2. Passer `VERSION` à 1.0.0, regénérer le setup pack et taguer la release
   (procédure : [`RELEASE.md`](RELEASE.md)).
3. Post-1.0 : promotion AOT ciblée, si le profil de performance le justifie
   (voir [`COVERAGE.md`](COVERAGE.md)).

## 7. Commandes utiles

```sh
git submodule update --init --recursive
tools/regen.sh --rom "ROM/Mr. Nutz (USA) (En,Fr).sfc"
./build.sh
tools/smoke.sh "ROM/Mr. Nutz (USA) (En,Fr).sfc"
tools/audio_probe.sh "ROM/Mr. Nutz (USA) (En,Fr).sfc"
```

Voir [`BUILD.md`](BUILD.md) pour le conteneur `distrobox`.
