[English](README.md) · [Español](README.es.md) · **Français** · [Deutsch](README.de.md) · [日本語](README.ja.md) · [中文](README.zh.md) · [हिन्दी](README.hi.md)

# Chordex FM

Un instrument d'accords avec un moteur FM à 4 opérateurs (style DX / TX81Z)
pour [monome norns](https://monome.org/docs/norns/). Une touche joue un accord
de quatre notes plus la basse ; la touche la plus grave enfoncée donne la
fondamentale.

![Chordex FM, six modèles](docs/sheet.png)

**L'écran est la FM**, dessinée avec la même formule que celle qui produit le
son :

- **à gauche, l'algorithme :** 4 opérateurs en cercles. Leur luminosité est
  leur enveloppe, le point qui tourne à l'intérieur suit la vitesse de son
  ratio, les lignes sont la modulation (particules en mouvement = quantité
  d'index) et la boucle de l'opérateur 4 est son feedback. En dessous, les
  9 faders.
- **au centre, la fleur :** la vraie forme d'onde de la note, en coordonnées
  polaires. Avec un index faible, c'est un cercle doux ; avec un index élevé,
  elle se remplit de pétales et de pointes. Le contour fantôme est le fatness,
  les étincelles sont le shimmer et le craquement, et au centre se trouve
  l'accord sur une roue de 12 notes. Chaque note d'arpège s'envole comme une
  comète.
- **à droite :** oscilloscope (un cycle) et spectre (les harmoniques et bandes
  latérales créées par la FM) ; en dessous, le motif de l'arpège.

## Fonctions

- **FM à 4 opérateurs** : 8 algorithmes, ratios, feedback de l'opérateur 4,
  une enveloppe par opérateur et un « balayage » des modulateurs
- **10 modèles** : EPIANO, CAMPANA (cloche), METAL, CORO (chœur), BAJO
  (basse), ORGANO (orgue), MARIMBA, CUERDAS (cordes), FLAUTA (flûte), VIDRIO
  (verre)
- **10 accords** : maj, min, dim, aug, 7, maj7, min7, m7b5, sus2, sus4
- **arpégiateur** : up, down, up-down, up x2, down x2, random et *arpa*
  (harpe) ; gate au maximum = vrai legato
- **mode accord** on/off (off = notes seules) et **maintien**
- craquement de vieux disque avec plus de deux touches enfoncées
- suit l'horloge MIDI entrante pour le tempo de l'arpège
- tous les réglages sont sauvegardés automatiquement

De la famille Chordex : mêmes contrôles que Chordex80.

## Prérequis

- norns (shield, standard ou fates)
- un clavier ou contrôleur MIDI

## Installation

Depuis maiden :

```
;install https://github.com/buenosairesfront/chordexfm
```

Ensuite **redémarrez norns** (SYSTEM > RESTART) pour compiler le nouveau
moteur `ChordexFM`, puis chargez **chordexfm** depuis SELECT.

## Contrôles

| contrôle | action |
|---|---|
| E1 | index FM (brillance) |
| E2 | choisir un fader |
| E3 | régler le fader |
| K3 + E1 | modèle |
| K3 + E2 | feedback de l'opérateur 4 |
| K3 + E3 | type d'accord |
| K3 maintenu (sans tourner) | mode accord on/off |
| K2 (appui bref) | arpégiateur on/off |
| K2 + E1 | gate de l'arpège (max = legato) |
| K2 + E2 | motif de l'arpège |
| K2 + E3 | vitesse de l'arpège |
| K1 maintenu | maintien on/off (petit point en haut à droite) |

**Faders :** attaque, decay, ratio de l'opérateur 2, algorithme, balayage
(decay des modulateurs), distorsion, wobble, fatness, shimmer.

**Menu PARAMETERS :** canal MIDI (0 = tous, par défaut), diviseur d'horloge
MIDI, hall, volume, et tout ce qui précède.

## Galerie

| | |
|---|---|
| ![EPIANO](docs/1_epiano.png) EPIANO · maj7 | ![CAMPANA](docs/2_campana.png) CAMPANA (cloche) |
| ![METAL](docs/3_metal.png) METAL · index élevé | ![ORGANO](docs/4_organo.png) ORGANO (orgue) |
| ![CUERDAS](docs/5_cuerdas_arp.png) CUERDAS (cordes) · arpège | ![VIDRIO](docs/6_vidrio.png) VIDRIO (verre) |

## Crédits

Créé par [Buenos Aires Front](https://github.com/buenosairesfront) / U-MA.
Licence MIT.
