tool
extends Spatial


const proto = preload("res://engineinterface.gd")
const parcel_size = 16

var peer = null
var global_scene
var id

var current_index = -1
var entities = {"0": get_node(".")}
var components : Dictionary


func create(msg, p_peer, is_global):
	id = msg.payload.id
	global_scene = is_global

	peer = p_peer

	if msg.payload.name != "DCL Scene":
		ContentManager.load_contents(self, msg.payload)

	if msg.payload.contents.size() > 0:
		transform.origin = Vector3(msg.payload.basePosition.x, 0, msg.payload.basePosition.y) * parcel_size
	
	var response = {"eventType":"SceneReady", "payload": {"sceneId": id}}
	Server.send({"type": "ControlEvent", "payload": JSON.print(response)}, peer)


func contents_loaded():
	print("scene ready! ", id)


func message(scene_msg):
	#print(scene_msg.to_string())

	if scene_msg.has_createEntity():
		#print("create entity ", scene_msg.get_createEntity().get_id())
		var entity_id = scene_msg.get_createEntity().get_id()
		entities[entity_id] = Spatial.new()
		entities[entity_id].name = entity_id
		add_child(entities[entity_id])

	if scene_msg.has_removeEntity():
		pass#print("remove entity ", scene_msg.get_removeEntity().get_id())

	if scene_msg.has_setEntityParent():
#		print("setEntityParent %s -> %s" % [
#			scene_msg.get_setEntityParent().get_parentId(),
#			scene_msg.get_setEntityParent().get_entityId() ])
		reparent(scene_msg.get_setEntityParent().get_entityId(), scene_msg.get_setEntityParent().get_parentId())

	if scene_msg.has_componentCreated():
		#print("component created ", scene_msg.get_componentCreated().get_name())
		var component_id = scene_msg.get_componentCreated().get_id()
		components[component_id] = preload("cube.tscn").instance()
		components[component_id].name = scene_msg.get_componentCreated().get_name()

	if scene_msg.has_componentDisposed():
		pass#print("component disposed ", scene_msg.get_componentDisposed().get_id())

	if scene_msg.has_componentRemoved():
		pass#print("component removed ", scene_msg.get_componentRemoved().get_name())

	if scene_msg.has_componentUpdated():
		#print("component updated %s -> %s" % [
#			scene_msg.get_componentUpdated().get_id(),
#			scene_msg.get_componentUpdated().get_json() ])
		var json = JSON.parse(scene_msg.get_componentUpdated().get_json()).result
		if json.has("src"):
			var ext = json.src.get_extension()
			if ext == "glb":
				var component = ContentManager.get_instance(json.src)
				if is_instance_valid(component):
					components[scene_msg.get_componentUpdated().get_id()] = component
					
					for child in component.get_children():
						if child.name.ends_with("_collider") \
						or child.name.begins_with("FloorBaseGrass"):
							child.queue_free()

	if scene_msg.has_attachEntityComponent():
		#print("attach component to entity %s -> %s" % [
#			scene_msg.get_attachEntityComponent().get_entityId(),
#			scene_msg.get_attachEntityComponent().get_id() ])
		entities[scene_msg.get_attachEntityComponent().get_entityId()].add_child(
			components[scene_msg.get_attachEntityComponent().get_id()]
		)

	if scene_msg.has_updateEntityComponent():

		var data = scene_msg.get_updateEntityComponent().get_data()
		if data.left(1) in ["[", "{"]:

			var comp = JSON.parse(data)
			printt("update component in entity %s -> %s" % [
				scene_msg.get_updateEntityComponent().get_entityId(),
				scene_msg.get_updateEntityComponent().get_data() ],
				JSON.print(comp.result))
		else:
			var buf = Marshalls.base64_to_raw(data)

			var comp = proto.PB_Transform.new()
			var err = comp.from_bytes(buf)
			if err == proto.PB_ERR.NO_ERRORS:
				var rot = comp.get_rotation()
				var pos = comp.get_position()
				var sca = comp.get_scale()

				var q = Quat(
					rot.get_x(),
					rot.get_y(),
					rot.get_z(),
					rot.get_w()
				)
				var xform = Transform()
				xform = xform.translated(Vector3(pos.get_x(), pos.get_y(), pos.get_z()))
				xform = xform * Transform(q)
				xform = xform.scaled(Vector3(sca.get_x(), sca.get_y(), sca.get_z()))

				var entity_id = scene_msg.get_updateEntityComponent().get_entityId()
				entities[entity_id].set_transform(xform)
			else:
				push_warning("****** error decoding PB_Transform payload %s" % err)

	if scene_msg.has_sceneStarted():
		pass#print("scene started ", id)

	if scene_msg.has_openNFTDialog():
		pass#print("open NFT dialog %s %s" % [
#			scene_msg.get_openNFTDialog().get_assetContractAddress(),
#			scene_msg.get_openNFTDialog().get_tokenId()
#		])

	if scene_msg.has_query():
		pass#print("query ", scene_msg.get_query().get_payload())


func reparent(src, dest):
	var src_node = entities[src]
	var dest_node = entities[dest]
	var xform = src_node.get_global_transform()
	remove_child(src_node)
	dest_node.add_child(src_node)
	src_node.set_global_transform(xform)


func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.is_pressed():
		var response = {
			"eventType":"uuidEvent",
			"sceneId": id,
			"payload": {
				"uuid": "UUIDf",
				"payload": { "buttonId": 0 }
			}

		}
		Server.send({"type": "SceneEvent", "payload": JSON.print(response)}, peer)


func _get_configuration_warning():
	return "" if peer == null else "Scene is currently connected to a peer." +\
			"\nRemoving the DebuggerDump off the tree will completely detach this scene from it."
