-- Chordex FM
-- hermano FM de Chordex80: mismo instrumento de acordes (una tecla = un
-- acorde de 4 tonos + bajo, suena la nota más grave apretada, arpegio,
-- retener, crackle con más de 2 teclas) con un motor FM de 4 operadores
-- (DX / TX81Z): 8 algoritmos, ratios, feedback, envolvente por operador.
--
-- La pantalla ES el FM, calculado con la misma fórmula que suena:
--   izquierda: el algoritmo. 4 operadores (círculos), su brillo es su
--     envolvente, el punto que gira adentro va a la velocidad de su ratio,
--     las líneas son la modulación (partículas viajando = cuánto índice),
--     el rulo del op 4 es el feedback; abajo, los 9 faders.
--   centro: la flor. La forma de onda real de la nota, en polar: con
--     índice bajo es un círculo suave, con índice alto se llena de pétalos
--     y púas. Fantasma = fatness, chispas = shimmer / crackle, adentro el
--     acorde en la rueda de 12 notas; cada nota del arpegio sale como cometa.
--   derecha: osciloscopio (un ciclo) y espectro (los armónicos y bandas
--     laterales que genera el FM), abajo el patrón del arpegio.
--
-- Controles (los mismos de Chordex80):
--   E1: índice FM (brillo)       K3 + E1: modelo (10: EPIANO, CAMPANA, METAL, CORO,
--                                BAJO, ORGANO, MARIMBA, CUERDAS, FLAUTA, VIDRIO)
--   E2: elige fader              K3 + E2: feedback del op 4
--   E3: ajusta fader             K3 + E3: tipo de acorde
--   K3 mantenido (sin girar nada): modo acorde on/off (off = una sola nota)
--   faders: ataque, decay, ratio op 2, algoritmo, barrido (decay de
--           los moduladores), distorsión, wobble, fatness, shimmer
--   K2: tap = arpegiador on/off
--   K2 + E1: gate del arpegio (al máximo = legato real)
--   K2 + E2: patrón              K2 + E3: velocidad
--   K1 mantenido: retener on/off (puntito arriba a la derecha)
--   clock MIDI entrante: solo marca el tempo del arpegio

engine.name = 'ChordexFM'

local musicutil = require 'musicutil'

local midi_in
local current_note = nil
local current_vel = 0.8
local last_note = nil
local held_stack = {}
-- teclas que arpegia el modo simple (quedan con HOLD hasta la próxima tecla)
local arp_keys = {}
local function update_arp_keys()
  if #held_stack == 0 then return end
  arp_keys = {}
  for i, n in ipairs(held_stack) do arp_keys[i] = n end
  table.sort(arp_keys)
end
-- modo simple: qué teclas están sonando, para no redisparar si no cambió nada
local voiced_sig = nil
local function keys_sig() return table.concat(arp_keys, ",") end
local last_midi_clock = nil
local CLOCK_TIMEOUT = 0.5
local tick_sec = nil
local ext_ticks = 0
local hold_on = false
local loading = false

local chord_types = {"maj", "min", "dim", "aug", "7", "maj7", "min7", "m7b5", "sus2", "sus4"}
local chord_suffix = {maj = "", min = "m", dim = "dim", aug = "+", ["7"] = "7",
  maj7 = "maj7", min7 = "m7", m7b5 = "m7b5", sus2 = "sus2", sus4 = "sus4"}
local chord_intervals = {
  maj = {0, 4, 7}, min = {0, 3, 7}, dim = {0, 3, 6}, aug = {0, 4, 8},
  ["7"] = {0, 4, 7, 10}, maj7 = {0, 4, 7, 11}, min7 = {0, 3, 7, 10},
  m7b5 = {0, 3, 6, 10}, sus2 = {0, 2, 7}, sus4 = {0, 5, 7},
}
local note_names = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
local arp_pattern_names = {"up", "down", "up-down", "up x2", "down x2", "random", "arpa"}
local arp_rate_mult = {4, 2, 1, 0.5}
local arp_rate_names = {"x1/4", "x1/2", "x1", "x2"}

-- ============================================================
-- tablas FM (las mismas que el engine)
-- ============================================================

local FM = {}
FM.models = {
  {name = "EPIANO",  r = {1, 1, 1, 14},   l = {1, 1.1, 0.55, 0.9},
   a = {0, 0, 0, 0},  d = {2.6, 1.4, 0.9, 0.22}, s = {0.55, 0.25, 0, 0},
   alg = 5, ratio = 1, fb = 0, moddec = 1},
  {name = "CAMPANA", r = {1, 3.5, 2, 2.76}, l = {1, 1.3, 0.5, 1.0},
   a = {0, 0, 0, 0},  d = {4, 2.4, 3, 1.2},      s = {0.3, 0.15, 0.2, 0.1},
   alg = 5, ratio = 3.5, fb = 0.1, moddec = 1},
  {name = "METAL",   r = {1, 1, 1, 3},    l = {1, 1.4, 0.55, 0.45},
   a = {0.02, 0.13, 0.2, 0.05}, d = {3, 1.5, 1, 1}, s = {0.85, 0.55, 0.4, 0.5},
   alg = 2, ratio = 1, fb = 0.35, moddec = 1},
  {name = "CORO",    r = {1, 2, 1, 1},    l = {1, 0.45, 0.7, 0.75},
   a = {0.25, 0.3, 0.35, 0.6}, d = {4, 4, 4, 4}, s = {0.9, 0.8, 0.9, 0.7},
   alg = 7, ratio = 2, fb = 0.15, moddec = 1},
  {name = "BAJO",    r = {1, 1, 2, 1},    l = {1, 1.2, 0.6, 0.7},
   a = {0, 0, 0, 0},  d = {1.4, 0.3, 0.2, 0.4},  s = {0.7, 0.1, 0.05, 0.15},
   alg = 3, ratio = 1, fb = 0.25, moddec = 1},
  {name = "ORGANO",  r = {1, 2, 3, 4},    l = {1, 0.7, 0.5, 0.6},
   a = {0, 0, 0, 0},  d = {4, 4, 4, 0.15},       s = {1, 1, 1, 0},
   alg = 6, ratio = 2, fb = 0.05, moddec = 1},
  {name = "MARIMBA", r = {1, 4, 1, 7},    l = {1, 0.9, 0.4, 0.6},
   a = {0, 0, 0, 0},  d = {0.9, 0.12, 0.5, 0.08}, s = {0, 0, 0, 0},
   alg = 5, ratio = 4, fb = 0, moddec = 1},
  {name = "CUERDAS", r = {1, 1, 2, 1},    l = {1, 0.7, 0.5, 0.4},
   a = {0.4, 0.5, 0.6, 0.7}, d = {4, 4, 4, 4},  s = {0.95, 0.85, 0.8, 0.7},
   alg = 1, ratio = 1, fb = 0.22, moddec = 1},
  {name = "FLAUTA",  r = {1, 1, 2, 1},    l = {1, 0.35, 0.2, 0.35},
   a = {0.08, 0.05, 0.1, 0.02}, d = {3, 1, 2, 0.4}, s = {0.9, 0.5, 0.3, 0.25},
   alg = 3, ratio = 1, fb = 0.4, moddec = 1},
  {name = "VIDRIO",  r = {1, 7, 3, 11},   l = {1, 0.7, 0.45, 0.5},
   a = {0, 0, 0, 0},  d = {3.5, 1, 2.5, 0.6},    s = {0.2, 0.1, 0.15, 0},
   alg = 5, ratio = 7, fb = 0, moddec = 1},
}
FM.model_names = {}
for i, m in ipairs(FM.models) do FM.model_names[i] = m.name end

-- algoritmos: mods[j] = a quiénes modula el operador j; car = portadores
FM.algs = {
  {mods = {[4] = {3}, [3] = {2}, [2] = {1}}, car = {1}},
  {mods = {[4] = {2}, [3] = {2}, [2] = {1}}, car = {1}},
  {mods = {[4] = {1}, [3] = {2}, [2] = {1}}, car = {1}},
  {mods = {[4] = {3}, [3] = {1}, [2] = {1}}, car = {1}},
  {mods = {[4] = {3}, [2] = {1}},            car = {1, 3}},
  {mods = {[4] = {1, 2, 3}},                 car = {1, 2, 3}},
  {mods = {[4] = {3}},                       car = {1, 2, 3}},
  {mods = {},                                car = {1, 2, 3, 4}},
}
for _, a in ipairs(FM.algs) do
  a.isc = {}
  for _, c in ipairs(a.car) do a.isc[c] = true end
end
-- dónde se dibuja cada operador en el panel del algoritmo (x, y)
FM.pos = {
  {{15, 30}, {15, 21}, {15, 12}, {15, 3}},
  {{15, 30}, {15, 19}, {8, 7}, {22, 7}},
  {{11, 30}, {6, 19}, {6, 7}, {22, 18}},
  {{11, 30}, {22, 18}, {6, 18}, {6, 6}},
  {{8, 30}, {8, 16}, {22, 30}, {22, 16}},
  {{5, 30}, {15, 30}, {25, 30}, {15, 13}},
  {{5, 30}, {14, 30}, {24, 30}, {24, 15}},
  {{4, 30}, {11, 30}, {18, 30}, {25, 30}},
}
FM.ratios = {0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 5, 6, 7, 8, 9, 11, 14}
FM.ratio_names = {}
for i, r in ipairs(FM.ratios) do FM.ratio_names[i] = tostring(r) end
local function ratio_index(r)
  for i, v in ipairs(FM.ratios) do if math.abs(v - r) < 0.01 then return i end end
  return 2
end

-- faders (E2 elige, E3 ajusta)
local P = {
  {id = "atk",     min = 0.001, max = 2,   step = 0.01},
  {id = "rel",     min = 0.02,  max = 4,   step = 0.03},
  {id = "ratio",   opt = true},
  {id = "alg",     opt = true},
  {id = "moddec",  min = 0.1,   max = 3,   step = 0.04},
  {id = "drive",   min = 0,     max = 1,   step = 0.02},
  {id = "wobble",  min = 0,     max = 1,   step = 0.02},
  {id = "fatness", min = 0,     max = 1,   step = 0.02},
  {id = "shimmer", min = 0,     max = 1,   step = 0.02},
}
local focus_index = 1

local arp_on = false
local arp_clock_id = nil
local arp_step_lit = 0
local k2_held, k2_turned, k3_held = false, false, false
local k3_turned = false
local k3_press = nil
local K3_LONG = 0.5   -- segundos manteniendo K3 para alternar el modo acorde

-- animación
local PULSE = 24
local pulse = {}          -- pulso por nombre de control
local flash = 0
local chord_flash = 0
local model_flash = 0
local hold_flash = 0
local last_t = nil

-- voces "simuladas" para que la pantalla respire igual que el sonido
local VS = {chord = nil, arp = nil}

local function pv(id) return params:get(id) end
local function note_to_hz(n) return musicutil.note_num_to_freq(n) end
local function bump(name) pulse[name] = PULSE end

local function four_tone_intervals(name)
  local iv = chord_intervals[name]
  if #iv >= 4 then return iv end
  return {iv[1], iv[2], iv[3], iv[1] + 12}
end

local function chord_name() return chord_types[pv("chord")] end

-- intervalos que suenan: el acorde, o solo la nota con el modo acorde apagado
local function chord_ivs()
  if pv("chord_on") == 1 then return {0} end
  return four_tone_intervals(chord_name())
end

local function chord_tone_hz(note)
  local f = {}
  for _, iv in ipairs(chord_ivs()) do
    f[#f + 1] = note_to_hz(note + iv)
  end
  for i = #f + 1, 4 do f[i] = 0 end   -- 0 = esa voz no suena
  return f
end

local comets = {}
local function spawn_comet(note, lv)
  if #comets > 20 then table.remove(comets, 1) end
  comets[#comets + 1] = {pc = note % 12, oct = note, r = 0, lv = lv}
end

-- ============================================================
-- sonido
-- ============================================================

local function sound_chord(note)
  local f = chord_tone_hz(note)
  -- modo simple con varias teclas: suenan todas juntas (hasta 4, las más agudas)
  if pv("chord_on") == 1 and #arp_keys > 1 then
    f = {}
    for i = math.max(1, #arp_keys - 3), #arp_keys do f[#f + 1] = note_to_hz(arp_keys[i]) end
    for i = #f + 1, 4 do f[i] = 0 end
  end
  voiced_sig = keys_sig()
  engine.noteOn(f[1], f[2], f[3], f[4], note_to_hz(note - 24), current_vel)
  VS.chord = {t0 = util.time(), note = note, vel = current_vel}
  flash = 1
end

local function release_chord_vs()
  if VS.chord and not VS.chord.t1 then VS.chord.t1 = util.time() end
end

local function step_order(pat, n)
  local t = {}
  if pat == 1 or pat == 7 then for i = 1, n do t[#t + 1] = i end
  elseif pat == 2 then for i = n, 1, -1 do t[#t + 1] = i end
  elseif pat == 3 then
    for i = 1, n do t[#t + 1] = i end
    for i = n - 1, 2, -1 do t[#t + 1] = i end
  elseif pat == 4 then for i = 1, n do t[#t + 1] = i; t[#t + 1] = i end
  elseif pat == 5 then for i = n, 1, -1 do t[#t + 1] = i; t[#t + 1] = i end
  end
  return t
end

-- notas del arpegio (en número MIDI); "arpa" recorre dos octavas
local function arp_notes()
  local t = {}
  for _, iv in ipairs(chord_ivs()) do t[#t + 1] = current_note + iv end
  if pv("chord_on") == 1 and #arp_keys > 0 then
    t = {}
    for i, n in ipairs(arp_keys) do t[i] = n end
  end
  if pv("arp_pattern") == 7 then
    local n = #t
    for i = 1, n do t[#t + 1] = t[i] + 12 end
  end
  return t
end

local function ext_clock_on()
  return last_midi_clock ~= nil and (util.time() - last_midi_clock) < CLOCK_TIMEOUT
end

local function ticks_per_step()
  local div = ({1, 2, 4, 8})[params:get("midi_clock_div")]
  return math.max(1, 24 * (1 / 16) * div * arp_rate_mult[pv("arp_rate")])
end

local function step_seconds()
  if ext_clock_on() and tick_sec then return tick_sec * ticks_per_step() end
  return clock.get_beat_sec() * (1 / 16) * arp_rate_mult[pv("arp_rate")]
end

local function beat_seconds()
  if ext_clock_on() and tick_sec then return tick_sec * 24 end
  return clock.get_beat_sec()
end

local function arp_note_dur(step_sec)
  local g = params:get("arp_gate")
  return util.clamp(step_sec * 0.25 * (32 ^ g), 0.03, 4)
end

local step_i = 1
local function arp_step()
  if current_note == nil then return end
  local notes = arp_notes()
  local pat = pv("arp_pattern")
  local idx, pos
  if pat == 6 then
    idx = math.random(1, #notes); pos = 1
  else
    local order = step_order(pat, #notes)
    pos = ((step_i - 1) % #order) + 1
    idx = order[pos]
  end
  step_i = step_i + 1
  local step_sec = step_seconds()
  local n = notes[idx]
  local vel = (pos == 1 and 1 or 0.72) * (0.55 + current_vel * 0.45)
  local pan = ((idx - 1) % 4 - 1.5) * 0.22
  local dur = arp_note_dur(step_sec)
  if params:get("arp_gate") >= 0.995 then
    engine.arpLegato(note_to_hz(n), vel, pan)
    if not (VS.arp and VS.arp.legato and not VS.arp.t1) then
      VS.arp = {t0 = util.time(), note = n, vel = vel, legato = true}
    else
      VS.arp.note = n; VS.arp.vel = vel
    end
  else
    engine.arpLegatoOff()
    engine.arpStep(note_to_hz(n), dur, vel, pan)
    VS.arp = {t0 = util.time(), note = n, vel = vel, pluck = true, dur = dur}
  end
  arp_step_lit = idx
  spawn_comet(n, 6 + vel * 9)
  flash = math.max(flash, 0.35 * vel)
end

local function arp_legato_off()
  engine.arpLegatoOff()
  if VS.arp and VS.arp.legato and not VS.arp.t1 then VS.arp.t1 = util.time() end
end

-- el loop termina solo (generación) en vez de clock.cancel: cancelar un
-- coroutine que ya estaba por despertarse tira "resume (thread expected)"
local arp_gen = 0
local function arp_loop(gen)
  while arp_on and current_note and gen == arp_gen do
    if ext_clock_on() then
      clock.sleep(0.05)
    else
      local quantum = (1 / 16) * arp_rate_mult[pv("arp_rate")]
      if params:get("clock_source") == 1 then clock.sync(quantum)
      else clock.sleep(clock.get_beat_sec() * quantum) end
      if arp_on and current_note and gen == arp_gen and not ext_clock_on() then arp_step() end
    end
  end
  if gen == arp_gen then
    arp_step_lit = 0
    arp_legato_off()
    arp_clock_id = nil
  end
end

local function start_arp_if_needed()
  if arp_clock_id == nil and current_note then
    engine.padOn(note_to_hz(current_note - 24))
    step_i = 1
    ext_ticks = 0
    arp_step()
    arp_gen = arp_gen + 1
    arp_clock_id = clock.run(arp_loop, arp_gen)
  end
end

local function stop_arp()
  if arp_clock_id ~= nil then
    arp_gen = arp_gen + 1
    arp_clock_id = nil
  end
  arp_step_lit = 0
  engine.padOff()
  arp_legato_off()
end

local function lowest_held()
  local m = nil
  for _, n in ipairs(held_stack) do
    if m == nil or n < m then m = n end
  end
  return m
end

local crackle_amt = 0
local function update_crackle()
  crackle_amt = util.clamp((#held_stack - 2) * 0.35, 0, 1)
  engine.crackle(0)   -- el ruido ya no crece con cada tecla (solo quedan las chispas)
end

-- con clock MIDI, algunos equipos repiten la nota apretada a tempo: el
-- soltar espera un poco y si vuelve la misma nota no se redispara
local release_id = nil

local function cancel_release()
  if release_id then clock.cancel(release_id); release_id = nil end
end

local function release_now()
  release_id = nil
  if #held_stack == 0 and not hold_on and current_note ~= nil then
    if arp_on then stop_arp() else engine.noteOff(); release_chord_vs() end
    current_note = nil
  end
end

local function release_grace()
  return util.clamp((tick_sec or 0.02) * 13, 0.05, 0.8)
end

local function on_note_on(note, vel)
  cancel_release()
  local prev = current_note
  local fresh = hold_on and #held_stack == 0 and prev ~= nil
  local added = hold_on and #held_stack > 0
  table.insert(held_stack, note)
  if added then
    -- con HOLD, una tecla más mientras hay otras apretadas se suma a lo
    -- retenido (aunque alguna ya se haya soltado)
    local dup = false
    for _, n in ipairs(arp_keys) do if n == note then dup = true end end
    if not dup then table.insert(arp_keys, note); table.sort(arp_keys) end
  else
    update_arp_keys()
  end
  -- modo acorde: manda la última tecla apretada (también si es más aguda);
  -- modo simple: suenan todas las apretadas y la más grave da el bajo
  local simple = pv("chord_on") == 1
  local low = simple and arp_keys[1] or note
  if low ~= prev or fresh or (simple and not arp_on and keys_sig() ~= voiced_sig) then
    current_note = low
    last_note = low
    current_vel = vel / 127
    if arp_on then
      if arp_clock_id == nil then start_arp_if_needed()
      else engine.padOn(note_to_hz(current_note - 24)) end
    else
      sound_chord(current_note)
    end
  end
  update_crackle()
end

local function on_note_off(note)
  for i = #held_stack, 1, -1 do
    if held_stack[i] == note then table.remove(held_stack, i); break end
  end
  -- con HOLD, soltar teclas no cambia nada: queda el acorde / las notas
  -- del arpegio tal como se apretaron
  if hold_on then update_crackle(); return end
  update_arp_keys()
  -- modo acorde: al soltar la que suena vuelve la última que sigue apretada;
  -- modo simple: soltar una de varias no redispara (cambia con la próxima tecla)
  local low = held_stack[#held_stack]
  if pv("chord_on") == 1 then low = (low ~= nil) and current_note or nil end
  if low == nil then
    if not hold_on and current_note ~= nil then
      if ext_clock_on() then
        cancel_release()
        local wait = release_grace()
        release_id = clock.run(function() clock.sleep(wait); release_now() end)
      else
        release_now()
      end
    end
  elseif low ~= current_note then
    current_note = low
    last_note = low
    if arp_on then engine.padOn(note_to_hz(current_note - 24))
    else sound_chord(current_note) end
  end
  update_crackle()
end

local function set_hold(on)
  hold_on = on
  hold_flash = PULSE
  if not on then cancel_release(); release_now() end
end

local function midi_event(data)
  local msg = midi.to_msg(data)
  if msg.type == "clock" then
    local now = util.time()
    if last_midi_clock then
      local d = now - last_midi_clock
      if d > 0.002 and d < 0.25 then
        tick_sec = tick_sec and (tick_sec * 0.9 + d * 0.1) or d
      end
    end
    last_midi_clock = now
    if arp_on and arp_clock_id and current_note then
      local tps = ticks_per_step()
      ext_ticks = ext_ticks + 1
      if ext_ticks >= tps then
        ext_ticks = math.min(ext_ticks - tps, tps - 1)
        arp_step()
      end
    end
    return
  elseif msg.type == "start" then
    ext_ticks = 0
    step_i = 1
    return
  elseif msg.type == "stop" or msg.type == "continue" then
    return
  end
  local ch = params:get("midi_channel")
  if ch ~= 0 and msg.ch ~= ch then return end
  if msg.type == "note_on" and msg.vel > 0 then
    on_note_on(msg.note, msg.vel)
  elseif msg.type == "note_off" or (msg.type == "note_on" and msg.vel == 0) then
    on_note_off(msg.note)
  end
end

-- ============================================================
-- parámetros (se guardan solos en data/chordexfm/estado.pset)
-- ============================================================

local STATE_FILE

local function add_params()
  params:add_separator("chordex_fm", "CHORDEX FM")
  params:add_number("midi_channel", "canal MIDI (0=todos)", 0, 16, 0)
  params:add_option("midi_clock_div", "divisor reloj MIDI", {"1x", "2x", "4x", "8x"}, 3)
  params:add_option("model", "modelo", FM.model_names, 1)
  params:set_action("model", function(v)
    engine.model(v - 1)
    -- elegir un modelo carga su algoritmo / ratio / feedback (como un preset);
    -- al cargar el estado guardado se respetan los valores guardados
    if not loading then
      local m = FM.models[v]
      params:set("alg", m.alg)
      params:set("ratio", ratio_index(m.ratio))
      params:set("fb", m.fb)
      params:set("moddec", m.moddec)
    end
  end)
  params:add_option("chord", "acorde", chord_types, 1)
  params:set_action("chord", function()
    if current_note and not arp_on then sound_chord(current_note) end
  end)
  params:add_option("chord_on", "modo acorde", {"no", "sí"}, 2)
  params:set_action("chord_on", function()
    if current_note and not arp_on and not loading then sound_chord(current_note) end
  end)
  params:add_option("arp_pattern", "patrón arp", arp_pattern_names, 1)
  params:add_option("arp_rate", "velocidad arp", arp_rate_names, 3)
  params:add_control("arp_gate", "gate arp (1=legato)", controlspec.new(0, 1, "lin", 0, 0.6, ""))

  params:add_separator("chordex_fm_fm", "FM")
  params:add_control("index", "índice", controlspec.new(0, 3, "lin", 0, 1.0, ""))
  params:set_action("index", function(v) engine.index(v) end)
  params:add_option("alg", "algoritmo", {"1", "2", "3", "4", "5", "6", "7", "8"}, 5)
  params:set_action("alg", function(v) engine.alg(v) end)
  params:add_option("ratio", "ratio op 2", FM.ratio_names, 2)
  params:set_action("ratio", function(v) engine.ratio(FM.ratios[v]) end)
  params:add_control("fb", "feedback op 4", controlspec.new(0, 1.5, "lin", 0, 0, ""))
  params:set_action("fb", function(v) engine.fb(v) end)
  params:add_control("moddec", "barrido", controlspec.new(0.1, 3, "lin", 0, 1, ""))
  params:set_action("moddec", function(v) engine.moddec(v) end)

  params:add_separator("chordex_fm_tono", "TONO")
  params:add_control("atk", "ataque", controlspec.new(0.001, 2, "lin", 0, 0.01, "s"))
  params:set_action("atk", function(v) engine.atk(v) end)
  params:add_control("rel", "decay", controlspec.new(0.02, 4, "lin", 0, 0.9, "s"))
  params:set_action("rel", function(v) engine.rel(v) end)
  params:add_control("drive", "distorsión", controlspec.new(0, 1, "lin", 0, 0.1, ""))
  params:set_action("drive", function(v) engine.drive(v) end)
  params:add_control("wobble", "wobble", controlspec.new(0, 1, "lin", 0, 0.2, ""))
  params:set_action("wobble", function(v) engine.wobble(v) end)
  params:add_control("fatness", "fatness", controlspec.new(0, 1, "lin", 0, 0.5, ""))
  params:set_action("fatness", function(v) engine.fatness(v) end)
  params:add_control("shimmer", "shimmer", controlspec.new(0, 1, "lin", 0, 0, ""))
  params:set_action("shimmer", function(v) engine.shimmer(v ^ 3) end)
  params:add_control("space", "hall", controlspec.new(0, 0.6, "lin", 0, 0.22, ""))
  params:set_action("space", function(v) engine.space(v) end)
  params:add_control("gain", "volumen", controlspec.new(0, 1.5, "lin", 0, 1.0, ""))
  params:set_action("gain", function(v) engine.gain(v) end)
end

-- ============================================================
-- init / controles
-- ============================================================

local screen_metro
local splash_start = nil
-- primero la intro U-MA de particulas (la de uma_splash/splash), despues CHORDEX
local SPLASH_IN, SPLASH_HOLD, SPLASH_FADE = 0.5, 1.6, 0.7
local uma_intro = include("lib/uma_splash_particles")
local uma_sound = include("lib/uma_splash") -- base de la intro, maneja el sonido

local function skip_splash()
  if splash_start and util.time() - splash_start < uma_intro.DUR then uma_sound.sound_off() end
  splash_start = nil
end

function init()
  midi_in = {}
  for i = 1, #midi.vports do
    midi_in[i] = midi.connect(i)
    midi_in[i].event = midi_event
  end

  add_params()
  STATE_FILE = norns.state.data .. "estado.pset"
  loading = true
  if util.file_exists(STATE_FILE) then params:read(STATE_FILE) end
  params:bang()
  loading = false

  uma_sound.sound_on(norns.state.path .. "lib/uma_particles.wav")
  splash_start = util.time()
  screen_metro = metro.init(function() redraw() end, 1 / 24, -1)
  screen_metro:start()
end

function cleanup()
  if STATE_FILE then params:write(STATE_FILE, "chordexfm") end
end

local function nudge(p, d)
  if p.opt then
    local n = #params:lookup_param(p.id).options
    params:set(p.id, util.clamp(pv(p.id) + (d > 0 and 1 or -1), 1, n))
  else
    params:set(p.id, util.clamp(pv(p.id) + d * p.step, p.min, p.max))
  end
end

function enc(n, d)
  if splash_start then return end
  if n == 1 then
    if k2_held then
      params:set("arp_gate", util.clamp(params:get("arp_gate") + d * 0.02, 0, 1))
      k2_turned = true
      bump("arp")
    elseif k3_held then
      k3_turned = true
      params:set("model", util.clamp(pv("model") + (d > 0 and 1 or -1), 1, #FM.models))
      model_flash = PULSE * 2
    else
      params:set("index", util.clamp(pv("index") + d * 0.03, 0, 3))
      bump("index")
    end
  elseif n == 2 then
    local dir = d > 0 and 1 or -1
    if k2_held then
      params:set("arp_pattern", ((pv("arp_pattern") - 1 + dir) % #arp_pattern_names) + 1)
      k2_turned = true
      bump("arp")
    elseif k3_held then
      k3_turned = true
      params:set("fb", util.clamp(pv("fb") + d * 0.03, 0, 1.5))
      bump("fb")
    else
      focus_index = ((focus_index - 1 + dir) % #P) + 1
      bump(P[focus_index].id)
    end
  elseif n == 3 then
    if k2_held then
      params:set("arp_rate", util.clamp(pv("arp_rate") + (d > 0 and 1 or -1), 1, #arp_rate_names))
      k2_turned = true
      bump("arp")
    elseif k3_held then
      k3_turned = true
      params:set("chord", util.clamp(pv("chord") + (d > 0 and 1 or -1), 1, #chord_types))
      chord_flash = PULSE * 2
    else
      nudge(P[focus_index], d)
      bump(P[focus_index].id)
    end
  end
end

function key(n, z)
  -- K1 llega acá solo si se mantiene (el toque corto abre el menú de norns)
  if n == 1 then
    if z == 1 then
      if splash_start then skip_splash() end
      set_hold(not hold_on)
    end
  elseif n == 2 then
    if z == 1 then
      k2_held = true; k2_turned = false
    else
      if splash_start then skip_splash()
      elseif k2_held and not k2_turned then
        arp_on = not arp_on
        bump("arp")
        if arp_on then
          engine.noteOff(); release_chord_vs()
          if current_note then start_arp_if_needed() end
        else
          stop_arp()
          if current_note then sound_chord(current_note) end
        end
      end
      k2_held = false
    end
  elseif n == 3 then
    k3_held = (z == 1)
    if z == 1 and splash_start then skip_splash() end
    if z == 1 then
      -- mantener K3 sin girar ningún encoder alterna el modo acorde
      k3_turned = false
      local press = util.time()
      k3_press = press
      clock.run(function()
        clock.sleep(K3_LONG)
        if k3_held and not k3_turned and k3_press == press then
          params:set("chord_on", 3 - params:get("chord_on"))
          chord_flash = PULSE * 2
        end
      end)
    end
  end
end

-- ============================================================
-- GRÁFICOS — acumulador por nivel (mismo esquema que Chordex80)
-- ============================================================

local G = {}
do
local bt, b1, b2, b3, b4, bn = {}, {}, {}, {}, {}, {}
for lv = 1, 15 do bt[lv] = {}; b1[lv] = {}; b2[lv] = {}; b3[lv] = {}; b4[lv] = {}; bn[lv] = 0 end

local function add(lv, ty, a, b, c, d)
  lv = math.floor(lv + 0.5)
  if lv < 1 then return end
  if lv > 15 then lv = 15 end
  local n = bn[lv] + 1
  bn[lv] = n
  bt[lv][n] = ty; b1[lv][n] = a; b2[lv][n] = b; b3[lv][n] = c; b4[lv][n] = d
end

function G.px(lv, x, y) add(lv, 0, x, y) end
function G.line(lv, x1, y1, x2, y2) add(lv, 3, x1, y1, x2, y2) end
function G.rect(lv, x, y, w, h) add(lv, 4, x, y, w, h) end
function G.circle(lv, x, y, r) add(lv, 5, x, y, r) end

function G.flush()
  local floor = math.floor
  for lv = 1, 15 do
    local n = bn[lv]
    if n > 0 then
      local T, A, B, C, D = bt[lv], b1[lv], b2[lv], b3[lv], b4[lv]
      screen.level(lv)
      local fills, strokes = false, false
      for k = 1, n do
        local ty = T[k]
        if ty == 0 then
          screen.rect(floor(A[k]), floor(B[k]), 1, 1); fills = true
        elseif ty == 4 then
          screen.rect(floor(A[k]), floor(B[k]), C[k], D[k]); fills = true
        else
          strokes = true
        end
      end
      if fills then screen.fill() end
      if strokes then
        for k = 1, n do
          local ty = T[k]
          if ty == 3 then
            screen.move(floor(A[k]) + 0.5, floor(B[k]) + 0.5)
            screen.line(floor(C[k]) + 0.5, floor(D[k]) + 0.5)
          elseif ty == 5 then
            screen.move(floor(A[k]) + 0.5 + C[k], floor(B[k]) + 0.5)
            screen.circle(floor(A[k]) + 0.5, floor(B[k]) + 0.5, C[k])
          end
        end
        screen.stroke()
      end
      bn[lv] = 0
    end
  end
end
end

-- ============================================================
-- el FM calculado en Lua (misma fórmula que el engine) para dibujar
-- ============================================================

local V = {}          -- estado del cálculo visual
do
  V.N = 64              -- puntos por ciclo (la mitad de cálculo; alcanza para la flor)
  V.y = {}
  V.e = {1, 1, 1, 1}
  V.mod = {0, 0, 0, 0}   -- profundidad de modulación que sale de cada op
  V.amp = 0
  V.P = 1
  V.spec = {}
  V.ph = {0, 0, 0, 0}    -- fase de los puntitos que giran en cada operador
  for k = 1, V.N do V.y[k] = 0 end
  for h = 1, 14 do V.spec[h] = 0 end
  V.tw = {}             -- tablas de la DFT por bin (se llenan a demanda)
end

local function ratios_now()
  local m = FM.models[pv("model")]
  return {m.r[1], FM.ratios[pv("ratio")], m.r[3], m.r[4]}
end

-- envolvente de un operador en el instante t (aprox. de la del engine)
local function op_env(i, vs, t, isc)
  if not vs then return 0 end
  local m = FM.models[pv("model")]
  local c = isc and 1 or 0
  local a = m.a[i] * (vs.pluck and 0.15 or 1) + pv("atk") * c + 0.002
  local d = m.d[i] * (isc and 1 or pv("moddec"))
  local s = m.s[i]
  local rel = vs.pluck and (vs.dur * 0.9 + 0.04) or pv("rel")
  local toff = vs.t1 or (vs.pluck and (vs.t0 + vs.dur * 0.45)) or nil
  local function held(tt)
    local x = tt - vs.t0
    if x < a then return x / a end
    return s + (1 - s) * math.exp(-3.5 * (x - a) / d)
  end
  if toff and t > toff then
    local x = (t - toff) / rel
    if x >= 1 then return 0 end
    return held(toff) * (1 - x) * (1 - x)
  end
  return held(t)
end

-- un número cercano a entero
local function near_int(x) return math.abs(x - math.floor(x + 0.5)) < 0.06 end

local function compute_fm(t)
  local vs = arp_on and VS.arp or VS.chord
  if arp_on and not vs then vs = VS.chord end
  local alg = FM.algs[pv("alg")]
  local m = FM.models[pv("model")]
  local r = ratios_now()
  local e = V.e
  for i = 1, 4 do e[i] = op_env(i, vs, t, alg.isc[i]) end

  local note = vs and vs.note or (last_note or 60)
  local fhz = note_to_hz(note)
  local ks = util.clamp((fhz / 261.6) ^ -0.3, 0.45, 1.5)
  local vel = vs and vs.vel or 0.6
  local I = pv("index") * (0.45 + vel * 0.75) * ks * 2.2

  -- cuántos ciclos del portador hacen falta para que la forma cierre
  local P = 1
  for _, pp in ipairs({1, 2, 4}) do
    local ok = true
    for i = 1, 4 do if not near_int(r[i] * pp) then ok = false end end
    if ok then P = pp; break end
  end
  V.P = P
  -- 64 puntos alcanzan; con 4 ciclos (campana) 96 y solo los armónicos bajo Nyquist, para que el espectro no se pase de Nyquist
  V.N = (P >= 4) and 96 or 64

  local l = m.l
  for i = 1, 4 do V.mod[i] = alg.isc[i] and 0 or l[i] * e[i] * I end
  local mods = alg.mods
  local fb = pv("fb")
  local dr = pv("drive")
  local dg = 1 + (dr ^ 1.4) * 9
  local csum = 0
  for _, c in ipairs(alg.car) do csum = csum + l[c] end
  csum = math.max(0.6, csum)

  local sin, tanh = math.sin, function(x) local e2 = math.exp(2 * x); return (e2 - 1) / (e2 + 1) end
  local N = V.N
  local o4prev = V.o4 or 0   -- el feedback sigue del cuadro anterior: alcanza una pasada
  local pm = {0, 0, 0, 0}
  local out = {0, 0, 0, 0}
  local peak = 0
  for pass = 2, 2 do
    for k = 1, N do
      local th = 2 * math.pi * P * (k - 1) / N
      pm[1], pm[2], pm[3] = 0, 0, 0
      local o4 = sin(r[4] * th + fb * o4prev)
      o4prev = o4
      out[4] = o4
      for i = 4, 2, -1 do
        if i < 4 then out[i] = sin(r[i] * th + pm[i]) end
        local tg = mods[i]
        if tg then
          local dep = out[i] * V.mod[i]
          for _, j in ipairs(tg) do pm[j] = pm[j] + dep end
        end
      end
      out[1] = sin(r[1] * th + pm[1])
      if pass == 2 then
        local y = 0
        for _, c in ipairs(alg.car) do y = y + out[c] * l[c] * e[c] end
        y = y / csum
        if dr > 0 then y = y * (1 - dr) + tanh(y * dg) * dr / (1 + dr * 0.8) end
        V.y[k] = y
        if math.abs(y) > peak then peak = math.abs(y) end
      end
    end
  end
  V.amp = peak
  V.o4 = o4prev

  -- el espectro se recalcula cada 2 cuadros (igual se suaviza)
  V.fr = (V.fr or 0) + 1
  if V.fr % 2 == 1 then return end

  -- espectro: el armónico h del portador cae en el bin h*P
  for h = 1, 14 do
    local b = h * P
    if b >= N / 2 then
      V.spec[h] = 0
    else
      local key = b * 1000 + N
      local tw = V.tw[key]
      if not tw then
        tw = {c = {}, s = {}}
        for k = 1, N do
          local a = 2 * math.pi * b * (k - 1) / N
          tw.c[k] = math.cos(a); tw.s[k] = math.sin(a)
        end
        V.tw[key] = tw
      end
      local re, im = 0, 0
      local cc, ss, y = tw.c, tw.s, V.y
      for k = 1, N do re = re + y[k] * cc[k]; im = im + y[k] * ss[k] end
      local mag = 2 * math.sqrt(re * re + im * im) / N
      V.spec[h] = V.spec[h] * 0.5 + mag * 0.5
    end
  end
end

-- ============================================================
-- dibujo
-- ============================================================

local CX, CY = 64, 32
local R0, RA = 15, 12
local rot = 0
local sparks = {}


local function pl(name) return (pulse[name] or 0) / PULSE end

-- panel izquierdo: el algoritmo vivo
local function draw_algorithm(t, dt)
  local a = pv("alg")
  local alg = FM.algs[a]
  local pos = FM.pos[a]
  local r = ratios_now()
  local ap = pl("alg")
  local rp = pl("ratio")
  local fp = pl("fb")
  local mp = pl("moddec")
  local ip = pl("index")

  -- bus de salida
  local bl = 2 + V.amp * 10
  G.line(bl, 2, 36, 28, 36)
  -- líneas de modulación + partículas viajando hacia el portador
  for j, tg in pairs(alg.mods) do
    local x1, y1 = pos[j][1], pos[j][2]
    local depth = util.clamp(V.mod[j] / 3, 0, 1)
    for _, i in ipairs(tg) do
      local x2, y2 = pos[i][1], pos[i][2]
      G.line(1 + depth * 4 + ap * 6 + ip * 3, x1, y1, x2, y2)
      local np = 1 + math.floor(depth * 3 + 0.5)
      local sp = 0.4 + 0.25 * math.log(1 + r[j])
      for q = 0, np - 1 do
        local u = (t * sp + q / np) % 1
        G.px(5 + depth * 10, x1 + (x2 - x1) * u, y1 + (y2 - y1) * u)
      end
    end
  end
  -- operadores
  for i = 1, 4 do
    local x, y = pos[i][1], pos[i][2]
    local e = V.e[i]
    local isc = alg.isc[i]
    V.ph[i] = (V.ph[i] + dt * (1.2 + 1.1 * math.log(1 + r[i]) * 2.2)) % (2 * math.pi)
    local lit = (i == 2 and rp > 0) and 15 or nil
    local cl = lit or (3 + e * 12)
    G.circle(cl, x, y, 3)
    if isc then
      -- portador: cae al bus
      G.line(2 + e * 6, x, y + 4, x, 35)
      G.rect(4 + e * 11, x - 1, y - 1, 3, 3)
    else
      local ph = V.ph[i]
      G.px(6 + e * 9, x + math.cos(ph) * 2, y + math.sin(ph) * 2)
    end
    if mp > 0 and not isc then G.circle(15 * mp, x, y, 5) end
  end
  -- feedback: rulo al lado del op 4 con un punto que da vueltas
  local fb = pv("fb")
  if fb > 0.02 or fp > 0 then
    local x, y = pos[4][1] + 5, pos[4][2] - 3
    local rr = 1 + fb * 1.4
    G.circle(3 + fb * 6 + fp * 8, x, y, rr)
    local ph = t * (2 + fb * 6)
    G.px(15, x + math.cos(ph) * rr, y + math.sin(ph) * rr)
  end
end

-- faders: 9 columnitas abajo a la izquierda
local function fader_norm(p)
  if p.opt then
    local n = #params:lookup_param(p.id).options
    return (pv(p.id) - 1) / (n - 1)
  end
  return (pv(p.id) - p.min) / (p.max - p.min)
end

-- indicador de 3x3 debajo de cada fader
local FADER_ICON = {
  atk     = {"..#", ".##", "###"},   -- rampa que sube
  rel     = {"#..", "##.", "###"},   -- rampa que cae
  ratio   = {"#.#", "#.#", "###"},   -- dos operadores (relación)
  alg     = {"#.#", ".#.", ".#."},   -- conexiones del algoritmo
  moddec  = {"#..", ".#.", "..#"},   -- barrido que se apaga
  drive   = {"#.#", ".#.", "#.#"},   -- chispa
  wobble  = {".#.", "#.#", ".#."},   -- tiembla
  fatness = {"##.", "###", ".##"},   -- dos ondas encimadas
  shimmer = {".#.", "###", ".#."},   -- destello
}

local function draw_faders()
  for i, p in ipairs(P) do
    local x = 1 + (i - 1) * 3
    local focused = (focus_index == i)
    local pp = pl(p.id)
    local lv = focused and 15 or (pp > 0 and 6 + 9 * pp or 6)
    G.line(focused and 3 or 1, x, 42, x, 55)
    local v = fader_norm(p)
    local cy = math.floor(54 - v * 12 + 0.5)
    G.rect(lv, x - (focused and 1 or 0), cy, focused and 3 or 2, 2)
    -- indicador (alternados en dos filas para que no se peguen)
    local low = (i % 2 == 0)
    local iy = low and 61 or 57
    local il = focused and 15 or math.floor(5 + 8 * pp + 0.5)
    if low then G.px(focused and 5 or 2, x, 57) G.px(focused and 5 or 2, x, 59) end
    local ic = FADER_ICON[p.id]
    for r = 1, 3 do
      local row = ic[r]
      for c = 1, 3 do
        if row:sub(c, c) == "#" then G.px(il, x - 2 + c, iy + r - 1) end
      end
    end
  end
end

-- la flor: forma de onda real en polar
local function draw_flower(t, dt)
  local N = V.N
  local fat = pv("fatness")
  local amp = V.amp
  local lv = 4 + 11 * math.min(1, amp * 1.4 + flash * 0.3)
  local ip = pl("index")
  local wob = pv("wobble")
  local rr = R0 + math.sin(t * 5.2) * wob * 0.8 * amp

  local function pt(k, off)
    local a = 2 * math.pi * (k - 1) / N + rot + off
    local rad = rr + RA * V.y[k]
    return CX + math.cos(a) * rad, CY + math.sin(a) * rad
  end
  -- fantasma (fatness): la misma flor corrida, respirando
  if fat > 0.02 then
    local off = fat * 0.12 * math.sin(t * 2.3) + fat * 0.05
    local px, py = pt(N, off)
    for k = 1, N, 2 do
      local x, y = pt(k, off)
      G.line(1 + fat * 3, px, py, x, y)
      px, py = x, y
    end
  end
  local px, py = pt(N, 0)
  for k = 1, N do
    local x, y = pt(k, 0)
    G.line(lv, px, py, x, y)
    px, py = x, y
  end
  -- anillo del índice al moverlo con E1: punteado en el borde máximo
  if ip > 0 then
    local rim = R0 + RA * 1.05
    local n = 40
    local idxf = pv("index") / 3
    for k = 1, n do
      local a = 2 * math.pi * k / n
      local on = (k / n) <= idxf
      G.px(on and 15 * ip or 3 * ip, CX + math.cos(a) * rim, CY + math.sin(a) * rim)
    end
  end
  -- envolvente de salida como un punto que gira lento en el borde
  rot = rot + dt * (0.08 + amp * 0.35)

  -- shimmer: chispas que suben desde el borde
  local sh = pv("shimmer")
  if sh > 0.02 and amp > 0.02 and math.random() < sh * 0.9 then
    local a = math.random() * 2 * math.pi
    sparks[#sparks + 1] = {a = a, r = R0 + RA * 0.6, v = 6 + math.random() * 8, life = 1}
  end
  for i = #sparks, 1, -1 do
    local s = sparks[i]
    s.r = s.r + s.v * dt
    s.life = s.life - dt * 0.9
    if s.life <= 0 or s.r > 40 then table.remove(sparks, i)
    else G.px(2 + s.life * 12, CX + math.cos(s.a) * s.r, CY + math.sin(s.a) * s.r - (1 - s.life) * 4) end
  end
  -- crackle: chispas sueltas alrededor
  if crackle_amt > 0 then
    for i = 1, math.floor(crackle_amt * 9) do
      local a = math.random() * 2 * math.pi
      local d = R0 + math.random() * (RA + 5)
      G.px(15, CX + math.cos(a) * d, CY + math.sin(a) * d)
    end
  end
end

-- el acorde en la rueda de 12 notas, en el centro de la flor
local function wheel_xy(pc, rad)
  local a = (pc / 12) * 2 * math.pi - math.pi / 2
  return CX + math.cos(a) * rad, CY + math.sin(a) * rad
end

local function draw_wheel(t, dt)
  local root = current_note or last_note
  local lit = current_note ~= nil
  local W = 7
  local tones = {}
  if root then
    for i, iv in ipairs(chord_ivs()) do
      tones[#tones + 1] = (root + iv) % 12
    end
  end
  for pc = 0, 11 do
    local x, y = wheel_xy(pc, W)
    G.px(2, x, y)
  end
  if #tones > 0 then
    local base = lit and 1 or 0.35
    -- polígono del acorde
    local sorted = {}
    for _, pc in ipairs(tones) do sorted[#sorted + 1] = pc end
    table.sort(sorted)
    for i = 1, #sorted do
      local a, b = sorted[i], sorted[i % #sorted + 1]
      if a ~= b then
        local x1, y1 = wheel_xy(a, W)
        local x2, y2 = wheel_xy(b, W)
        G.line((4 + 5 * V.amp) * base + chord_flash / PULSE * 6, x1, y1, x2, y2)
      end
    end
    for i, pc in ipairs(tones) do
      local x, y = wheel_xy(pc, W)
      if i == 1 then G.rect(15 * base, x - 1, y - 1, 2, 2)
      else G.px(11 * base, x, y) end
    end
  end
  -- cometas: cada nota del arpegio sale de su lugar en la rueda
  for i = #comets, 1, -1 do
    local c = comets[i]
    c.r = c.r + dt * 34
    if c.r > 32 then table.remove(comets, i)
    else
      local r0 = W + c.r
      local x1, y1 = wheel_xy(c.pc, r0)
      local x2, y2 = wheel_xy(c.pc, math.max(W, r0 - 4))
      G.line(c.lv * (1 - c.r / 34), x2, y2, x1, y1)
    end
  end
end

-- panel derecho: osciloscopio, espectro, arpegio
local function draw_right(t)
  local x0 = 98
  -- modelo: 10 puntos arriba
  for m = 1, #FM.models do
    G.rect(pv("model") == m and 12 or 2, x0 + 1 + (m - 1) * 2, 0, 1, 2)
  end
  -- retener: rombo de 3x3 arriba a la derecha
  local lk = hold_on and (current_note and 13 or 8) or 3
  lk = math.min(15, lk + hold_flash * 0.25)
  G.px(lk, 125, 0) G.px(lk, 124, 1) G.px(lk, 126, 1) G.px(lk, 125, 2)
  if hold_on then G.px(lk, 125, 1) end

  -- osciloscopio: un ciclo del portador
  local N, P = V.N, V.P
  local per = N / P
  local mid = 11
  G.line(1, x0, mid, 127, mid)
  local lv = 4 + 11 * math.min(1, V.amp * 1.5)
  local px, py
  for xx = 0, 29 do
    local k = math.floor(xx / 29 * (per - 1)) + 1
    local y = mid - V.y[k] * 7
    if px then G.line(lv, px, py, x0 + xx, y) end
    px, py = x0 + xx, y
  end

  -- espectro: 14 armónicos
  local base = 50
  for h = 1, 14 do
    local x = x0 + 1 + (h - 1) * 2
    local m = math.sqrt(V.spec[h]) * 26
    local hh = math.min(26, math.floor(m + 0.5))
    G.px(1, x, base)
    if hh > 0 then
      for y = 0, hh - 1 do
        local u = y / 26
        G.px(3 + 12 * (1 - u) * math.min(1, V.amp * 2 + 0.3), x, base - 1 - y)
      end
    end
  end

  -- patrón del arpegio: escalera de puntos
  local pat = pv("arp_pattern")
  local order
  if pat == 6 then
    order = {}
    for i = 1, 6 do order[i] = (math.floor(t * 4) * 7 + i * 5) % 4 + 1 end
  else
    order = step_order(pat, pat == 7 and 8 or 4)
  end
  local top = (pat == 7) and 8 or 4
  local ap = pl("arp")
  local blink = (math.floor(t * 6) % 2 == 0)
  local base_lv = k2_held and (blink and 15 or 8) or (arp_on and 6 + ap * 6 or 2 + ap * 8)
  local gw = math.min(3, math.floor(26 / #order))
  for i, idx in ipairs(order) do
    local x = x0 + 1 + (i - 1) * gw
    local y = 61 - (idx - 1) * (5 / (top - 1))
    local cur = arp_on and arp_step_lit > 0 and idx == arp_step_lit
    G.rect(cur and 15 or base_lv, x, math.floor(y), math.max(1, gw - 1), 1)
  end
  -- velocidad (1..4 puntitos) y gate (una rayita que se alarga)
  for i = 1, pv("arp_rate") do
    G.px(k2_held and 12 or (arp_on and 5 or 2), x0 + 1 + (i - 1) * 2, 63)
  end
  local gl = math.floor(params:get("arp_gate") * 18 + 0.5)
  if gl > 0 then G.line(k2_held and 10 or (arp_on and 4 or 1), x0 + 10, 63, x0 + 10 + gl, 63) end
end

-- dibujos de los modelos (aparecen al cambiar con K3 + E1)
local MODEL_ICON = {
  EPIANO = {
    "#####################",
    "#+++++++++++++++++++#",
    "#####################",
    "# ## ### ## ### ## ##",
    "# ## ### ## ### ## ##",
    "# ## ### ## ### ## ##",
    "#  #  #  #  #  #  # #",
    "#####################",
  },
  CAMPANA = {
    "         #         ",
    "       #####       ",
    "      #+++++#      ",
    "     #+++++++#     ",
    "     #+++++++#     ",
    "    #+++++++++#    ",
    "   #+++++++++++#   ",
    "  ###############  ",
    "         ##        ",
  },
  METAL = {
    "#                    ",
    "#                ### ",
    "##              #+++#",
    "#+##############++++#",
    "##    #  #  #   #+++#",
    "#     #  #  #    ### ",
    "#                    ",
  },
  CORO = {
    "  ...     ...     ... ",
    " .###.   .###.   .###.",
    " #+ +#   #+ +#   #+ +#",
    " # # #   # # #   # # #",
    " #+++#   #+++#   #+++#",
    "  ###     ###     ### ",
    " #####   #####   #####",
  },
  BAJO = {
    "        ###          ",
    "       #+++#         ",
    "##################+++",
    "#+++++++++++++++++#++",
    "##################+++",
    "       #+++#         ",
    "        ###          ",
  },
  ORGANO = {
    "  #  #  #  #  #  #  ",
    " ### # ### # ### #  ",
    " #+# # #+# # #+# #  ",
    " #+# # #+# # #+# #  ",
    " #+# # #+# # #+# #  ",
    "####################",
    "#..................#",
    "####################",
  },
  MARIMBA = {
    " ##  ##  ##  ##  ## ",
    " ##  ##  ##  ##  ## ",
    " ##  ##  ##  ##  ## ",
    " ++  ##  ##  ##  ## ",
    "     ++  ##  ##  ## ",
    "         ++  ##  ## ",
    "             ++  ## ",
    "                 ++ ",
  },
  CUERDAS = {
    "   ###   ",
    "  #+ +#  ",
    "   #+#   ",
    "  #+++#  ",
    " #+#+#+# ",
    " #+#+#+# ",
    "  #+++#  ",
    "   ###   ",
    "    #    ",
  },
  FLAUTA = {
    "                       ",
    "#######################",
    "#+ + #+ #+ #+ #+ #+++ #",
    "#######################",
    "   .  .                ",
    "  .  .                 ",
  },
  VIDRIO = {
    "  #######  ",
    "  #.....#  ",
    "   #+++#   ",
    "    #+#    ",
    "     #     ",
    "     #     ",
    "     #     ",
    "   #####   ",
  },
}
local ICON_LV = {["#"] = 15, ["+"] = 9, ["."] = 4}

local function draw_overlays()
  if model_flash > 0 then
    local a = math.min(1, model_flash / PULSE)
    local rows = MODEL_ICON[FM.model_names[pv("model")]]
    local w, h = #rows[1], #rows
    local x0, y0 = math.floor(CX - w / 2), math.floor(CY - h / 2)
    screen.level(0)
    screen.rect(x0 - 2, y0 - 2, w + 4, h + 4)
    screen.fill()
    for ch, l in pairs(ICON_LV) do
      local lv = math.floor(l * a + 0.5)
      if lv > 0 then
        screen.level(lv)
        for y = 1, h do
          local r = rows[y]
          for x = 1, w do
            if r:sub(x, x) == ch then screen.rect(x0 + x - 1, y0 + y - 1, 1, 1) end
          end
        end
        screen.fill()
      end
    end
  elseif chord_flash > 0 or k3_held then
    -- nombre del acorde, solo mientras se elige (K3)
    local root = current_note or last_note
    local txt = (root and note_names[(root % 12) + 1] or "") ..
      (chord_suffix[chord_name()] ~= "" and chord_suffix[chord_name()] or (root and "" or "maj"))
    -- modo acorde apagado: solo la nota (o "1" si todavía no se tocó nada)
    if pv("chord_on") == 1 then txt = root and note_names[(root % 12) + 1] or "1" end
    screen.font_face(1)
    screen.font_size(8)
    local w = screen.text_extents(txt)
    local a = k3_held and 1 or math.min(1, chord_flash / PULSE)
    screen.level(0)
    screen.rect(CX - w / 2 - 2, CY - 5, w + 4, 9)
    screen.fill()
    screen.level(math.floor(15 * a))
    screen.move(CX - w / 2, CY + 2)
    screen.text(txt)
  end
end

-- ---- splash ----
local function draw_splash(alpha)
  screen.clear()
  local lv = math.max(0, math.min(15, math.floor(15 * alpha)))
  screen.level(lv)
  screen.font_face(1)
  screen.font_size(16)
  local txt = "C H O R D E X"
  local w = screen.text_extents(txt)
  screen.move(64 - w / 2, 30)
  screen.text(txt)
  -- "FM" dibujado como una onda modulada debajo
  local t = util.time()
  local px, py
  for x = 0, 60 do
    local th = x / 60 * 2 * math.pi * 3
    local y = 42 + math.sin(th + 2.2 * math.sin(th * 2 + t * 3)) * 4
    if px then
      screen.move(px, py)
      screen.line(34 + x, y)
    end
    px, py = 34 + x, y
  end
  screen.stroke()
  screen.update()
end

local function tick(dt)
  for k, v in pairs(pulse) do pulse[k] = math.max(0, v - 1) end
  model_flash = math.max(0, model_flash - 1)
  chord_flash = math.max(0, chord_flash - 1)
  hold_flash = math.max(0, hold_flash - 1)
  flash = math.max(0, flash - dt * 3)
end

function redraw()
  local now = util.time()
  if splash_start then
    local e = now - splash_start
    if e < uma_intro.DUR then
      uma_intro.render(e)
      screen.update()
      return
    end
    e = e - uma_intro.DUR
    local t1 = SPLASH_IN
    local t2 = t1 + SPLASH_HOLD
    local t3 = t2 + SPLASH_FADE
    if e < t1 then draw_splash(e / SPLASH_IN) return
    elseif e < t2 then draw_splash(1) return
    elseif e < t3 then draw_splash(1 - (e - t2) / SPLASH_FADE) return
    else splash_start = nil end
  end

  local dt = last_t and math.min(0.2, now - last_t) or 1 / 24
  last_t = now
  tick(dt)
  compute_fm(now)

  screen.clear()
  draw_flower(now, dt)
  draw_wheel(now, dt)
  draw_algorithm(now, dt)
  draw_faders()
  draw_right(now)
  G.flush()
  draw_overlays()
  screen.update()
end
