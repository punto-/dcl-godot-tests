extends "res://interfaces/component.gd"
class_name DCL_Material

const _classid = 65

var material : StandardMaterial3D


func _init(_name, _scene, _id):
	super(_name, _scene, _id)
	material = StandardMaterial3D.new()


func update(data):
	var parser = JSON.new()
	var err = parser.parse(data)
	if err != OK:
		return

	var json = parser.get_data()

	if json.has("albedoColor"):
		material.albedo_color = Color(
			json.albedoColor.r,
			json.albedoColor.g,
			json.albedoColor.b
		)
	if json.has("ambientColor"):
		material.albedo_color = Color(
			json.ambientColor.r,
			json.ambientColor.g,
			json.ambientColor.b
		)
	if json.has("albedoTexture"):
		var tex_component = scene.components[json.albedoTexture]
		# the texture reference in the component can change after it was assigned. Keep it up to date
		if tex_component is DCL_VideoTexture:
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
		if tex_component.has_signal("texture_changed"):
			tex_component.texture_changed.connect(_on_albedo_texture_changed)
		material.albedo_texture = tex_component.texture

	if json.has("refractionTexture"):
		var tex_component = scene.components[json.refractionTexture]
		if tex_component.has_signal("texture_changed"):
			tex_component.texture_changed.connect(_on_texture_changed, ["refraction_texture"])
		material.refraction_enabled = true
		material.refraction_texture = tex_component.texture
		material.refraction_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GRAYSCALE


	if json.has("bumpTexture"):
		var tex_component = scene.components[json.bumpTexture]
		if tex_component.has_signal("texture_changed"):
			tex_component.texture_changed.connect(_on_texture_changed, ["normal_texture"])
		material.normal_enabled = true
		material.normal_texture = tex_component.texture

	if json.has("alpha"):
		var new_color = material.albedo_color
		material.flags_transparent = true
		new_color.a = json.alpha

	if json.has("hasAlpha"):
		material.flags_transparent = json.hasAlpha

	if json.has("disableLighting"):
		material.flags_unshaded = json.disableLighting

	if json.has("emissiveTexture"):
		material.emission_enabled = true
		var tex_component = scene.components[json.emissiveTexture]
		# the texture reference in the component can change after it was assigned. Keep it up to date
		if tex_component.has_signal("texture_changed"):
			tex_component.texture_changed.connect(_on_emissive_texture_changed)
		if tex_component is DCL_VideoTexture:
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
			material.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
		material.emission_texture = tex_component.texture

	if json.has("emissiveIntensity"):
		material.emission_enabled = true
		material.emission_energy = json.get("emissiveIntensity", material.emission_energy)

	if json.has("emissiveColor"):
		material.emission_enabled = true
		var color_dict = json.emissiveColor
		material.emission = Color(color_dict.r, color_dict.g, color_dict.b)

	if json.has("metallic"):
		material.metallic = json.metallic

	if json.has("specularIntensity"):
		material.metallic = json.specularIntensity

	if json.has("roughness"):
		material.roughness = json.roughness

	if json.has("alphaTest"):
		material.flags_transparent = true
		material.params_depth_draw_mode = StandardMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
		material.params_use_alpha_scissor = true
		material.params_alpha_scissor_threshold = json.alphaTest


func attach_to(entity):
	if entity.has_node("shape"):
		entity.get_node("shape").mesh.surface_set_material(0, material)

	super.attach_to(entity)


func detach_from(entity):
	if entity.has_node("shape"):
		entity.get_node("shape").set("material/0", StandardMaterial3D.new())

	super.detach_from(entity)


func _on_albedo_texture_changed(value):
	material.albedo_texture = value

func _on_texture_changed(texture, name):
	material.set(name, texture)

func _on_emissive_texture_changed(value):
	material.emission_texture = value
