# Couverture et décision AOT

Mesure de la couverture d'exécution du build actuel, et décision sur une
éventuelle promotion AOT avant la v1.0.

## Objectif

Le port tourne intégralement dans l'interpréteur (`src/gen` ne contient que les
vecteurs IRQ). Le framework sait capturer où l'interpréteur travaille et
proposer des entrées candidates à la génération AOT. Cette mesure vérifie si
une promotion est utile pour la v1.0 ; elle ne certifie pas que du code généré
serait correct.

## Capture

Route : boot → titre → carte → niveau 1, puis marche, sauts et courses pendant
environ deux minutes (6 974 frames utiles).

```text
wait 950
press start 2
wait 900
press right 600
press right+a 2
wait 120
press right 900
press a 2
wait 120
press right 600
press right+a 2
wait 120
press right 900
press a 2
wait 120
press right 600
press right+b 2
wait 120
press right 900
quit
```

Écrire cette route dans `/tmp/mrnutz-coverage/route.txt`, puis :

```sh
mkdir -p /tmp/mrnutz-coverage
cd build
SDL_VIDEODRIVER=dummy SDL_AUDIO_DRIVER=dummy \
  SNESRECOMP_TIER2_CAPTURE=1 \
  SNESRECOMP_COVERAGE_DIR=/tmp/mrnutz-coverage \
  SNESRECOMP_RUN_FRAMES=8000 \
  ./MrNutzRecomp --no-launcher --script /tmp/mrnutz-coverage/route.txt \
  "../ROM/Mr. Nutz (USA) (En,Fr).sfc"
```

Puis, avec le manifeste du build qui a produit la capture :

```sh
python3 snesrecomp/tools/tier2_ingest.py \
  /tmp/mrnutz-coverage/mrnutz/*.json /tmp/mrnutz-coverage/mrnutz/*.jsonl \
  --cfg-dir recomp --program-manifest src/gen/program_manifest.json
```

Le manifeste doit être celui du binaire utilisé : l'outil vérifie son empreinte
et refuse un manifeste régénéré après coup.

## Résultats

| Mesure | Valeur |
|---|---|
| Frames simulées | 6 974 |
| Instructions interprétées | 98 384 854 |
| Cycles invité | 372 037 823 |
| Sites de transfert observés | 331 |
| Candidats `call_gap` | 259 |
| Atterrissages `goto` à délimiter | 72 |
| Routines RAM | 0 |
| Avertissements | 0 |

Identité vérifiée : ROM SHA-256 `3472dd57…`, module `main`, mapper LoROM.

Les deux PCs d'instruction les plus coûteux sont `80:822E` (22,7 M
instructions, 113,7 M cycles) et `80:8231` (22,7 M instructions, 68,2 M
cycles), soit ensemble environ 49 % des cycles invités. Viennent ensuite
`9D:E19A`, `9D:C883` et `9D:E19D`, entre 8,3 et 13,8 M cycles chacun. Aucun
n'est actuellement généré : la capture les voit tous passer par l'interpréteur.

## Décision v1.0

**Pas de promotion AOT pour la v1.0.**

- le jeu tient 59,5 fps stables sur un cœur à ~50 % en 100 % LLE ;
- une promotion exige analyse des 331 sites, régénération, comparaison de
  replay et validation du gameplay ; c'est un changement de binaire, pas une
  optimisation sans risque ;
- la couverture montre que le gain porterait surtout sur des boucles très
  chaudes, sans nécessité pour la cible de performance.

La capture reste reproductible avec les commandes ci-dessus. Une promotion
ciblée est un travail post-1.0, à faire avec `snesrecomp/tools/v2_emit.py`, un
rebuild et `snesrecomp/tools/coverage_replay.py` pour comparer la route de
référence.
