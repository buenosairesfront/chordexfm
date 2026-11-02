// Engine_ChordexFM.sc
// Chordex FM — mismo instrumento de acordes que Chordex2 / Chordex80
// (una tecla = un acorde de 4 tonos + bajo, arpegio, retener, crackle),
// pero con un motor FM de 4 operadores al estilo DX / TX81Z.
//
// Voz (\fm_voice / \fm_pluck / \fm_legato): 4 operadores seno con
//   modulación de fase. Cada operador tiene ratio, nivel (en los
//   moduladores = índice, en los portadores = mezcla) y su propia
//   envolvente (ataque, decay, sustain). El operador 4 tiene feedback
//   (SinOscFB: de seno a casi sierra). La ruta entre operadores la da el
//   algoritmo: una matriz m43 m42 m41 m32 m31 m21 + portadores c1..c4.
//   El índice global llega por un bus de control: E1 lo mueve en vivo,
//   hasta en las notas que ya están sonando. La velocidad abre el índice
//   (como en un DX) y en notas agudas se cierra un poco (keytracking).
//   fatness = cada portador se duplica levemente desafinado a la derecha.
// Modelos (command "model"): 0 EPIANO, 1 CAMPANA, 2 METAL, 3 CORO.
//   Cada modelo es una tabla de operadores; algoritmo, ratio del op 2,
//   feedback y barrido (decay de los moduladores) se mandan aparte.
// FX (\fm_fx): crackle -> chorus estéreo -> shimmer -> hall -> compresor.

Engine_ChordexFM : CroneEngine {

  var voiceBus, idxBus;
  var fxSynth;
  var noteGroup, releasingGroup, padSynth, legatoSynth, plucks;

  var atk = 0.01, rel = 0.9;
  var wobble = 0.2, drive = 0.1, fatness = 0.5, shimmer = 0.0;
  var model = 0, alg = 5, ratio2 = 1, fb = 0, moddec = 1;

  // [r1..r4, l1..l4, a1..a4, d1..d4, s1..s4]
  var models, modelAmp;
  // algoritmos: [m43, m42, m41, m32, m31, m21, c1, c2, c3, c4]
  var algs;

  alloc {
    var mk;
    plucks = List.new;

    models = [
      // EPIANO (DX E.PIANO 1): par cálido 2->1 y par "tine" 4->3 ratio 14
      [1, 1, 1, 14,   1.0, 1.1, 0.55, 0.9,   0, 0, 0, 0,   2.6, 1.4, 0.9, 0.22,   0.55, 0.25, 0.0, 0.0],
      // CAMPANA: ratios inarmónicos (3.5, 2.76), decays largos
      [1, 3.5, 2, 2.76,   1.0, 1.3, 0.5, 1.0,   0, 0, 0, 0,   4.0, 2.4, 3.0, 1.2,   0.3, 0.15, 0.2, 0.1],
      // METAL (bronces): moduladores con ataque lento -> "bwaaah"
      [1, 1, 1, 3,   1.0, 1.4, 0.55, 0.45,   0.02, 0.13, 0.2, 0.05,   3.0, 1.5, 1.0, 1.0,   0.85, 0.55, 0.4, 0.5],
      // CORO: pad suave, portadores en octava + pila 4->3 lenta
      [1, 2, 1, 1,   1.0, 0.45, 0.7, 0.75,   0.25, 0.3, 0.35, 0.6,   4.0, 4.0, 4.0, 4.0,   0.9, 0.8, 0.9, 0.7],
      // BAJO: golpe corto del 2 y gruñido del 4 sobre el 1
      [1, 1, 2, 1,   1.0, 1.2, 0.6, 0.7,   0, 0, 0, 0,   1.4, 0.3, 0.2, 0.4,   0.7, 0.1, 0.05, 0.15],
      // ORGANO: tres tiradores (1, 2, 3) y un "click" corto del 4
      [1, 2, 3, 4,   1.0, 0.7, 0.5, 0.6,   0, 0, 0, 0,   4.0, 4.0, 4.0, 0.15,   1.0, 1.0, 1.0, 0.0],
      // MARIMBA: dos pares percusivos, moduladores que mueren enseguida
      [1, 4, 1, 7,   1.0, 0.9, 0.4, 0.6,   0, 0, 0, 0,   0.9, 0.12, 0.5, 0.08,   0, 0, 0, 0],
      // CUERDAS: pila 4>3>2>1 con ataques lentos, feedback = sierra
      [1, 1, 2, 1,   1.0, 0.7, 0.5, 0.4,   0.4, 0.5, 0.6, 0.7,   4.0, 4.0, 4.0, 4.0,   0.95, 0.85, 0.8, 0.7],
      // FLAUTA: casi seno, el 4 con mucho feedback hace el soplido
      [1, 1, 2, 1,   1.0, 0.35, 0.2, 0.35,   0.08, 0.05, 0.1, 0.02,   3.0, 1.0, 2.0, 0.4,   0.9, 0.5, 0.3, 0.25],
      // VIDRIO: ratios altos (7, 11) y decays largos, brillo de cristal
      [1, 7, 3, 11,   1.0, 0.7, 0.45, 0.5,   0, 0, 0, 0,   3.5, 1.0, 2.5, 0.6,   0.2, 0.1, 0.15, 0.0]
    ];
    // volumen de cada modelo (medido para que suenen parejos)
    modelAmp = [1, 1, 0.85, 0.95, 0.85, 1, 1.15, 0.8, 0.75, 1];

    algs = [
      [1, 0, 0, 1, 0, 1,   1, 0, 0, 0],  // 1: 4>3>2>1
      [0, 1, 0, 1, 0, 1,   1, 0, 0, 0],  // 2: (3+4)>2>1
      [0, 0, 1, 1, 0, 1,   1, 0, 0, 0],  // 3: 3>2>1 + 4>1
      [1, 0, 0, 0, 1, 1,   1, 0, 0, 0],  // 4: 4>3>1 + 2>1
      [1, 0, 0, 0, 0, 1,   1, 0, 1, 0],  // 5: 2>1  4>3  (dos pares)
      [1, 1, 1, 0, 0, 0,   1, 1, 1, 0],  // 6: 4>1,2,3
      [1, 0, 0, 0, 0, 0,   1, 1, 1, 0],  // 7: 4>3 + 1 + 2
      [0, 0, 0, 0, 0, 0,   1, 1, 1, 1]   // 8: aditivo (órgano)
    ];

    voiceBus = Bus.audio(context.server, 2);
    idxBus = Bus.control(context.server, 1);
    idxBus.set(1.0);

    // mode 0 = acorde (gate), 1 = pluck del arpegio (dur), 2 = legato
    mk = { |name, mode|
      SynthDef(name, {
        arg out = 0, freq = 440, gate = 1, vel = 0.8, amp = 0.2, pan = 0, dur = 0.3,
            atk = 0.01, rel = 0.9, wobble = 0.2, drive = 0.1, fat = 0.5, moddec = 1,
            r1 = 1, r2 = 1, r3 = 1, r4 = 14,
            l1 = 1, l2 = 1.1, l3 = 0.55, l4 = 0.9,
            a1 = 0, a2 = 0, a3 = 0, a4 = 0,
            d1 = 2.6, d2 = 1.4, d3 = 0.9, d4 = 0.22,
            s1 = 0.55, s2 = 0.25, s3 = 0, s4 = 0,
            m43 = 1, m42 = 0, m41 = 0, m32 = 0, m31 = 0, m21 = 1,
            c1 = 1, c2 = 0, c3 = 1, c4 = 0, fb = 0, idxBus = 0;
        var g, relE, f, fv, vdel, vib, drift, idx, det, ks, master,
            e1, e2, e3, e4, op, p4, p3, p2, p1, q1, q2, q3, q4,
            mod4, mod3, mod2, pm3, pm2, pm1, csum, sl, sr, sig, dg, sat, att;

        if (mode == 1) {
          g = Trig1.kr(1, dur * 0.45);
          relE = (dur * 0.9) + 0.04;
          att = 0.15;
        } {
          g = gate;
          relE = rel;
          att = 1;
        };

        // envolvente de cada operador; en los moduladores el decay se
        // estira o acorta con "barrido" (moddec); en los portadores el
        // ataque suma el attack general
        op = { |a, d, s, c|
          EnvGen.kr(Env([0, 1, s, 0],
            [(a * att) + (atk * c) + 0.002, d * (c + ((1 - c) * moddec)), relE],
            [-2, -4, -4], 2), g)
        };
        e1 = op.(a1, d1, s1, c1);
        e2 = op.(a2, d2, s2, c2);
        e3 = op.(a3, d3, s3, c3);
        e4 = op.(a4, d4, s4, c4);

        fv = if (mode == 2) { Lag.kr(freq, 0.035) } { freq };
        vdel = EnvGen.kr(Env([0, 0, 1], [0.3, 0.9]));
        vib = SinOsc.kr(5.2 + LFNoise1.kr(0.4).range(-0.2, 0.2)) * wobble * 0.006 * vdel;
        drift = LFNoise2.kr(0.3).range(-0.0015, 0.0015);
        f = fv * (1 + vib + drift);

        // índice en radianes: bus (E1) x velocidad x keytracking
        ks = (fv / 261.6).pow(-0.3).clip(0.45, 1.5);
        idx = In.kr(idxBus, 1) * (0.45 + (vel * 0.75)) * ks * 2.2
          * (1 + (SinOsc.kr(0.7) * wobble * 0.15));

        p4 = SinOscFB.ar(f * r4, fb);
        mod4 = p4 * e4 * l4 * idx;
        pm3 = mod4 * m43;
        p3 = SinOsc.ar(f * r3, pm3);
        mod3 = p3 * e3 * l3 * idx;
        pm2 = (mod4 * m42) + (mod3 * m32);
        p2 = SinOsc.ar(f * r2, pm2);
        mod2 = p2 * e2 * l2 * idx;
        pm1 = (mod4 * m41) + (mod3 * m31) + (mod2 * m21);
        p1 = SinOsc.ar(f * r1, pm1);

        // fatness: cada portador tiene un gemelo desafinado (canal derecho)
        det = 1 + (fat * 0.0045);
        q1 = SinOsc.ar(f * r1 * det, pm1);
        q2 = SinOsc.ar(f * r2 * det, pm2);
        q3 = SinOsc.ar(f * r3 * det, pm3);
        q4 = SinOscFB.ar(f * r4 * det, fb);

        csum = ((c1 * l1) + (c2 * l2) + (c3 * l3) + (c4 * l4)).max(0.6);
        sl = ((p1 * e1 * l1 * c1) + (p2 * e2 * l2 * c2) + (p3 * e3 * l3 * c3) + (p4 * e4 * l4 * c4)) / csum;
        sr = ((q1 * e1 * l1 * c1) + (q2 * e2 * l2 * c2) + (q3 * e3 * l3 * c3) + (q4 * e4 * l4 * c4)) / csum;
        sig = [sl, (sl * (1 - fat)) + (sr * fat)];

        dg = 1 + (drive.pow(1.4) * 9);
        sat = (sig * dg).tanh;
        sig = (sig * (1 - drive.min(1))) + (sat * drive.min(1) / (1 + (drive * 0.8)));
        sig = HPF.ar(sig, 40);

        if (mode == 1) {
          master = EnvGen.kr(Env([1, 1, 0], [(dur * 0.45) + relE, 0.05]), doneAction: 2)
            * EnvGen.kr(Env.asr(0, 1, 0.06), gate, doneAction: 2);
        } {
          master = EnvGen.kr(Env.asr(0, 1, relE + 0.08), gate, doneAction: 2);
        };
        sig = sig * master * amp * (0.45 + (Lag.kr(vel, 0.03) * 0.55));
        Out.ar(out, Balance2.ar(sig[0], sig[1], if (mode == 2) { Lag.kr(pan, 0.05) } { pan }));
      }).add;
    };
    mk.(\fm_voice, 0);
    mk.(\fm_pluck, 1);
    mk.(\fm_legato, 2);

    // --- bajo: un par FM 1:1 suave, el índice sigue a E1 ---
    SynthDef(\fm_bass, {
      arg out = 0, freq = 55, gate = 1, atk = 0.01, rel = 0.6,
          drive = 0.1, amp = 0.3, idxBus = 0;
      var env, menv, sig, idx;
      env = EnvGen.kr(Env.asr(atk, 1, rel), gate, doneAction: 2);
      menv = EnvGen.kr(Env([0, 1, 0.35], [0.005, 0.5], -4));
      idx = In.kr(idxBus, 1).clip(0, 2.5) * 0.6 * menv;
      sig = SinOsc.ar(freq, SinOsc.ar(freq) * idx);
      sig = (sig * (1 + (drive * 3))).tanh / (1 + (drive * 0.6));
      Out.ar(out, Pan2.ar(sig * env * amp, 0));
    }).add;

    SynthDef(\fm_fx, {
      arg in, out, fat = 0.5, shimmer = 0, crackle = 0, space = 0.22, gain = 1.0;
      var dry, sig, lfo1, lfo2, cmix, wet, sh, verb, cn, cg, comp;

      dry = In.ar(in, 2);
      sig = dry;

      // crackle: igual que en Chordex2 (solo suena si hay señal)
      cn = HPF.ar(Crackle.ar(1.85, mul: [1, 1]), 1600);
      cg = Amplitude.kr(Mix(dry), 0.01, 0.08) > 0.02;
      sig = sig + (cn * crackle * 0.3 * cg);

      // chorus estéreo tipo DX + ensemble (fatness)
      lfo1 = LFTri.kr(0.47);
      lfo2 = LFTri.kr(0.79);
      cmix = LPF.ar(Mix(sig) * 0.5, 9000);
      wet = [DelayC.ar(cmix, 0.02, 0.004 + (lfo1 * 0.0016) + (lfo2 * 0.0007)),
             DelayC.ar(cmix, 0.02, 0.004 - (lfo1 * 0.0016) - (lfo2 * 0.0007))];
      sig = (sig * (1 - (fat * 0.25))) + (LPF.ar(wet, 8000) * fat * 0.55);

      // shimmer: reverb de la señal una octava arriba
      sh = PitchShift.ar(sig, 0.15, 2.0, 0.008, 0.01);
      sh = FreeVerb2.ar(sh[0], sh[1], 1, 0.9, 0.3);
      sig = sig + (sh * shimmer * 0.8);

      verb = HPF.ar(sig, 200) * (space + (shimmer * 0.35));
      verb = DelayN.ar(verb, 0.05, 0.03);
      verb = FreeVerb2.ar(verb[0], verb[1], 1, 0.93 + (shimmer * 0.05), 0.4);
      sig = sig + (verb * 0.9);

      comp = Compander.ar(sig, Mix(sig) * 0.5, 0.25, 1, 0.5, 0.008, 0.18);
      sig = comp * 1.5 * gain;
      // lookahead corto: el Limiter atrasa la señal 2 x dur (antes 20 ms)
      sig = Limiter.ar(LeakDC.ar(sig), 0.92, 0.002);
      Out.ar(out, sig);
    }).add;

    context.server.sync;

    fxSynth = Synth.tail(context.xg, \fm_fx, [
      \in, voiceBus, \out, context.out_b, \fat, fatness, \shimmer, shimmer
    ]);

    this.addCommand("noteOn", "ffffff", { |msg|
      var freqs = [msg[1], msg[2], msg[3], msg[4]];
      var subf = msg[5], vel = msg[6], nv;

      if (releasingGroup.notNil) { releasingGroup.free };
      if (noteGroup.notNil) {
        noteGroup.set(\gate, 0);
        releasingGroup = noteGroup;
      };
      noteGroup = Group.head(context.xg);

      // freq 0 = voz apagada (modo acorde off: una sola nota, al centro)
      nv = freqs.count({ |f| f > 0 }).max(1);
      freqs.do({ |f, i|
        if (f > 0) {
          Synth.new(\fm_voice, this.voiceArgs ++ [
            \freq, f, \vel, vel, \amp, 0.2 * modelAmp[model] * ((4 / nv) ** 0.5),
            \pan, if (nv == 1) { 0 } { ((i - 1.5) * 0.3 * (0.5 + fatness)).clip(-0.9, 0.9) }
          ], noteGroup);
        };
      });
      Synth.new(\fm_bass, [
        \out, voiceBus, \freq, this.bassFreq(subf), \atk, atk, \rel, rel,
        \drive, drive, \idxBus, idxBus.index, \amp, 0.22
      ], noteGroup);
    });

    this.addCommand("noteOff", "", { |msg|
      var g;
      if (releasingGroup.notNil) { releasingGroup.free; releasingGroup = nil };
      if (noteGroup.notNil) {
        g = noteGroup;
        g.set(\gate, 0);
        releasingGroup = g;
        noteGroup = nil;
        SystemClock.sched(rel + 0.6, {
          if (releasingGroup === g) { g.free; releasingGroup = nil };
          nil
        });
      };
    });

    this.addCommand("padOn", "f", { |msg|
      if (padSynth.notNil) {
        padSynth.set(\freq, this.bassFreq(msg[1]));
      } {
        padSynth = Synth.new(\fm_bass, [
          \out, voiceBus, \freq, this.bassFreq(msg[1]), \atk, atk, \rel, rel,
          \drive, drive, \idxBus, idxBus.index, \amp, 0.3
        ], context.xg);
      };
    });

    this.addCommand("padOff", "", { |msg|
      if (padSynth.notNil) { padSynth.set(\gate, 0); padSynth = nil };
    });

    // freq, dur, vel, pan
    this.addCommand("arpStep", "ffff", { |msg|
      var p;
      // máximo 8 notas de arpegio a la vez (lección de Chordex80 v10)
      while { plucks.size >= 8 } { plucks.removeAt(0).set(\gate, 0) };
      p = Synth.new(\fm_pluck, this.voiceArgs ++ [
        \freq, msg[1], \dur, msg[2], \vel, msg[3], \pan, msg[4], \amp, 0.3
      ], context.xg);
      plucks.add(p);
      p.onFree { plucks.remove(p) };
    });

    // freq, vel, pan: la primera vez crea la voz, después solo la mueve
    this.addCommand("arpLegato", "fff", { |msg|
      if (legatoSynth.notNil) {
        legatoSynth.set(\freq, msg[1], \vel, msg[2], \pan, msg[3]);
      } {
        legatoSynth = Synth.new(\fm_legato, this.voiceArgs ++ [
          \freq, msg[1], \vel, msg[2], \pan, msg[3], \amp, 0.42
        ], context.xg);
      };
    });
    this.addCommand("arpLegatoOff", "", { |msg|
      if (legatoSynth.notNil) { legatoSynth.set(\gate, 0); legatoSynth = nil };
    });

    this.addCommand("atk", "f", { |msg| atk = msg[1] });
    this.addCommand("rel", "f", { |msg|
      rel = msg[1];
      this.setLive([\rel, rel]);
    });
    this.addCommand("drive", "f", { |msg|
      drive = msg[1];
      this.setLive([\drive, drive]);
    });
    this.addCommand("wobble", "f", { |msg|
      wobble = msg[1];
      this.setLive([\wobble, wobble]);
    });
    this.addCommand("fatness", "f", { |msg|
      fatness = msg[1];
      fxSynth.set(\fat, fatness);
      this.setLive([\fat, fatness]);
    });
    this.addCommand("shimmer", "f", { |msg|
      shimmer = msg[1];
      fxSynth.set(\shimmer, shimmer);
    });
    this.addCommand("space", "f", { |msg| fxSynth.set(\space, msg[1]) });
    this.addCommand("gain", "f", { |msg| fxSynth.set(\gain, msg[1]) });
    this.addCommand("crackle", "f", { |msg| fxSynth.set(\crackle, msg[1]) });
    this.addCommand("index", "f", { |msg| idxBus.set(msg[1]) });

    // los cambios de FM se oyen en vivo en las notas que ya suenan
    this.addCommand("model", "i", { |msg|
      model = msg[1].clip(0, models.size - 1);
      this.setLive(this.opArgs);
    });
    this.addCommand("alg", "i", { |msg|
      alg = msg[1].clip(1, algs.size);
      this.setLive(this.algArgs);
    });
    this.addCommand("ratio", "f", { |msg|
      ratio2 = msg[1];
      this.setLive([\r2, ratio2]);
    });
    this.addCommand("fb", "f", { |msg|
      fb = msg[1];
      this.setLive([\fb, fb]);
    });
    this.addCommand("moddec", "f", { |msg|
      moddec = msg[1];
      this.setLive([\moddec, moddec]);
    });
  }

  opArgs {
    var m = models[model];
    ^[\r1, m[0], \r2, ratio2, \r3, m[2], \r4, m[3],
      \l1, m[4], \l2, m[5], \l3, m[6], \l4, m[7],
      \a1, m[8], \a2, m[9], \a3, m[10], \a4, m[11],
      \d1, m[12], \d2, m[13], \d3, m[14], \d4, m[15],
      \s1, m[16], \s2, m[17], \s3, m[18], \s4, m[19]]
  }

  algArgs {
    var a = algs[alg - 1];
    ^[\m43, a[0], \m42, a[1], \m41, a[2], \m32, a[3], \m31, a[4], \m21, a[5],
      \c1, a[6], \c2, a[7], \c3, a[8], \c4, a[9]]
  }

  voiceArgs {
    ^[\out, voiceBus, \idxBus, idxBus.index, \atk, atk, \rel, rel,
      \wobble, wobble, \drive, drive, \fat, fatness, \fb, fb, \moddec, moddec]
      ++ this.opArgs ++ this.algArgs
  }

  setLive { |args|
    if (noteGroup.notNil) { noteGroup.set(*args) };
    if (legatoSynth.notNil) { legatoSynth.set(*args) };
  }

  // el bajo nunca por debajo de ~40 Hz: en notas graves sube una octava
  bassFreq { |f| ^if (f < 40) { f * 2 } { f } }

  free {
    if (noteGroup.notNil) { noteGroup.free };
    if (releasingGroup.notNil) { releasingGroup.free };
    if (padSynth.notNil) { padSynth.free };
    if (legatoSynth.notNil) { legatoSynth.free };
    fxSynth.free;
    voiceBus.free;
    idxBus.free;
  }
}
