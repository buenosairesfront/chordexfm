[English](README.md) · **Español** · [Français](README.fr.md) · [Deutsch](README.de.md) · [日本語](README.ja.md) · [中文](README.zh.md) · [हिन्दी](README.hi.md)

# Chordex FM

Instrumento de acordes con un motor FM de 4 operadores (estilo DX / TX81Z)
para [monome norns](https://monome.org/docs/norns/). Una tecla toca un acorde
de cuatro notas más el bajo; la tecla más grave apretada marca la raíz.

![Chordex FM, seis modelos](docs/sheet.png)

**La pantalla es el FM**, dibujado con la misma fórmula que suena:

- **izquierda, el algoritmo:** 4 operadores como círculos. Su brillo es su
  envolvente, el punto que gira adentro va a la velocidad de su ratio, las
  líneas son la modulación (las partículas que viajan = cuánto índice) y el
  rulo del operador 4 es el feedback. Abajo, los 9 faders.
- **centro, la flor:** la forma de onda real de la nota, en polar. Con índice
  bajo es un círculo suave; con índice alto se llena de pétalos y púas. El
  fantasma es el fatness, las chispas son shimmer y crackle, y adentro está el
  acorde en la rueda de 12 notas. Cada nota del arpegio sale como un cometa.
- **derecha:** osciloscopio (un ciclo) y espectro (los armónicos y bandas
  laterales que genera el FM); abajo, el patrón del arpegio.

## Características

- **FM de 4 operadores**: 8 algoritmos, ratios, feedback del operador 4,
  envolvente por operador y "barrido" de los moduladores
- **10 modelos**: EPIANO, CAMPANA, METAL, CORO, BAJO, ORGANO, MARIMBA,
  CUERDAS, FLAUTA, VIDRIO
- **10 acordes**: maj, min, dim, aug, 7, maj7, min7, m7b5, sus2, sus4
- **arpegiador**: up, down, up-down, up x2, down x2, random y *arpa*; con el
  gate al máximo, legato real
- **modo acorde** on/off (off = una sola nota) y **retener**
- crackle de disco viejo con más de dos teclas apretadas
- sigue el clock MIDI entrante para el tempo del arpegio
- todo se guarda solo

De la familia Chordex: los mismos controles que Chordex80.

<!-- u-ma:family -->
## La familia Chordex

Mismos controles, motores distintos. Probá los otros:

| | |
|---|---|
| <a href="https://github.com/buenosairesfront/chordex80/blob/main/README.es.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordex80/main/docs/1_d50.png" width="200" alt="Chordex 80"></a> | **[Chordex 80](https://github.com/buenosairesfront/chordex80/blob/main/README.es.md)**<br>polisynth ochentoso con atardecer outrun<br>`;install https://github.com/buenosairesfront/chordex80` |
| <a href="https://github.com/buenosairesfront/chordexstg/blob/main/README.es.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexstg/main/docs/2_tutti.png" width="200" alt="ChordexSTG"></a> | **[ChordexSTG](https://github.com/buenosairesfront/chordexstg/blob/main/README.es.md)**<br>cuerdas de orquesta con el movimiento real de una cuerda frotada<br>`;install https://github.com/buenosairesfront/chordexstg` |
| <a href="https://github.com/buenosairesfront/chordexwt/blob/main/README.es.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexwt/main/docs/2_vocal.png" width="200" alt="Chordex WT"></a> | **[Chordex WT](https://github.com/buenosairesfront/chordexwt/blob/main/README.es.md)**<br>wavetable: 8 bancos de 8 ondas, dibujado como una tabla en 3D<br>`;install https://github.com/buenosairesfront/chordexwt` |

**Más de U-MA:** todos los instrumentos y herramientas en un solo lugar → [muestrario U-MA](https://github.com/buenosairesfront/U-ma/blob/main/README.es.md)
<!-- /u-ma:family -->

## Requisitos

- norns (shield, estándar o fates)
- un teclado o controlador MIDI

## Instalación

Desde maiden:

```
;install https://github.com/buenosairesfront/chordexfm
```

Después **reiniciá la norns** (SYSTEM > RESTART) para que compile el engine
nuevo `ChordexFM`, y cargá **chordexfm** desde SELECT.

## Controles

| control | acción |
|---|---|
| E1 | índice FM (brillo) |
| E2 | elegir fader |
| E3 | ajustar fader |
| K3 + E1 | modelo |
| K3 + E2 | feedback del operador 4 |
| K3 + E3 | tipo de acorde |
| K3 mantenido (sin girar nada) | modo acorde on/off |
| K2 (toque) | arpegiador on/off |
| K2 + E1 | gate del arpegio (al máximo, legato) |
| K2 + E2 | patrón del arpegio |
| K2 + E3 | velocidad del arpegio |
| K1 mantenido | retener on/off (puntito arriba a la derecha) |

**Faders:** ataque, decay, ratio del operador 2, algoritmo, barrido (decay de
los moduladores), distorsión, wobble, fatness, shimmer.

**Menú PARAMETERS:** canal MIDI (0 = todos, por defecto), divisor del reloj
MIDI, hall, volumen y todo lo anterior.

## Galería

| | |
|---|---|
| ![EPIANO](docs/1_epiano.png) EPIANO · maj7 | ![CAMPANA](docs/2_campana.png) CAMPANA |
| ![METAL](docs/3_metal.png) METAL · índice alto | ![ORGANO](docs/4_organo.png) ORGANO |
| ![CUERDAS](docs/5_cuerdas_arp.png) CUERDAS · arpegio | ![VIDRIO](docs/6_vidrio.png) VIDRIO |

## Créditos

Hecho por [Buenos Aires Front](https://github.com/buenosairesfront) / U-MA.
Licencia MIT.
