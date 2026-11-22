extends Node3D
## Turno da Madrugada: Km 42 - Parte 1 (Godot 4.7, renderizador Compatibilidade)
## Modelos 3D (assets/models) e texturas (assets/textures) vem dos arquivos enviados; sons e itens simples sao gerados por codigo.

const SR := 22050
const TYPE_CPS := 32.0                       # velocidade da digitação das legendas (letras por segundo)
const QUALIDADE_ALTA := true                   # true = PC bom (sombras e imagem mais nítida); false = notebook fraco
const RESOLUCAO := 432.0                      # linhas da imagem, estilo VHS/Fears to Fathom (240 = bem pixelado, 360 = mais nítido, 1080 = sem efeito)
const MACIO := 0.6                            # quanto a imagem fica borrada/macia na horizontal (0.0 a 1.0)
const BLUR := "shader_type canvas_item;\nuniform sampler2D tela : hint_screen_texture, filter_linear_mipmap;\nvoid fragment(){\n float asp = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;\n vec2 res = vec2(VHS_RES * asp, VHS_RES);\n vec2 uv = (floor(SCREEN_UV * res) + 0.5) / res;\n vec2 px = vec2(1.0 / res.x, 0.0);\n vec3 c;\n c.r = textureLod(tela, uv + px * 0.6, 0.0).r;\n c.g = textureLod(tela, uv, 0.0).g;\n c.b = textureLod(tela, uv - px * 0.6, 0.0).b;\n vec3 c2 = textureLod(tela, uv + px * 1.2, 0.0).rgb * 0.25 + textureLod(tela, uv - px * 1.2, 0.0).rgb * 0.25 + c * 0.5;\n c = mix(c, c2, VHS_MACIO);\n float l = dot(c, vec3(0.299, 0.587, 0.114));\n c = mix(vec3(l), c, 0.8);\n c *= vec3(1.10, 0.98, 0.86);\n c = c * 0.9 + vec3(0.045, 0.035, 0.03);\n c *= 0.96 + 0.04 * sin(uv.y * res.y * 6.2831);\n COLOR = vec4(c, 1.0);\n}"
const VIGNETTE := "shader_type canvas_item;\nvoid fragment(){ float d = length(UV - vec2(0.5)); COLOR = vec4(0.0, 0.0, 0.0, smoothstep(0.35, 0.85, d) * 0.65); }"
const GRAIN_FORCA := 0.05                   # força do granulado (0.0 = sem granulado, 0.3 = bem forte)
const GRAIN_TAMANHO := 3.0                    # tamanho de cada "grão" em pixels (1 = fino, 3 = grosso)
const GRAIN := "shader_type canvas_item;\nfloat hash12(vec2 p){ vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }\nvoid fragment(){ vec2 p = floor(FRAGCOORD.xy / GRAIN_SIZE) + floor(TIME * 24.0) * vec2(17.0, 31.0); float n = hash12(p) - 0.5; COLOR = vec4(vec3(step(0.0, n)), abs(n) * GRAIN_FORCE * 2.0); }"
# ---- pastas de assets (carro, elevadores, rádio, bateria, caixa de ferramentas, chão e tijolos)
const MODEL_DIR := "res://assets/models/"
const TEX_DIR := "res://assets/textures/"
const TEXFILE := {"conc": "piso", "planks": "piso", "wall": "parede", "ceil": "teto"}

# ---- onde ficam as coisas
const CAR_BASE := Vector3(-3.0, 0.0, -2.5)     # centro do Fiat Uno e do elevador animado
const LIFT2_BASE := Vector3(3.2, 0.0, -2.5)    # elevador parado (vaga vazia)
const CAR_FRONT := Vector2(-3.0, 1.1)         # onde o jogador fica, na frente do carro
const BAT_SPOT := Vector3(0.38, 0.63, 1.7)   # lugar da bateria dentro do compartimento do motor
const CAR_TINT := Color.WHITE                  # cor extra do carro (Color.WHITE = cor original do modelo)

# ---- onde o jogador se agacha para calibrar cada pneu (na ordem)
const TIRE_SPOTS := [Vector2(-1.45, -0.73), Vector2(-1.45, -4.27), Vector2(-4.55, -4.27), Vector2(-4.55, -0.73)]

# ---- elevador animado
const LIFT_SCALE := 1.3                        # tamanho do elevador em relação ao modelo original
const LIFT_PAD_CENTER := Vector3(1.195, 0.02, -1.90)   # centro das plataformas no modelo original
const LIFT_UP_START := 9.5                     # segundo da animação "up" em que o carro começa a subir
const LIFT_DOWN_END := 12.5                    # segundo da animação "down" em que o carro chega embaixo
const LIFT_SPEED := 2.0                        # 2.0 = o dobro da velocidade original

# ---- janelas, floresta e o vulto do Larry
const WIN_Y0 := 1.2                            # parte de baixo das janelas
const WIN_Y1 := 2.5                            # parte de cima das janelas
const WIN_HALF := 1.2                          # metade da largura das janelas
const FOREST_POS := Vector3(0.0, -0.5, -25.5)  # onde fica a floresta (atrás do fundo da oficina)
const LARRY_SPOTS := [Vector3(5.3, -0.6, -8.55), Vector3(-4.7, -0.6, -8.55)]   # só a cabeça aparece na janela
const LARRY_FIRST := 25.0                      # segundos até a primeira aparição

var player: CharacterBody3D
var cam: Camera3D
var pitch := 0.0
var paused := true
var started := false
var over := false
var press_e := false
var t := 0.0
var step_acc := 0.0
var texcache := {}
var lamps := []
var flick_until := 0.0
var ghost: Node3D
var ghost_until := 0.0
var gate: Node3D
var hood: Node3D
var car_bat: Node3D
var car_bat2: Node3D
var engine: MeshInstance3D
var car_model := false
var car_root: Node3D
var uno: Node3D
var hood_pivot: Node3D
var bay_light: OmniLight3D
var lift_anim: AnimationPlayer
var lift_carriage: Node3D
var lift_rest_y := 1.0e9
var lift_state := 0            # 0 embaixo, 1 subindo, 2 em cima, 3 descendo
var lift_switch_pos := Vector2(-4.9, -3.0)
var lift_switch_3d := Vector3(-4.9, 1.0, -3.0)
var lift_switch_r := 0.6
var anim_up := ""
var anim_down := ""
var new_bat: Node3D
var clip: Node3D
var multi: Node3D
var galao: Node3D
var funil: Node3D
var held: Node3D
var head_mats := []
var step := 0
var prog := 0.0
var in_dep := false
var ghost_done := false
var car_state := {"oleo": false, "bateria": false, "pneus": false, "capo": false}
var steps := []

var l_obj: Label
var l_chk: RichTextLabel
var l_sub: Label
var l_hint: Label
var bar: ProgressBar
var overlay: Control
var ov_title: Label
var ov_text: Label
var ov_btn: Button
var sub_tween: Tween

var snd_creak: AudioStream
var snd_clack: AudioStream
var snd_step: AudioStream
var snd_gate: AudioStream
var snd_gate2: AudioStream
var snd_chime1: AudioStream
var snd_chime2: AudioStream
var snd_hiss: AudioStream
var snd_lift: AudioStream
var radio_bus := "Master"
var larry: Node3D
var tire_i := 0
var crouch := 0.0
var larry_tween: Tween
var larry_state := 0           # 0 escondido, 1 espiando, 2 sumindo
var larry_next := 25.0
var larry_until := 0.0
var larry_born := 0.0
var larry_spot := 0


func _ready() -> void:
	randomize()
	_make_env()
	_build_world()
	_build_player()
	_build_hud()
	_build_steps()
	_build_audio()
	_set_obj()
	_render_chk()
	_show_overlay("Turno da Madrugada: Km 42", "Parte 1: A rotina\n\nUma oficina antiga na beira da rodovia, cercada de mata fechada. Chove fino lá fora. O chefe não vai conseguir voltar, e você está sozinho no turno.\n\nW A S D: andar     Mouse: olhar     E: interagir     Shift: correr     F11: tela cheia     Esc: pausa\n\nElevador: aponte a mira para o motor do elevador e aperte E para subir ou descer o carro.", "Começar")


# ---------------------------------------------------------------- ambiente
func _make_env() -> void:
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.02, 0.02, 0.03)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.2, 0.2, 0.3)
	e.ambient_light_energy = 0.30
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.fog_enabled = true
	e.fog_light_color = Color(0.03, 0.03, 0.04)
	e.fog_density = 0.015
	e.glow_enabled = true
	we.environment = e
	add_child(we)


# ---------------------------------------------------------------- texturas e materiais
func _tex(kind: String) -> ImageTexture:
	if texcache.has(kind):
		return texcache[kind]
	var cfg := {
		"conc": [Color(0.40, 0.40, 0.42), 0.06, 0.22, 0.015, 0.9],
		"wall": [Color(0.42, 0.43, 0.47), 0.05, 0.15, 0.012, 0.8],
		"wood": [Color(0.44, 0.33, 0.20), 0.15, 0.30, 0.02, 0.5],
		"woodd": [Color(0.36, 0.29, 0.22), 0.15, 0.30, 0.02, 0.5],
		"paint": [Color(0.22, 0.38, 0.70), 0.20, 0.06, 0.02, 0.5],
		"rust": [Color(0.46, 0.46, 0.50), 0.08, 0.20, 0.02, 1.0],
		"planks": [Color(0.50, 0.38, 0.27), 0.12, 0.25, 0.02, 0.6],
		"crate": [Color(0.50, 0.42, 0.26), 0.12, 0.30, 0.02, 0.5],
	}
	var c: Array = cfg[kind]
	var base: Color = c[0]
	var n1 := FastNoiseLite.new()
	n1.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n1.frequency = c[1]
	n1.seed = randi()
	var n2 := FastNoiseLite.new()
	n2.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n2.frequency = c[3]
	n2.seed = randi()
	var i1: Image = n1.get_seamless_image(128, 128)
	var i2: Image = n2.get_seamless_image(128, 128)
	var img := Image.create(128, 128, false, Image.FORMAT_RGB8)
	for y in 128:
		for x in 128:
			var g: float = i1.get_pixel(x, y).r - 0.5
			var s: float = i2.get_pixel(x, y).r - 0.5
			var k: float = 1.0 + g * c[2] * 2.0 + minf(s, 0.0) * c[4] * 1.6
			var col := Color(base.r * k, base.g * k, base.b * k)
			if kind == "rust":
				var r: float = clampf(s * 4.0, 0.0, 1.0)
				col = col.lerp(Color(0.5 * k, 0.25 * k, 0.1 * k), r)
			elif kind == "planks":
				var row: int = y / 32
				col = col * (0.88 + 0.12 * sin(float(row) * 12.9))
				if y % 32 < 2:
					col = col * 0.35
			elif kind == "crate" and (y % 64 < 3):
				col = col * 0.5
			col.a = 1.0
			img.set_pixel(x, y, col)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	texcache[kind] = tex
	return tex


func _find_asset(dir: String, base: String, exts: Array) -> String:
	for e in exts:
		var p: String = dir + base + e
		if ResourceLoader.exists(p):
			return p
	return ""


func mat(kind: String, tint: Color = Color.WHITE, size: float = 4.0, rough: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.roughness = rough
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	var sc := 1.0 / size
	m.uv1_scale = Vector3(sc, sc, sc)
	var key: String = TEXFILE.get(kind, kind)
	if kind == "wall":
		m.uv1_scale = Vector3(1.0 / 7.2, 1.0 / 4.0, 1.0 / 7.2)   # painel de reboco: 7,2 m de largura x 4 m de altura
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var exts := [".jpg", ".jpeg", ".png"]
	var col := _find_asset(TEX_DIR, key + "_color", exts)
	if col != "":
		m.albedo_texture = load(col)
		var nrm := _find_asset(TEX_DIR, key + "_normal", exts)
		if nrm != "":
			m.normal_enabled = true
			m.normal_texture = load(nrm)
		var rgh := _find_asset(TEX_DIR, key + "_roughness", exts)
		if rgh != "":
			m.roughness = 1.0
			m.roughness_texture = load(rgh)
	else:
		m.albedo_texture = _tex(kind)
	return m


func flat(c: Color, rough: float = 0.9, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func lit(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	return m


# ---------------------------------------------------------------- helpers de geometria
func box(pos: Vector3, size: Vector3, m: Material, solid: bool = true, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	var p: Node = parent
	if p == null:
		p = self
	p.add_child(mi)
	if solid:
		_add_body(mi, size)
	return mi


func _add_body(target: Node, size: Vector3) -> void:
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	sb.add_child(cs)
	target.add_child(sb)


func solid_box(pos: Vector3, size: Vector3) -> void:
	var n := Node3D.new()
	n.position = pos
	add_child(n)
	_add_body(n, size)


func cyl(pos: Vector3, r_top: float, r_bot: float, h: float, m: Material, rot: Vector3 = Vector3.ZERO, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bot
	cm.height = h
	mi.mesh = cm
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = rot
	var p: Node = parent
	if p == null:
		p = self
	p.add_child(mi)
	return mi


func _sp(w: float, m: float) -> float:
	return signf(w) * pow(absf(w), m)


func _rmesh(size: Vector3, e1: float, e2: float, lat: int = 20, lon: int = 32) -> ArrayMesh:
	# superelipsoide: e = 1 vira elipsoide, e menor deixa a forma mais "quadrada"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := size * 0.5
	var pts := []
	for i in lat + 1:
		var phi := -PI / 2.0 + PI * float(i) / float(lat)
		var cp := 0.0
		if i != 0 and i != lat:
			cp = _sp(cos(phi), e1)
		var row := []
		for j in lon + 1:
			var th := TAU * float(j % lon) / float(lon)
			row.append(Vector3(half.x * cp * _sp(cos(th), e2), half.y * _sp(sin(phi), e1), half.z * cp * _sp(sin(th), e2)))
		pts.append(row)
	for i in lat:
		for j in lon:
			var a: Vector3 = pts[i][j]
			var b: Vector3 = pts[i + 1][j]
			var c: Vector3 = pts[i + 1][j + 1]
			var d: Vector3 = pts[i][j + 1]
			for v in [a, c, b, a, d, c]:
				st.add_vertex(v)
	st.generate_normals()
	return st.commit()


func rbox(pos: Vector3, size: Vector3, m: Material, e1: float = 0.5, e2: float = 0.5, solid: bool = true, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _rmesh(size, e1, e2)
	if m is BaseMaterial3D:
		(m as BaseMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.position = pos
	var p: Node = parent
	if p == null:
		p = self
	p.add_child(mi)
	if solid:
		_add_body(mi, size)
	return mi


func _aabb(n: Node) -> AABB:
	var out := AABB()
	var first := true
	var stack := [n]
	while stack.size() > 0:
		var c: Node = stack.pop_back()
		for ch in c.get_children():
			stack.append(ch)
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			var bb: AABB = mi.global_transform * mi.get_aabb()
			if first:
				out = bb
				first = false
			else:
				out = out.merge(bb)
	return out


func _model(base: String, target: float, auto_z: bool = false, extra: float = 0.0) -> Node3D:
	# carrega assets/models/<base>.glb, ajusta tamanho (maior lado = target) e apoia no chão
	var path := _find_asset(MODEL_DIR, base, [".glb", ".gltf"])
	if path == "":
		return null
	var res = load(path)
	if not (res is PackedScene):
		return null
	var inst := (res as PackedScene).instantiate() as Node3D
	if inst == null:
		return null
	var holder := Node3D.new()
	add_child(holder)
	holder.add_child(inst)
	inst.rotation_degrees.y = extra
	var bb := _aabb(inst)
	if auto_z and bb.size.x > bb.size.z:
		inst.rotation_degrees.y += 90.0
		bb = _aabb(inst)
	var big := maxf(bb.size.x, maxf(bb.size.y, bb.size.z))
	if big < 0.0001:
		holder.queue_free()
		return null
	var k := target / big
	inst.scale = Vector3(k, k, k)
	bb = _aabb(inst)
	inst.position -= Vector3(bb.get_center().x, bb.position.y, bb.get_center().z)
	remove_child(holder)
	return holder


func _make_prop(key: String) -> Node3D:
	match key:
		"oleo":
			return _prop_oil("20W-50", Color(0.86, 0.62, 0.10))
		"funil":
			return _prop_funnel()
		"bateria":
			var b := _baked("bateria")
			if b != null:
				return b
			return _prop_battery(false)
		"bateria_velha":
			return _prop_battery(true)
	return _prop_multi()


func _label3d(txt: String, size: int, pos: Vector3, parent: Node) -> void:
	var lb := Label3D.new()
	lb.text = txt
	lb.font_size = size
	lb.pixel_size = 0.0025
	lb.modulate = Color(0.08, 0.08, 0.08)
	lb.position = pos
	parent.add_child(lb)


func _prop_oil(_label: String = "", col: Color = Color(0.86, 0.62, 0.10)) -> Node3D:
	var n := Node3D.new()
	var cn := _baked("lata")
	if cn != null:
		n.add_child(cn)
		return n
	var plastic := flat(col, 0.3)
	var red := flat(Color(0.7, 0.1, 0.08), 0.4)
	rbox(Vector3(0, 0.19, 0), Vector3(0.3, 0.38, 0.2), plastic, 0.35, 0.3, false, n)
	rbox(Vector3(-0.08, 0.41, 0), Vector3(0.1, 0.06, 0.06), plastic, 0.5, 0.5, false, n)
	cyl(Vector3(0.08, 0.41, 0), 0.035, 0.035, 0.06, red, Vector3.ZERO, n)
	box(Vector3(0, 0.19, 0.101), Vector3(0.22, 0.2, 0.004), flat(Color(0.93, 0.92, 0.85)), false, n)
	box(Vector3(0, 0.275, 0.104), Vector3(0.22, 0.04, 0.004), red, false, n)
	_label3d("ÓLEO", 44, Vector3(0, 0.17, 0.108), n)
	return n


func _prop_funnel() -> Node3D:
	var n := Node3D.new()
	var red := flat(Color(0.75, 0.15, 0.1), 0.35)
	cyl(Vector3(0, 0.035, 0), 0.02, 0.02, 0.07, red, Vector3.ZERO, n)
	cyl(Vector3(0, 0.14, 0), 0.11, 0.02, 0.14, red, Vector3.ZERO, n)
	rbox(Vector3(0.12, 0.19, 0), Vector3(0.06, 0.03, 0.02), red, 0.6, 0.6, false, n)
	return n


func _prop_battery(old: bool) -> Node3D:
	var n := Node3D.new()
	var case_c := Color(0.1, 0.1, 0.12)
	var tp := Color(0.75, 0.1, 0.1)
	var tn := Color(0.15, 0.15, 0.17)
	var lab := Color(0.9, 0.75, 0.1)
	if old:
		case_c = Color(0.16, 0.15, 0.13)
		tp = Color(0.55, 0.68, 0.55)
		tn = Color(0.62, 0.72, 0.62)
		lab = Color(0.55, 0.5, 0.3)
	rbox(Vector3(0, 0.095, 0), Vector3(0.24, 0.19, 0.17), flat(case_c, 0.5), 0.25, 0.25, false, n)
	rbox(Vector3(0, 0.19, 0), Vector3(0.22, 0.02, 0.15), flat(Color(0.22, 0.22, 0.25), 0.5), 0.5, 0.5, false, n)
	cyl(Vector3(-0.07, 0.215, 0.04), 0.017, 0.017, 0.035, flat(tp, 0.4, 0.5), Vector3.ZERO, n)
	cyl(Vector3(0.07, 0.215, 0.04), 0.017, 0.017, 0.035, flat(tn, 0.4, 0.5), Vector3.ZERO, n)
	box(Vector3(0, 0.1, 0.0855), Vector3(0.18, 0.1, 0.003), flat(lab, 0.6), false, n)
	_label3d("12V\n60Ah", 36, Vector3(0, 0.1, 0.09), n)
	return n


func _prop_multi() -> Node3D:
	var n := Node3D.new()
	var mm := _baked("multimetro")
	if mm != null:
		mm.rotation_degrees.x = -90.0   # deitado, com o mostrador para cima
		mm.position.y = 0.085
		n.add_child(mm)
		return n
	rbox(Vector3(0, 0.02, 0), Vector3(0.09, 0.04, 0.17), flat(Color(0.88, 0.75, 0.19), 0.4), 0.4, 0.4, false, n)
	box(Vector3(0, 0.041, -0.04), Vector3(0.06, 0.004, 0.05), lit(Color(0.45, 0.6, 0.4)), false, n)
	cyl(Vector3(0, 0.045, 0.04), 0.022, 0.022, 0.01, flat(Color(0.1, 0.1, 0.1)), Vector3.ZERO, n)
	return n


func _shelf(pos: Vector3, rot: float, mission: bool = false, kit: bool = false) -> void:
	# estante de 3 andares com estoque; "rot" gira (0 = frente para +Z, 90 = frente para +X...)
	var h := Node3D.new()
	h.position = pos
	h.rotation_degrees.y = rot
	add_child(h)
	var sh := _baked("estante")
	if sh != null:
		h.add_child(sh)
	else:
		rbox(Vector3(0, 0.8, 0), Vector3(2.1, 1.6, 0.8), flat(Color(0.3, 0.3, 0.32)), 0.2, 0.2, false, h)
	_add_body_at(h, Vector3(0, 0.84, 0), Vector3(2.1, 1.68, 0.9))
	var oils := [["20W-50", Color(0.86, 0.62, 0.10)], ["15W-40", Color(0.20, 0.55, 0.28)], ["5W-30", Color(0.20, 0.42, 0.80)]]
	if mission:
		new_bat = _make_prop("bateria")
		new_bat.position = Vector3(0, 0.9, 0)
		h.add_child(new_bat)
		for bx in [-0.75, -0.4, 0.4, 0.75]:
			var eb := _prop_battery(false)
			eb.position = Vector3(bx, 0.9, 0)
			h.add_child(eb)
		for row in [1.62, 0.18]:
			for k in 6:
				var o: Array = oils[(k / 2) % 3]
				var ob := _prop_oil(o[0], o[1])
				ob.position = Vector3(-0.85 + k * 0.34, row, 0)
				h.add_child(ob)
	else:
		for k in 3:
			var o2: Array = oils[(k + int(absf(pos.x + pos.z))) % 3]
			var ob2: Node3D
			if kit and k == 0:
				galao = _make_prop("oleo")
				ob2 = galao
			elif kit and k == 1:
				funil = _make_prop("funil")
				ob2 = funil
			else:
				ob2 = _prop_oil(o2[0], o2[1])
			ob2.position = Vector3(-0.6 + k * 0.6, 1.62, 0)
			h.add_child(ob2)
		for bx2 in [-0.5, 0.5]:
			var eb2 := _prop_battery(false)
			eb2.position = Vector3(bx2, 0.9, 0)
			h.add_child(eb2)
		for cx2 in [-0.5, 0.5]:
			box(Vector3(cx2, 0.18 + 0.2, 0), Vector3(0.5, 0.4, 0.4), mat("crate", Color.WHITE, 1.0), false, h)


func _table(base: Vector3, size: Vector3, rot: float = 0.0) -> void:
	var m := _baked("mesa")
	if m == null:
		box(base + Vector3(0, size.y / 2.0, 0), size, mat("wood", Color.WHITE, 1.5))
		return
	m.position = base
	m.scale = Vector3(size.x / 2.09, size.y / 0.96, size.z / 1.11)
	m.rotation_degrees.y = rot
	add_child(m)
	var csz := size
	if absf(rot) > 45.0:
		csz = Vector3(size.z, size.y, size.x)
	solid_box(base + Vector3(0, size.y / 2.0, 0), csz)


func _fillet(cx: float, cz: float, dx: float, dz: float, r: float, m: Material) -> void:
	# faixa vertical côncava que arredonda o canto interno de uma sala (dx, dz = direção para dentro da sala)
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var n := 6
	for i in n + 1:
		var a := deg_to_rad(-90.0 - 90.0 * float(i) / float(n))
		var u := r + r * cos(a)
		var v := r + r * sin(a)
		var nu := -cos(a)
		var nv := -sin(a)
		for y in [0.0, 4.0]:
			verts.append(Vector3(cx + dx * u, y, cz + dz * v))
			norms.append(Vector3(dx * nu, 0.0, dz * nv).normalized())
	var idx := PackedInt32Array()
	for i in n:
		var k := i * 2
		idx.append_array([k, k + 1, k + 2, k + 1, k + 3, k + 2])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	if m is BaseMaterial3D:
		(m as BaseMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	add_child(mi)


func _set_layers(n: Node, bits: int) -> void:
	if n is VisualInstance3D:
		(n as VisualInstance3D).layers = bits
	for ch in n.get_children():
		_set_layers(ch, bits)


func _wall_h(x0: float, x1: float, z: float, holes: Array, wm: Material) -> void:
	# parede ao longo de X, com buracos para as janelas (centros em "holes")
	var cur := x0
	for hx in holes:
		var a: float = hx - WIN_HALF
		var b: float = hx + WIN_HALF
		if a > cur:
			box(Vector3((cur + a) / 2.0, 2.0, z), Vector3(a - cur, 4.0, 0.2), wm)
		box(Vector3(hx, WIN_Y0 / 2.0, z), Vector3(b - a, WIN_Y0, 0.2), wm)
		box(Vector3(hx, (WIN_Y1 + 4.0) / 2.0, z), Vector3(b - a, 4.0 - WIN_Y1, 0.2), wm)
		cur = b
	if x1 > cur:
		box(Vector3((cur + x1) / 2.0, 2.0, z), Vector3(x1 - cur, 4.0, 0.2), wm)


func _baked(base: String) -> Node3D:
	# carrega assets/models/<base>.glb (já no tamanho certo, base no chão, frente para +Z)
	var path := _find_asset(MODEL_DIR, base, [".glb", ".gltf"])
	if path == "":
		return null
	var res = load(path)
	if res is PackedScene:
		return (res as PackedScene).instantiate() as Node3D
	return null


func _find_anim(ap: AnimationPlayer, key: String) -> String:
	for n in ap.get_animation_list():
		var nm := String(n)
		if nm == key or nm.ends_with("|" + key):
			return nm
	return ""


func _tint(n: Node, c: Color) -> void:
	for ch in n.get_children():
		_tint(ch, c)
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			return
		for i in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(i)
			if m is StandardMaterial3D:
				var d := (m as StandardMaterial3D).duplicate() as StandardMaterial3D
				d.albedo_color = c
				d.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				mi.set_surface_override_material(i, d)


func _add_body_at(parent: Node, pos: Vector3, size: Vector3) -> void:
	var sb := StaticBody3D.new()
	sb.position = pos
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	sb.add_child(cs)
	parent.add_child(sb)


func _aim_at(p: Vector3, r: float, maxd: float) -> bool:
	var o := cam.global_position
	var d := -cam.global_transform.basis.z
	var v := p - o
	var t := v.dot(d)
	if t < 0.2 or t > maxd:
		return false
	return (v - d * t).length() < r


func _lift_toggle() -> void:
	if lift_anim == null or lift_state == 1 or lift_state == 3:
		return
	sfx(snd_lift, -8.0)
	lift_anim.speed_scale = LIFT_SPEED
	if lift_state == 0 and anim_up != "":
		lift_state = 1
		lift_anim.play(anim_up)
		lift_anim.seek(LIFT_UP_START, true)
	elif lift_state == 2 and anim_down != "":
		lift_state = 3
		lift_anim.play(anim_down)


func _lamp(pos: Vector3, energy: float, rng: float, shadow: bool) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = Color(0.97, 0.94, 0.86)   # branco levemente quente (lâmpada fluorescente)
	l.light_energy = energy
	l.omni_range = rng
	l.shadow_enabled = shadow or QUALIDADE_ALTA
	add_child(l)
	var fx := _baked("tubo")
	if fx != null:
		fx.position = Vector3(pos.x, 3.9, pos.z)
		add_child(fx)
	else:
		box(pos + Vector3(0, 0.45, 0), Vector3(0.4, 0.15, 0.4), lit(Color(1.0, 0.9, 0.7)), false)
	lamps.append([l, energy])


func _window(x: float, z: float) -> void:
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(2.4, 1.3)
	q.mesh = qm
	var gl := StandardMaterial3D.new()
	gl.albedo_color = Color(0.6, 0.75, 0.95, 0.07)
	gl.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gl.cull_mode = BaseMaterial3D.CULL_DISABLED
	gl.roughness = 0.1
	q.material_override = gl
	q.position = Vector3(x, 1.85, z)
	add_child(q)
	var fm := flat(Color(0.05, 0.05, 0.06))
	box(Vector3(x, 1.85, z + 0.03), Vector3(0.08, 1.3, 0.05), fm, false)
	box(Vector3(x, 1.85, z + 0.03), Vector3(2.4, 0.08, 0.05), fm, false)
	box(Vector3(x, 2.52, z + 0.03), Vector3(2.5, 0.08, 0.06), fm, false)
	box(Vector3(x, 1.18, z + 0.03), Vector3(2.5, 0.08, 0.06), fm, false)
	box(Vector3(x - 1.22, 1.85, z + 0.03), Vector3(0.08, 1.4, 0.06), fm, false)
	box(Vector3(x + 1.22, 1.85, z + 0.03), Vector3(0.08, 1.4, 0.06), fm, false)
	var l := OmniLight3D.new()
	l.position = Vector3(x, 1.75, z + 1.0)
	l.light_color = Color(0.42, 0.54, 0.82)
	l.light_energy = 0.5
	l.omni_range = 9.0
	add_child(l)


# ---------------------------------------------------------------- mundo
func _build_world() -> void:
	var conc := mat("conc", Color(0.92, 0.92, 0.95), 5.0, 0.8)
	var concb := mat("conc", Color(1.0, 0.90, 0.78), 5.0, 0.8)
	var planks := mat("planks", Color(0.95, 0.92, 0.88), 5.0, 0.8)
	var wall := mat("wall", Color(0.66, 0.62, 0.60), 4.0)
	var wood := mat("wood", Color.WHITE, 1.5)
	var woodd := mat("woodd", Color.WHITE, 1.5)
	var crate := mat("crate", Color.WHITE, 1.0)
	var paint := mat("paint", Color.WHITE, 2.5, 0.35)
	var rust := mat("rust", Color.WHITE, 2.0)
	var dark := flat(Color(0.1, 0.1, 0.11))
	var rubber := flat(Color(0.05, 0.05, 0.05), 0.95)
	var glass := flat(Color(0.05, 0.07, 0.1), 0.1, 0.3)
	var chrome := flat(Color(0.5, 0.5, 0.52), 0.35, 0.6)

	# pisos e tetos (salão 14 x 17, cômodos 6 x 8)
	var ceil_m: Material = dark
	if _find_asset(TEX_DIR, "teto_color", [".jpg", ".jpeg", ".png"]) != "":
		ceil_m = mat("ceil", Color(0.38, 0.36, 0.36), 2.5, 0.8)
	box(Vector3(0, -0.05, 0), Vector3(14, 0.1, 17), conc)
	box(Vector3(-10, -0.05, 0), Vector3(6, 0.1, 8), concb)
	box(Vector3(10, -0.05, 0), Vector3(6, 0.1, 8), planks)
	box(Vector3(0, 4.05, 0), Vector3(14, 0.1, 17), ceil_m, false)
	box(Vector3(-10, 4.05, 0), Vector3(6, 0.1, 8), ceil_m, false)
	box(Vector3(10, 4.05, 0), Vector3(6, 0.1, 8), ceil_m, false)

	# paredes
	_wall_h(-7.0, 7.0, -8.5, [-5.0, 5.0], wall)
	box(Vector3(-5.0, 2, 8.5), Vector3(4, 4, 0.2), wall)
	box(Vector3(5.0, 2, 8.5), Vector3(4, 4, 0.2), wall)
	box(Vector3(0, 3.6, 8.5), Vector3(6, 0.8, 0.2), wall)
	solid_box(Vector3(0, 2, 8.9), Vector3(6, 4, 0.4))
	for sx in [-7.0, 7.0]:
		box(Vector3(sx, 2, -5.0), Vector3(0.2, 4, 7.0), wall)
		box(Vector3(sx, 2, 5.0), Vector3(0.2, 4, 7.0), wall)
		box(Vector3(sx, 3.3, 0), Vector3(0.2, 1.4, 3), wall)
	for cx in [-10.0, 10.0]:
		_wall_h(cx - 3.0, cx + 3.0, -4.0, [cx], wall)
		box(Vector3(cx, 2, 4), Vector3(6, 4, 0.2), wall)
		box(Vector3(signf(cx) * 13.0, 2, 0), Vector3(0.2, 4, 8), wall)

	# só os batentes das portas ficam arredondados
	for sx in [-7.0, 7.0]:
		for sz in [-1.62, 1.62]:
			var jm := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.125
			cm.bottom_radius = 0.125
			cm.height = 2.6
			cm.radial_segments = 12
			jm.mesh = cm
			jm.material_override = wall
			jm.position = Vector3(sx, 1.3, sz)
			add_child(jm)

	# janelas
	for w in [[-5.0, -8.35], [5.0, -8.35], [-10.0, -3.85], [10.0, -3.85]]:
		_window(w[0], w[1])

	# luzes
	_lamp(Vector3(0, 3.4, -2), 1.1, 12.0, true)
	_lamp(Vector3(-10, 3.4, 0), 0.65, 8.0, false)
	_lamp(Vector3(10, 3.4, 0), 0.75, 8.0, false)
	_lamp(Vector3(0, 3.4, 5.5), 0.75, 8.0, false)   # perto do portão de entrada

	# detalhes do teto da garagem
	for z in [-5.0, 0.0, 5.0]:
		box(Vector3(0, 3.85, z), Vector3(14, 0.2, 0.3), dark, false)
	cyl(Vector3(0, 3.55, -8.0), 0.1, 0.1, 14.0, flat(Color(0.25, 0.25, 0.28), 0.5, 0.6), Vector3(0, 0, 90))

	# portão de rolo (aberto = acima do teto) e botão
	gate = box(Vector3(0, 5.9, 8.35), Vector3(6, 3.2, 0.12), rust, false)
	for i in 8:
		box(Vector3(0, -1.5 + i * 0.4, 0), Vector3(6, 0.04, 0.14), flat(Color(0.2, 0.2, 0.22)), false, gate)
	var btn := _baked("botao")
	if btn != null:
		btn.position = Vector3(4.5, 1.23, 8.36)
		add_child(btn)
	else:
		box(Vector3(4.5, 1.3, 8.38), Vector3(0.5, 0.5, 0.05), flat(Color(0.1, 0.1, 0.1)), false)
		box(Vector3(4.5, 1.3, 8.32), Vector3(0.25, 0.25, 0.08), lit(Color(0.8, 0.12, 0.1)), false)

	# ---- Cadillac Eldorado (sobre o elevador animado). O capô abre (nó HoodPivot do modelo).
	car_root = Node3D.new()
	car_root.position = CAR_BASE
	add_child(car_root)
	uno = _baked("cadillac")
	if uno != null:
		car_root.add_child(uno)
		if CAR_TINT != Color.WHITE:
			_tint(uno, CAR_TINT)
	else:
		rbox(Vector3(0, 0.7, 0.1), Vector3(1.8, 0.9, 3.8), paint, 0.5, 0.45, false, car_root)
	hood_pivot = null
	if uno != null:
		hood_pivot = uno.find_child("HoodPivot", true, false) as Node3D
	# compartimento do motor, visível quando o capô abre
	bay_light = OmniLight3D.new()
	bay_light.position = Vector3(0, 1.5, 2.0)
	bay_light.light_color = Color(1.0, 0.92, 0.8)
	bay_light.light_energy = 1.6
	bay_light.omni_range = 3.0
	bay_light.visible = false
	car_root.add_child(bay_light)
	box(Vector3(0, 0.6, 2.0), Vector3(1.3, 0.06, 1.3), flat(Color(0.04, 0.04, 0.05)), false, car_root)
	box(Vector3(0, 0.67, 2.05), Vector3(0.7, 0.2, 0.72), flat(Color(0.14, 0.15, 0.17), 0.55, 0.6), false, car_root)
	box(Vector3(-0.38, 0.69, 1.7), Vector3(0.22, 0.12, 0.2), flat(Color(0.1, 0.1, 0.12), 0.5, 0.5), false, car_root)
	_add_body_at(car_root, Vector3(0, 0.72, 0.0), Vector3(2.0, 1.44, 5.8))
	# as baterias do carro ficam guardadas fora de vista (o capô ainda não abre)
	car_bat = _make_prop("bateria_velha")
	car_bat.position = BAT_SPOT
	car_bat.scale = Vector3.ONE * 1.7
	car_root.add_child(car_bat)
	car_bat2 = _make_prop("bateria")
	car_bat2.position = BAT_SPOT
	car_bat2.scale = Vector3.ONE * 1.7
	car_bat2.visible = false
	car_root.add_child(car_bat2)

	# ---- elevador com animação (sobe e desce o carro)
	var lift := _baked("elevador_animado")
	if lift != null:
		var lift_basis := Basis(Vector3.UP, deg_to_rad(-90.0)) * Basis.from_scale(Vector3.ONE * LIFT_SCALE)
		lift.transform = Transform3D(lift_basis, CAR_BASE + lift_basis * (-LIFT_PAD_CENTER))
		add_child(lift)
		var aps := lift.find_children("*", "AnimationPlayer", true, false)
		if aps.size() > 0:
			lift_anim = aps[0] as AnimationPlayer
			anim_up = _find_anim(lift_anim, "up")
			anim_down = _find_anim(lift_anim, "down")
			lift_anim.speed_scale = LIFT_SPEED
			if anim_up != "":
				lift_anim.play(anim_up)
				lift_anim.seek(LIFT_UP_START, true)
				lift_anim.pause()
		lift_carriage = lift.find_child("lift_lift_0", true, false) as Node3D
		var sw := lift.find_child("switch_switch_0", true, false) as MeshInstance3D
		if sw != null:
			var sc: Vector3 = sw.global_transform * sw.get_aabb().get_center()
			lift_switch_pos = Vector2(sc.x, sc.z)
			lift_switch_3d = sc
			var wsz: Vector3 = sw.get_aabb().size * sw.global_transform.basis.get_scale()
			lift_switch_r = clampf(maxf(maxf(absf(wsz.x), absf(wsz.y)), absf(wsz.z)) * 0.5 + 0.2, 0.45, 0.9)
		else:
			lift_switch_pos = Vector2(CAR_BASE.x - 1.9, CAR_BASE.z)
		for sx in [-1.0, 1.0]:
			solid_box(CAR_BASE + Vector3(sx * 1.586, 1.2, 0.0), Vector3(0.5, 2.4, 0.55))

	# ---- elevador parado (vaga vazia ao lado)
	var lift2 := _baked("elevador_parado")
	if lift2 != null:
		lift2.position = LIFT2_BASE
		add_child(lift2)
		var cc := _baked("carro_coberto")
		if cc != null:
			cc.position = LIFT2_BASE
			add_child(cc)
			solid_box(LIFT2_BASE + Vector3(0, 0.73, 0), Vector3(1.8, 1.46, 4.4))
		for sx in [-1.0, 1.0]:
			solid_box(LIFT2_BASE + Vector3(sx * 1.32, 1.25, 0.0), Vector3(0.5, 2.5, 0.5))

	# garagem: bancada, armários, pneus, caixas, quadro, estantes
	_table(Vector3(-5.0, 0.0, -7.8), Vector3(2.4, 0.9, 1.1))
	clip = _baked("prancheta")
	if clip != null:
		clip.position = Vector3(-5.7, 0.9, -7.8)
		clip.rotation_degrees.y = 20.0
		add_child(clip)
	else:
		clip = box(Vector3(-5.7, 0.93, -7.8), Vector3(0.35, 0.03, 0.25), flat(Color(0.85, 0.85, 0.78)), false)
	# folha de papel com escrita borrada em cima da prancheta
	var pp_img := Image.create(24, 32, false, Image.FORMAT_RGBA8)
	pp_img.fill(Color(0.88, 0.86, 0.78))
	var pp_rng := RandomNumberGenerator.new()
	pp_rng.seed = 42
	for pp_row in range(3, 30, 3):
		var pp_x := 3
		var pp_maxx := 20 - (6 if pp_row > 24 else 0)
		while pp_x < pp_maxx:
			var pp_seg := pp_rng.randi_range(2, 6)
			for xx in range(pp_x, mini(pp_x + pp_seg, pp_maxx)):
				pp_img.set_pixel(xx, pp_row, Color(0.18, 0.18, 0.22))
				if pp_row == 3:
					pp_img.set_pixel(xx, pp_row + 1, Color(0.18, 0.18, 0.22))
			pp_x += pp_seg + 1
	var pp_mat := StandardMaterial3D.new()
	pp_mat.albedo_texture = ImageTexture.create_from_image(pp_img)
	pp_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	pp_mat.roughness = 1.0
	var pp_sheet := MeshInstance3D.new()
	var pp_mesh := BoxMesh.new()
	pp_mesh.size = Vector3(0.17, 0.004, 0.25)
	pp_sheet.mesh = pp_mesh
	pp_sheet.material_override = pp_mat
	pp_sheet.position = Vector3(-5.7, 0.9 + 0.046, -7.8)
	pp_sheet.rotation_degrees.y = 20.0
	add_child(pp_sheet)
	multi = _make_prop("multi")
	multi.position = Vector3(-4.3, 0.9, -7.8)
	multi.scale = Vector3.ONE * 1.8
	add_child(multi)
	box(Vector3(-5.3, 0.95, -7.9), Vector3(0.4, 0.1, 0.15), flat(Color(0.6, 0.12, 0.12)), false)
	for cz in [5.05, 6.7]:
		var cl := _baked("armario")
		if cl != null:
			cl.position = Vector3(-6.6, 0.0, cz)
			cl.rotation_degrees.y = 90.0
			add_child(cl)
			solid_box(Vector3(-6.6, 1.11, cz), Vector3(0.8, 2.22, 1.63))
		else:
			box(Vector3(-6.6, 1.0, cz), Vector3(0.8, 2.0, 1.6), woodd)
	for tp in [Vector3(5.6, 0.0, 6.8), Vector3(6.35, 0.0, 7.45), Vector3(4.85, 0.0, 7.45)]:
		for i in 5:
			var ts := _baked("pneu")
			if ts != null:
				ts.position = tp + Vector3(randf_range(-0.03, 0.03), i * 0.14, randf_range(-0.03, 0.03))
				ts.rotation_degrees.y = randf_range(0.0, 360.0)
				add_child(ts)
			else:
				var tm := MeshInstance3D.new()
				var tor := TorusMesh.new()
				tor.inner_radius = 0.2
				tor.outer_radius = 0.5
				tm.mesh = tor
				tm.material_override = rubber
				tm.position = tp + Vector3(0, 0.15 + i * 0.14, 0)
				add_child(tm)
		solid_box(tp + Vector3(0, 0.35, 0), Vector3(0.75, 0.7, 0.75))
	box(Vector3(-5.0, 0.4, 7.9), Vector3(0.8, 0.8, 0.8), crate)
	box(Vector3(-4.1, 0.4, 7.9), Vector3(0.8, 0.8, 0.8), crate)
	var board := box(Vector3(0.6, 2.2, -8.38), Vector3(2.2, 1.3, 0.04), flat(Color(0.7, 0.68, 0.58)), false)
	var lb := Label3D.new()
	lb.text = "REGRAS DA OFICINA\n\nProibido abandonar a\noficina durante o\nturno solo."
	lb.font_size = 40
	lb.pixel_size = 0.0035
	lb.modulate = Color(0.1, 0.1, 0.1)
	lb.position = Vector3(0, 0, 0.03)
	board.add_child(lb)

	# compressor de ar embaixo do quadro de avisos
	var comp := _baked("compressor")
	if comp != null:
		comp.position = Vector3(0.6, 0.0, -8.14)
		add_child(comp)
		solid_box(Vector3(0.6, 0.56, -8.14), Vector3(1.6, 1.12, 0.5))

	# caixa de ferramentas (guarda as chaves), encostada na parede dos fundos
	var chest := _baked("caixa_ferramentas")
	_table(Vector3(2.7, 0.0, -8.0), Vector3(1.5, 0.9, 0.8))
	if chest != null:
		chest.position = Vector3(2.7, 0.9, -8.05)
		add_child(chest)

	# quadro de ferramentas (pegboard) na parede, acima da caixa
	var peg := box(Vector3(2.7, 2.45, -8.38), Vector3(1.7, 0.9, 0.04), flat(Color(0.33, 0.25, 0.18)), false)
	var steel := flat(Color(0.5, 0.52, 0.56), 0.5, 0.6)
	var peg_dark := flat(Color(0.16, 0.16, 0.18), 0.6, 0.5)
	var peg_wood := flat(Color(0.4, 0.26, 0.14))
	var yellow := flat(Color(0.75, 0.6, 0.12))
	var redh := flat(Color(0.6, 0.1, 0.08))
	# chaves de boca (3 tamanhos)
	for i in 3:
		var wx := -0.7 + i * 0.16
		var wl := 0.5 - i * 0.07
		box(Vector3(wx, 0.05, 0.035), Vector3(0.035, wl, 0.015), steel, false, peg)
		box(Vector3(wx, 0.05 + wl / 2.0, 0.035), Vector3(0.09, 0.07, 0.015), steel, false, peg)
	# martelo
	box(Vector3(-0.15, 0.0, 0.035), Vector3(0.04, 0.5, 0.025), peg_wood, false, peg)
	box(Vector3(-0.15, 0.27, 0.035), Vector3(0.16, 0.07, 0.03), peg_dark, false, peg)
	# chaves de fenda
	for i in 3:
		var sx := 0.05 + i * 0.1
		box(Vector3(sx, 0.08, 0.035), Vector3(0.015, 0.32, 0.012), steel, false, peg)
		box(Vector3(sx, -0.14, 0.04), Vector3(0.04, 0.14, 0.03), yellow if i != 1 else redh, false, peg)
	# alicates
	for i in 2:
		var px := 0.5 + i * 0.17
		box(Vector3(px, 0.1, 0.035), Vector3(0.07, 0.2, 0.015), steel, false, peg)
		box(Vector3(px - 0.02, -0.12, 0.04), Vector3(0.025, 0.17, 0.025), redh, false, peg)
		box(Vector3(px + 0.02, -0.12, 0.04), Vector3(0.025, 0.17, 0.025), redh, false, peg)

	# (as estantes ficam só no depósito, à esquerda)

	# depósito (esquerda): estante da bateria nova + estantes pelas paredes
	_shelf(Vector3(-12.45, 0.0, 0.0), 90.0, true)
	_shelf(Vector3(-12.45, 0.0, -2.8), 90.0, false, true)   # estoque com o galão e o funil
	_shelf(Vector3(-12.45, 0.0, 2.8), 90.0)
	_shelf(Vector3(-10.0, 0.0, 3.55), 180.0)
	box(Vector3(-7.9, 0.5, 3.0), Vector3(1, 1, 1), crate)
	box(Vector3(-7.9, 1.45, 3.0), Vector3(0.9, 0.9, 0.9), crate)
	cyl(Vector3(-8.2, 0.5, -3.1), 0.5, 0.5, 1.0, flat(Color(0.17, 0.23, 0.3), 0.5, 0.5))
	solid_box(Vector3(-8.2, 0.5, -3.1), Vector3(1, 1, 1))

	# recepção (direita)
	_table(Vector3(12.3, 0.0, -2.05), Vector3(2.4, 0.9, 1.1), 90.0)
	var rad := _baked("radio")
	if rad != null:
		rad.position = Vector3(12.3, 0.9, -2.05)
		rad.rotation_degrees.y = -78.0
		rad.scale = Vector3.ONE * 1.8
		add_child(rad)
	else:
		rbox(Vector3(12.3, 1.04, -2.05), Vector3(0.5, 0.28, 0.2), flat(Color(0.25, 0.16, 0.1)), 0.35, 0.35, false)
		box(Vector3(12.3, 1.06, -2.05), Vector3(0.14, 0.06, 0.01), lit(Color(0.9, 0.6, 0.2)), false)
	var sofa := _baked("sofa")
	if sofa != null:
		sofa.position = Vector3(10.3, 0.0, 3.2)
		sofa.rotation_degrees.y = 180.0
		add_child(sofa)
		solid_box(Vector3(10.3, 0.5, 3.2), Vector3(2.8, 1.0, 1.35))
	else:
		box(Vector3(10.3, 0.4, 3.2), Vector3(3, 0.8, 1.2), flat(Color(0.29, 0.19, 0.25)))
	var gab := _baked("gabinete")
	if gab != null:
		gab.position = Vector3(12.3, 0.0, 0.0)
		gab.rotation_degrees.y = 180.0
		add_child(gab)
		solid_box(Vector3(12.3, 1.0, 0.0), Vector3(1.2, 2.0, 1.15))
	else:
		box(Vector3(12.55, 1.0, 0), Vector3(0.8, 2.0, 3.0), flat(Color(0.23, 0.23, 0.23), 0.6, 0.4))

	# ---- lado de fora: chão, floresta (só para ser vista pelas janelas) e luar fraco
	box(Vector3(0, -0.2, -7.5), Vector3(90, 0.1, 9.0), flat(Color(0.05, 0.06, 0.04), 0.95), false)
	var fl := _baked("floresta")
	if fl != null:
		fl.position = FOREST_POS
		add_child(fl)
		_tint(fl, Color(0.30, 0.36, 0.52))   # noite: mata azulada e escura
		_set_layers(fl, 2)
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.65, 0.95)
	moon.light_energy = 0.45
	moon.light_cull_mask = 2
	moon.rotation_degrees = Vector3(-50, 20, 0)
	add_child(moon)

	# ---- calçada, rua e poste na frente da oficina (para o lado de fora não ficar preto)
	var conc2 := mat("conc", Color(0.62, 0.62, 0.66), 5.0, 0.8)
	box(Vector3(0, -0.04, 11.5), Vector3(14, 0.08, 6), conc2, false)            # calçada
	box(Vector3(0, -0.02, 14.6), Vector3(14, 0.14, 0.3), conc2, false)          # meio-fio
	box(Vector3(0, -0.13, 21.0), Vector3(60, 0.06, 12), flat(Color(0.05, 0.05, 0.06), 0.9), false)   # rua
	for k in 8:
		box(Vector3(-10.5 + k * 3.0, -0.095, 21.0), Vector3(1.6, 0.01, 0.2), flat(Color(0.75, 0.65, 0.2), 0.8), false)
	box(Vector3(0, -0.2, 40.0), Vector3(120, 0.1, 50), flat(Color(0.04, 0.05, 0.04), 0.95), false)    # terreno além da rua
	box(Vector3(0, -0.2, 8.0), Vector3(120, 0.1, 6), flat(Color(0.04, 0.05, 0.04), 0.95), false)
	var pole := Node3D.new()
	pole.position = Vector3(5.5, 0.0, 13.2)
	add_child(pole)
	cyl(Vector3(0, 2.0, 0), 0.06, 0.08, 4.0, flat(Color(0.12, 0.12, 0.13), 0.5, 0.5), Vector3.ZERO, pole)
	box(Vector3(-0.5, 4.0, 0), Vector3(1.1, 0.08, 0.12), flat(Color(0.12, 0.12, 0.13), 0.5, 0.5), false, pole)
	box(Vector3(-1.0, 3.93, 0), Vector3(0.4, 0.1, 0.25), lit(Color(1.0, 0.85, 0.6)), false, pole)
	var pl := OmniLight3D.new()
	pl.position = Vector3(-1.0, 3.6, 0)
	pl.light_color = Color(1.0, 0.82, 0.55)
	pl.light_energy = 1.6
	pl.omni_range = 13.0
	pole.add_child(pl)

	# ---- chuva do lado de fora (partículas), atrás da oficina e na frente
	# (centro, tamanho, quantidade) -- todas ficam FORA do prédio (salão 14x17 e cômodos 6x8)
	var rain_zones := [
		[Vector3(0, 7.0, -14.5), Vector3(22.0, 0.1, 5.7), 250],   # atrás
		[Vector3(0, 7.0, 15.0), Vector3(22.0, 0.1, 6.0), 250],    # na frente
		[Vector3(-18.0, 7.0, 0), Vector3(4.8, 0.1, 14.0), 120],   # lado esquerdo
		[Vector3(18.0, 7.0, 0), Vector3(4.8, 0.1, 14.0), 120],    # lado direito
		[Vector3(-10.0, 7.0, -6.4), Vector3(2.9, 0.1, 2.0), 40],  # cantos entre o salão e os cômodos
		[Vector3(10.0, 7.0, -6.4), Vector3(2.9, 0.1, 2.0), 40],
		[Vector3(-10.0, 7.0, 6.4), Vector3(2.9, 0.1, 2.0), 40],
		[Vector3(10.0, 7.0, 6.4), Vector3(2.9, 0.1, 2.0), 40],
	]
	var rm := BoxMesh.new()
	rm.size = Vector3(0.012, 0.45, 0.012)
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.7, 0.8, 1.0, 0.45)
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.material = rmat
	for rz in rain_zones:
		var rp := CPUParticles3D.new()
		rp.position = rz[0]
		rp.amount = rz[2]
		rp.lifetime = 0.9
		rp.local_coords = false
		rp.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		rp.emission_box_extents = rz[1]
		rp.direction = Vector3(0, -1, 0)
		rp.spread = 1.0
		rp.gravity = Vector3(0, -6.0, 0)
		rp.initial_velocity_min = 8.0
		rp.initial_velocity_max = 10.0
		rp.mesh = rm
		add_child(rp)

	# ---- Larry: espia pela janela do fundo e some quando o jogador olha
	larry = _baked("larry")
	if larry != null:
		larry.visible = false
		larry.scale = Vector3.ONE * 1.25
		add_child(larry)
		_set_layers(larry, 3)
	larry_next = LARRY_FIRST

	# vulto translúcido
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0, 0, 0, 0.5)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost = Node3D.new()
	cyl(Vector3(0, 0.95, 0), 0.3, 0.4, 1.5, gm, Vector3.ZERO, ghost)
	var gh := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.26
	sm.height = 0.52
	gh.mesh = sm
	gh.material_override = gm
	gh.position = Vector3(0, 1.95, 0)
	ghost.add_child(gh)
	ghost.visible = false
	add_child(ghost)


# ---------------------------------------------------------------- jogador
func _build_player() -> void:
	player = CharacterBody3D.new()
	player.position = Vector3(11.5, 0.05, 0)
	player.rotation.y = PI / 2.0
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 0.9
	player.add_child(cs)
	cam = Camera3D.new()
	cam.position.y = 1.65
	cam.fov = 75.0
	cam.near = 0.05
	player.add_child(cam)
	add_child(player)
	held = Node3D.new()
	held.position = Vector3(0.3, -0.42, -0.55)
	cam.add_child(held)
	held.visible = false


func _hold_item(key: String) -> void:
	for ch in held.get_children():
		ch.queue_free()
	var p := _make_prop(key)
	p.rotation_degrees = Vector3(0, -30, 0)
	held.add_child(p)
	held.visible = true


# ---------------------------------------------------------------- HUD
func _lbl(parent: Control, size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _build_hud() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(root)

	for code in [BLUR, VIGNETTE, GRAIN]:
		var cr := ColorRect.new()
		cr.set_anchors_preset(Control.PRESET_FULL_RECT)
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sh := Shader.new()
		sh.code = code.replace("GRAIN_FORCE", str(GRAIN_FORCA)).replace("GRAIN_SIZE", str(GRAIN_TAMANHO)).replace("VHS_RES", str(RESOLUCAO)).replace("VHS_MACIO", str(MACIO))
		var sm := ShaderMaterial.new()
		sm.shader = sh
		cr.material = sm
		root.add_child(cr)

	l_obj = _lbl(root, 20, Color(0.85, 0.65, 0.23))
	l_obj.position = Vector2(18, 14)
	l_obj.custom_minimum_size = Vector2(560, 0)
	l_obj.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	l_chk = RichTextLabel.new()
	l_chk.bbcode_enabled = true
	l_chk.fit_content = true
	l_chk.scroll_active = false
	l_chk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l_chk.add_theme_font_size_override("normal_font_size", 18)
	l_chk.anchor_left = 1.0
	l_chk.anchor_right = 1.0
	l_chk.offset_left = -260
	l_chk.offset_right = -18
	l_chk.offset_top = 14
	root.add_child(l_chk)

	l_sub = _lbl(root, 24, Color(0.93, 0.9, 0.85))
	l_sub.anchor_left = 0.15
	l_sub.anchor_right = 0.85
	l_sub.anchor_top = 1.0
	l_sub.anchor_bottom = 1.0
	l_sub.offset_top = -170
	l_sub.offset_bottom = -50
	l_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_sub.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	l_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l_sub.modulate.a = 0.0

	l_hint = _lbl(root, 22, Color(0.93, 0.9, 0.85))
	l_hint.anchor_left = 0.25
	l_hint.anchor_right = 0.75
	l_hint.anchor_top = 0.58
	l_hint.anchor_bottom = 0.62
	l_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	bar = ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.step = 0.001
	bar.show_percentage = false
	bar.anchor_left = 0.42
	bar.anchor_right = 0.58
	bar.anchor_top = 0.64
	bar.anchor_bottom = 0.64
	bar.offset_bottom = 8
	bar.visible = false
	root.add_child(bar)

	var dot := ColorRect.new()
	dot.color = Color(1, 1, 1, 0.5)
	dot.anchor_left = 0.5
	dot.anchor_right = 0.5
	dot.anchor_top = 0.5
	dot.anchor_bottom = 0.5
	dot.offset_left = -2
	dot.offset_right = 2
	dot.offset_top = -2
	dot.offset_bottom = 2
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dot)

	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.04, 0.94)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(cc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	cc.add_child(vb)
	ov_title = Label.new()
	ov_title.add_theme_font_size_override("font_size", 44)
	ov_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(ov_title)
	ov_text = Label.new()
	ov_text.add_theme_font_size_override("font_size", 20)
	ov_text.add_theme_color_override("font_color", Color(0.65, 0.63, 0.58))
	ov_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ov_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ov_text.custom_minimum_size = Vector2(680, 0)
	vb.add_child(ov_text)
	ov_btn = Button.new()
	ov_btn.custom_minimum_size = Vector2(240, 48)
	ov_btn.add_theme_font_size_override("font_size", 22)
	ov_btn.pressed.connect(_on_btn)
	vb.add_child(ov_btn)


func _show_overlay(title: String, text: String, btn: String) -> void:
	ov_title.text = title
	ov_text.text = text
	ov_btn.text = btn
	overlay.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_btn() -> void:
	if over:
		get_tree().reload_current_scene()
		return
	overlay.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	paused = false
	if not started:
		started = true
		_begin()


func _pause() -> void:
	paused = true
	_show_overlay("Pausa", "O jogo está pausado.", "Continuar")


func say(txt: String, secs: float = 5.0) -> void:
	# a legenda aparece letra por letra, como se alguém estivesse digitando
	l_sub.text = txt
	l_sub.modulate.a = 1.0
	l_sub.visible_characters = 0
	if sub_tween:
		sub_tween.kill()
	var tdur := float(txt.length()) / TYPE_CPS
	sub_tween = create_tween()
	sub_tween.tween_property(l_sub, "visible_characters", txt.length(), tdur)
	sub_tween.tween_interval(secs)
	sub_tween.tween_property(l_sub, "modulate:a", 0.0, 0.5)


func _render_chk() -> void:
	var rows := [["oleo", "Óleo trocado"], ["bateria", "Bateria nova"], ["pneus", "Pneus calibrados"], ["capo", "Capô fechado"]]
	var s := "[right]"
	for r in rows:
		if car_state[r[0]]:
			s += "[color=#7fc08a][x] %s[/color]\n" % r[1]
		else:
			s += "[color=#9a968b][ ] %s[/color]\n" % r[1]
	l_chk.text = s + "[/right]"


func _set_obj() -> void:
	if step < steps.size():
		l_obj.text = steps[step]["o"]
	else:
		l_obj.text = ""


# ---------------------------------------------------------------- áudio gerado por código
func _wav(data: PackedByteArray, loop: bool = false) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SR
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = data.size() / 2
	return w


func _bytes(a: PackedFloat32Array) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(a.size() * 2)
	for i in a.size():
		b.encode_s16(i * 2, int(clampf(a[i], -1.0, 1.0) * 32767.0))
	return b


func _tone(f1: float, dur: float, vol: float, f2: float = -1.0, kind: int = 0, loop: bool = false) -> AudioStreamWAV:
	var n := int(SR * dur)
	var a := PackedFloat32Array()
	a.resize(n)
	var ph := 0.0
	for i in n:
		var u := float(i) / float(n)
		var f := f1
		if f2 > 0.0:
			f = lerpf(f1, f2, u)
		ph += f / float(SR)
		var s := sin(TAU * ph)
		if kind == 1:
			s = fposmod(ph, 1.0) * 2.0 - 1.0
		elif kind == 2:
			s = 1.0 if s > 0.0 else -1.0
		var env := 1.0
		if not loop:
			env = pow(1.0 - u, 2.0)
		a[i] = s * vol * env
	return _wav(_bytes(a), loop)


func _noise(dur: float, vol: float, hp: bool = false, k: float = 0.2, fade: bool = true, loop: bool = false) -> AudioStreamWAV:
	var n := int(SR * dur)
	var a := PackedFloat32Array()
	a.resize(n)
	var y := 0.0
	for i in n:
		var x := randf() * 2.0 - 1.0
		y += (x - y) * k
		var s := y
		if hp:
			s = x - y
		var env := 1.0
		if fade:
			env = 1.0 - float(i) / float(n)
		a[i] = s * vol * env
	return _wav(_bytes(a), loop)


func _rain() -> AudioStreamWAV:
	var n := SR * 4
	var a := PackedFloat32Array()
	a.resize(n)
	var y1 := 0.0
	var y2 := 0.0
	var drop := 0.0
	for i in n:
		var x := randf() * 2.0 - 1.0
		y1 += (x - y1) * 0.3
		y2 += (x - y2) * 0.03
		var band := y1 - y2
		if randf() < 0.0008:
			drop = randf_range(0.3, 0.9) * (1.0 if randf() > 0.5 else -1.0)
		drop *= 0.985
		var gust := 1.0 + 0.25 * sin(TAU * float(i) / float(n) * 2.0)
		a[i] = (band * 0.9 + drop * 0.5 + y2 * 1.5) * gust * 0.55
	return _wav(_bytes(a), true)


func _radio_stream() -> AudioStream:
	# se existir assets/audio/radio.ogg (ou .mp3), toca esse arquivo, abafado; senão usa a melodia própria
	var path := _find_asset("res://assets/audio/", "radio", [".ogg", ".mp3", ".wav"])
	if path != "":
		var st = load(path)
		if st is AudioStreamMP3:
			(st as AudioStreamMP3).loop = true
		elif st is AudioStreamOggVorbis:
			(st as AudioStreamOggVorbis).loop = true
		if st is AudioStream:
			var bi := AudioServer.bus_count
			AudioServer.add_bus(bi)
			AudioServer.set_bus_name(bi, "Radio")
			var lpf := AudioEffectLowPassFilter.new()
			lpf.cutoff_hz = 2600.0
			AudioServer.add_bus_effect(bi, lpf)
			AudioServer.set_bus_send(bi, "Master")
			radio_bus = "Radio"
			return st
	return _radio()


func _radio() -> AudioStreamWAV:
	# melodia original e simples (La menor), abafada por um filtro, com chiado de estática
	var dur := 8.0
	var n := int(SR * dur)
	var a := PackedFloat32Array()
	a.resize(n)
	var notes := [220.0, 261.63, 329.63, 261.63, 293.66, 246.94, 196.0, 246.94, 220.0, 329.63, 293.66, 261.63, 246.94, 196.0, 220.0, 0.0]
	var y := 0.0
	var lp := 0.0
	var ph := 0.0
	for i in n:
		var tt := float(i) / float(SR)
		var idx := int(tt / 0.5) % notes.size()
		var nt: float = notes[idx]
		var local := fposmod(tt, 0.5)
		var s := 0.0
		if nt > 0.0:
			ph += nt / float(SR)
			var env := exp(-local * 4.0) * minf(local * 60.0, 1.0)
			s = (sin(TAU * ph) + 0.5 * sin(TAU * ph * 2.0) + 0.25 * sin(TAU * ph * 3.0)) * env * 0.35
		s *= 0.7 + 0.3 * sin(TAU * tt / dur * 5.0)
		lp += (s - lp) * 0.12
		var x := randf() * 2.0 - 1.0
		y += (x - y) * 0.5
		var stat := (x - y) * 0.12 * (0.6 + 0.4 * sin(TAU * tt / dur * 3.0))
		if randf() < 0.0004:
			stat += randf_range(-0.6, 0.6)
		a[i] = lp + stat
	return _wav(_bytes(a), true)


func sfx(s: AudioStream, db: float = 0.0, pitch: float = 1.0) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.volume_db = db
	p.pitch_scale = pitch
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


func _build_audio() -> void:
	snd_creak = _tone(180.0, 1.2, 0.3, 90.0, 1)
	snd_clack = _tone(300.0, 0.08, 0.4, -1.0, 2)
	snd_step = _noise(0.1, 0.5, false, 0.15, true)
	snd_gate = _noise(2.0, 0.6, false, 0.05, true)
	snd_gate2 = _tone(60.0, 2.0, 0.3, -1.0, 1)
	snd_hiss = _noise(1.0, 0.5, true, 0.3, true)
	snd_lift = _tone(70.0, 6.5, 0.3, 85.0, 1)
	snd_chime1 = _tone(1320.0, 1.4, 0.3)
	snd_chime2 = _tone(990.0, 1.6, 0.3)
	var rain := AudioStreamPlayer.new()
	rain.stream = _rain()
	rain.volume_db = -14.0
	add_child(rain)
	rain.play()
	var hum := AudioStreamPlayer.new()
	hum.stream = _tone(50.0, 1.0, 0.4, -1.0, 0, true)
	hum.volume_db = -22.0
	add_child(hum)
	hum.play()
	var radio := AudioStreamPlayer3D.new()
	radio.stream = _radio_stream()
	radio.bus = radio_bus
	radio.position = Vector3(12.3, 1.0, -2.05)
	radio.unit_size = 5.0
	radio.max_distance = 35.0
	radio.volume_db = -4.0
	add_child(radio)
	radio.play()


# ---------------------------------------------------------------- etapas da Parte 1
func _build_steps() -> void:
	steps = [
		{"o": "Feche o portão principal (botão na parede, perto do portão)", "at": Vector2(4.5, 7.7), "r": 2.2, "h": "[E] Fechar portão", "hold": 0.0, "go": _s0},
		{"o": "Leia a ordem de serviço na prancheta (bancada)", "at": Vector2(-5.7, -7.0), "r": 1.7, "h": "[E] Ler prancheta", "hold": 0.0, "go": _s1},
		{"o": "Pegue o calibrador de pneus no compressor de ar (fundo da garagem)", "at": Vector2(0.6, -7.2), "r": 1.9, "h": "[E] Pegar calibrador", "hold": 0.0, "go": _p3},
		{"o": "Abra o capô do carro", "at": CAR_FRONT, "r": 1.9, "lift": true, "h": "[E] Abrir capô", "hold": 0.0, "go": _s2},
		{"o": "Pegue o funil e o galão de óleo no estoque (depósito, porta à esquerda da garagem)", "at": Vector2(-11.3, -2.8), "r": 1.8, "h": "[E] Pegar funil e galão", "hold": 0.0, "go": _s3},
		{"o": "Troque o óleo (segure E no carro)", "at": CAR_FRONT, "r": 1.9, "lift": true, "h": "Segure [E] para trocar o óleo", "hold": 4.0, "go": _s4},
		{"o": "Pegue o multímetro na bancada", "at": Vector2(-4.3, -7.0), "r": 1.7, "h": "[E] Pegar multímetro", "hold": 0.0, "go": _s5},
		{"o": "Teste a bateria do carro com o multímetro", "at": CAR_FRONT, "r": 1.9, "lift": true, "h": "[E] Testar bateria", "hold": 0.0, "go": _s6},
		{"o": "Vá ao depósito (porta à esquerda da garagem) e pegue a bateria nova", "at": Vector2(-11.3, 0.0), "r": 2.3, "h": "[E] Pegar bateria nova", "hold": 0.0, "go": _s7},
		{"o": "Troque a bateria do carro (segure E)", "at": CAR_FRONT, "r": 1.9, "lift": true, "h": "Segure [E] para instalar a bateria", "hold": 4.0, "go": _s8},
		{"o": "Calibre os pneus: pneu 1 de 4 (agache ao lado da roda, segure E)", "at": TIRE_SPOTS[0], "r": 1.0, "lift": true, "multi": 4, "h": "Segure [E] para calibrar o pneu", "hold": 3.5, "go": _s9},
		{"o": "Ronda do turno: verifique a janela dos fundos (lado direito)", "at": Vector2(5.0, -7.5), "r": 1.8, "h": "Segure [E] para checar a trava", "hold": 2.0, "go": _p4},
		{"o": "Ronda do turno: verifique a janela dos fundos (lado esquerdo)", "at": Vector2(-5.0, -6.4), "r": 1.6, "h": "Segure [E] para checar a trava", "hold": 2.0, "go": _p5},
		{"o": "Ronda do turno: verifique a janela do depósito", "at": Vector2(-10.0, -3.0), "r": 1.8, "h": "Segure [E] para checar a trava", "hold": 2.0, "go": _p6},
		{"o": "Ronda do turno: verifique a janela da recepção", "at": Vector2(10.0, -3.0), "r": 1.8, "h": "Segure [E] para checar a trava", "hold": 2.0, "go": _p7},
		{"o": "Feche o capô", "at": CAR_FRONT, "r": 1.9, "lift": true, "h": "[E] Fechar capô", "hold": 0.0, "go": _s10},
	]


func _s0() -> void:
	sfx(snd_gate, -4.0)
	sfx(snd_gate2, -8.0)
	create_tween().tween_property(gate, "position:y", 1.6, 2.0)


func _s1() -> void:
	say("Ordem de serviço, Cadillac Eldorado: 1) Trocar o óleo   2) Verificar a bateria   3) Calibrar os pneus   4) Ronda: checar as travas das janelas", 9.0)


func _p3() -> void:
	sfx(snd_clack, -8.0)
	say("Calibrador na mão. Mangueira conectada ao compressor.", 2.5)


func _p4() -> void:
	sfx(snd_clack, -6.0)
	say("Trava da janela direita: ok.", 2.5)


func _p5() -> void:
	sfx(snd_clack, -6.0)
	say("Trava da janela esquerda: ok. ...Tinha algo se mexendo lá fora?", 4.0)


func _p6() -> void:
	sfx(snd_creak, -8.0, 0.8)
	say("Janela do depósito: a trava estava frouxa. Apertei.", 3.5)


func _p7() -> void:
	sfx(snd_clack, -6.0)
	say("Janela da recepção: ok. Hora de fechar o serviço.", 3.0)


func _s2() -> void:
	sfx(snd_clack, -4.0)
	sfx(snd_creak, -6.0, 0.8)
	bay_light.visible = true
	if hood_pivot != null:
		var ot := create_tween()
		ot.tween_property(hood_pivot, "rotation:x", deg_to_rad(-62.0), 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _s3() -> void:
	galao.visible = false
	funil.visible = false
	_hold_item("oleo")
	say("Galão e funil na mão.", 2.5)


func _s4() -> void:
	held.visible = false
	car_state["oleo"] = true
	_render_chk()
	sfx(snd_hiss, -10.0, 0.6)
	say("Óleo trocado.", 2.5)


func _larry_appear() -> void:
	if larry == null:
		return
	if larry_tween:
		larry_tween.kill()
	larry.position = LARRY_SPOTS[1]      # janela em cima da bancada
	larry.rotation = Vector3.ZERO
	larry.visible = true
	larry_state = 1
	larry_born = t
	larry_until = t + 8.0
	sfx(snd_creak, -2.0, 0.7)
	sfx(snd_clack, -2.0, 0.6)
	flick_until = t + 0.5
	var base_fov := 75.0
	var zt := create_tween()
	zt.tween_property(cam, "fov", base_fov * 0.55, 0.18).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	zt.tween_interval(1.0)
	zt.tween_property(cam, "fov", base_fov, 0.7).set_trans(Tween.TRANS_SINE)


func _larry_duck(seen: bool) -> void:
	# Larry vira o rosto de leve (percebeu que foi visto), depois abaixa reto e se esconde atrás da parede
	larry_state = 2
	if seen:
		sfx(snd_creak, -12.0, 1.3)
	if larry_tween:
		larry_tween.kill()
	larry_tween = create_tween()
	var low: Vector3 = LARRY_SPOTS[1] + Vector3(0, -0.8, 0.0)
	larry_tween.tween_property(larry, "rotation:y", deg_to_rad(28.0), 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	larry_tween.tween_interval(0.08)
	larry_tween.tween_property(larry, "position", low, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	larry_tween.tween_callback(func():
		larry.visible = false
		larry_state = 0)


func _s5() -> void:
	multi.visible = false
	_hold_item("multi")
	_larry_appear()


func _s6() -> void:
	held.visible = false
	say("Multímetro: 9,8 V. Carga baixa. Precisa de uma bateria nova, no depósito dos fundos.", 6.0)


func _s7() -> void:
	new_bat.visible = false
	_hold_item("bateria")


func _s8() -> void:
	held.visible = false
	car_bat.visible = false
	car_bat2.visible = true
	car_state["bateria"] = true
	_render_chk()
	sfx(snd_clack, -4.0)
	say("Bateria instalada.", 2.5)


func _s9() -> void:
	car_state["pneus"] = true
	_render_chk()
	sfx(snd_hiss, -8.0, 1.4)
	say("Pneus calibrados.", 2.5)


func _s10() -> void:
	sfx(snd_creak, -8.0, 1.1)
	bay_light.visible = false
	if hood_pivot != null:
		var ct := create_tween()
		ct.tween_property(hood_pivot, "rotation:x", 0.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		ct.tween_callback(func(): sfx(snd_clack, -2.0, 0.7))
	car_state["capo"] = true
	_render_chk()
	_finish()


func _advance() -> void:
	var cur: Dictionary = steps[step]
	if int(cur.get("multi", 0)) > 0:
		tire_i += 1
		if tire_i < int(cur["multi"]):
			sfx(snd_hiss, -8.0, 1.4)
			say("Pneu %d de %d calibrado. Vá até a próxima roda." % [tire_i, int(cur["multi"])], 3.0)
			cur["at"] = TIRE_SPOTS[tire_i]
			cur["o"] = "Calibre os pneus: pneu %d de %d (agache ao lado da roda, segure E)" % [tire_i + 1, int(cur["multi"])]
			_set_obj()
			return
	var cb: Callable = steps[step]["go"]
	cb.call()
	if not over:
		step += 1
		_set_obj()


func _begin() -> void:
	say("Marcos (chefe): Cara, o guincho quebrou na estrada e não volto pra fechar. Revisa o Cadillac na baia 1, o dono vem cedo. Tranca o portão principal antes de mexer no carro.", 11.0)


func _finish() -> void:
	over = true
	l_hint.visible = false
	bar.visible = false
	l_obj.text = ""
	for hm in head_mats:
		var m: StandardMaterial3D = hm
		m.albedo_color = Color(1.0, 0.92, 0.65)
		m.emission_enabled = true
		m.emission = Color(1.0, 0.9, 0.6)
		m.emission_energy_multiplier = 2.0
	sfx(_tone(45.0, 2.2, 0.35, 95.0, 1), -4.0)
	say("O serviço está pronto. Lá fora, a chuva não para.", 5.0)
	get_tree().create_timer(4.5).timeout.connect(_chime)
	get_tree().create_timer(9.5).timeout.connect(_end_screen)


func _chime() -> void:
	sfx(snd_chime1, -8.0)
	get_tree().create_timer(0.5).timeout.connect(_chime2)
	say("...ao longe, o sino da porta lateral.", 4.0)


func _chime2() -> void:
	sfx(snd_chime2, -8.0)


func _end_screen() -> void:
	paused = true
	_show_overlay("Fim da Parte 1", "Óleo, bateria, pneus e capô: o Cadillac está pronto.\n\nMas o sino da porta lateral acabou de tocar...\n\nNa Parte 2 chega o cliente estranho, com o diálogo de escolhas.", "Jogar de novo")


# ---------------------------------------------------------------- entrada e loop
func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not paused:
		player.rotation.y -= ev.relative.x * 0.0022
		pitch = clampf(pitch - ev.relative.y * 0.0022, -1.4, 1.4)
		cam.rotation.x = pitch
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.physical_keycode == KEY_E:
			press_e = true
		elif ev.physical_keycode == KEY_F11:
			var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
		elif ev.physical_keycode == KEY_ESCAPE and not paused and not over:
			_pause()


func _process(_delta: float) -> void:
	if lift_carriage == null or car_root == null:
		return
	if lift_rest_y > 1.0e8:
		lift_rest_y = lift_carriage.global_position.y
	car_root.position.y = CAR_BASE.y + (lift_carriage.global_position.y - lift_rest_y)
	if lift_anim != null:
		if lift_state == 1 and not lift_anim.is_playing():
			lift_state = 2
			sfx(snd_clack, -4.0)
		elif lift_state == 3 and lift_anim.current_animation_position >= LIFT_DOWN_END:
			lift_anim.pause()
			lift_state = 0
			sfx(snd_clack, -4.0)


func _near(at: Vector2, r: float) -> bool:
	var p := Vector2(player.global_position.x, player.global_position.z)
	return p.distance_to(at) < r


func _physics_process(delta: float) -> void:
	if paused:
		return
	t += delta

	# movimento
	var dx := 0.0
	var dz := 0.0
	if not over:
		dx = float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
		dz = float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	var dir := player.global_transform.basis * Vector3(dx, 0, dz)
	dir.y = 0
	dir = dir.normalized()
	var sp := 2.4
	if Input.is_physical_key_pressed(KEY_SHIFT):
		sp = 4.0
	player.velocity.x = dir.x * sp
	player.velocity.z = dir.z * sp
	if player.is_on_floor():
		player.velocity.y = -0.5
	else:
		player.velocity.y -= 9.8 * delta
	player.move_and_slide()
	var moving := dir.length() > 0.1
	var want_crouch := 0.0
	if step < steps.size() and int(steps[step].get("multi", 0)) > 0 and prog > 0.0:
		want_crouch = 1.0
	crouch = move_toward(crouch, want_crouch, delta * 3.0)
	cam.position.y = 1.65 - crouch * 0.85
	if moving:
		cam.position.y += sin(t * 7.0) * 0.025
		step_acc += delta * sp
		if step_acc > 1.7:
			step_acc = 0.0
			sfx(snd_step, -14.0, randf_range(0.8, 1.2))

	# gatilhos
	var px := player.global_position.x
	if not in_dep and px < -8.0:
		in_dep = true
		sfx(snd_creak, -10.0)
		flick_until = t + 0.6
		say("O corredor dos fundos é sempre frio...", 3.5)
	if in_dep and not ghost_done and step == 8 and px > -6.0:
		ghost_done = true
		ghost.position = Vector3(-3.5, 0, -6.8)
		ghost.visible = true
		ghost_until = t + 2.5
		sfx(snd_creak, -10.0)
		say("Deve ser o reflexo da chuva na janela.", 3.5)

	# Larry: aparece só quando o jogador pega o multímetro; some na hora quando o jogador olha
	if larry != null and not over and larry_state == 1:
		var head: Vector3 = larry.global_position + Vector3(0, 2.0, 0)
		var to := head - cam.global_position
		var seen := cam.is_position_in_frustum(head) and to.length() < 22.0 and (-cam.global_transform.basis.z).dot(to.normalized()) > 0.9
		if (seen and t > larry_born + 0.8) or t > larry_until:
			_larry_duck(seen)

	# interações
	var h := ""
	var s = null
	if step < steps.size():
		s = steps[step]
	var step_near := false
	if s != null and _near(s["at"], s["r"]):
		step_near = true
		if s.get("lift", false) and lift_state != 0:
			h = "Abaixe o carro no elevador para trabalhar nele"
			prog = 0.0
			bar.visible = false
		else:
			h = s["h"]
			if s["hold"] > 0.0:
				if Input.is_physical_key_pressed(KEY_E) and not over:
					prog += delta / s["hold"]
					bar.visible = true
					bar.value = prog
					if prog >= 1.0:
						prog = 0.0
						bar.visible = false
						_advance()
				else:
					prog = 0.0
					bar.visible = false
			else:
				bar.visible = false
				if press_e:
					_advance()
	else:
		prog = 0.0
		bar.visible = false
		if not over and _near(Vector2(0.6, -7.4), 2.0):
			h = "[E] Ler quadro"
			if press_e:
				say("Quadro: Proibido abandonar a oficina durante o turno solo.", 5.0)
	if not step_near and not over and lift_anim != null and _aim_at(lift_switch_3d, lift_switch_r, 2.8):
		if lift_state == 0:
			h = "[E] Subir o carro"
		elif lift_state == 2:
			h = "[E] Descer o carro"
		else:
			h = "O elevador está em movimento..."
		if press_e:
			_lift_toggle()
	if over:
		h = ""
	l_hint.text = h
	l_hint.visible = h != ""
	press_e = false

	# luzes
	for pair in lamps:
		var l: OmniLight3D = pair[0]
		var b: float = pair[1]
		if t < flick_until:
			l.light_energy = b if randf() > 0.5 else b * 0.05
		else:
			l.light_energy = b + sin(t * 3.0) * b * 0.03
	if ghost.visible and t > ghost_until:
		ghost.visible = false
