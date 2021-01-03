var mesh := Mesh.new()
var vertices := []
var normals := []
var uvs := []
var faces := {}
var material_name : String
var lines : Array
var materials : Dictionary
var path : String

var current_line := 0
var current_face := 0
var current_material_group := 0
var st : SurfaceTool
var stage := 0

func _init(obj_path : String, _materials : Dictionary) -> void:
	path = obj_path
	var file := File.new()
	file.open(obj_path, File.READ)
	lines = file.get_as_text().split("\n", false)
	materials = _materials


func get_stage_count() -> int:
	return lines.size() * 2


func poll() -> Mesh:
	stage += 1
	if current_line < lines.size():
		_parse_line(lines[current_line])
		current_line += 1
		return null
	elif not st:
		st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		if materials:
			st.set_material(materials[faces.keys()[current_material_group]])
		return null
	
	if current_material_group < faces.keys().size():
		var material_group : String = faces.keys()[current_material_group]
		if current_face < faces[material_group].size():
			_apply_face(faces[material_group][current_face])
			current_face += 1
			return null
		else:
			current_material_group += 1
			mesh = st.commit(mesh)
			st = SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			if materials:
				st.set_material(materials[material_group])
			current_face = 0
			return null
	mesh.resource_path = path
	return mesh


func get_stage() -> int:
	return stage


func _apply_face(face):
	if face.v.size() != 3:
		return
	
	# Vertices
	var fan_v := PoolVector3Array()
	fan_v.append(vertices[face.v[0]])
	fan_v.append(vertices[face.v[2]])
	fan_v.append(vertices[face.v[1]])
	
	# Normals
	var fan_vn := PoolVector3Array()
	fan_vn.append(normals[face.vn[0]])
	fan_vn.append(normals[face.vn[2]])
	fan_vn.append(normals[face.vn[1]])
	
	# Textures
	var fan_vt := PoolVector2Array()
	fan_vt.append(uvs[face.vt[0]])
	fan_vt.append(uvs[face.vt[2]])
	fan_vt.append(uvs[face.vt[1]])
	
	st.add_triangle_fan(fan_v, fan_vt, [], [], fan_vn, [])


func _parse_line(line):
	var parts : Array = line.split(" ", false)
	match parts[0]:
		"v":
			vertices.append(Vector3(float(parts[1]), float(parts[2]), float(parts[3])))
		"vn":
			normals.append(Vector3(float(parts[1]), float(parts[2]), float(parts[3])))
		"vt":
			uvs.append(Vector2(float(parts[1]), 1.0 - float(parts[2])))
		"usemtl":
			# Material group
			material_name = parts[1]
			if not material_name in faces:
				faces[material_name] = []
		"f":
			# Face
			if parts.size() == 4:
				var face = {v = [], vt = [], vn = []}
				for map in parts:
					var vertices_index = map.split("/")
					if vertices_index[0] == "f":
						continue
					face.v.append(int(vertices_index[0]) - 1)
					face.vt.append(int(vertices_index[1]) - 1)
					face.vn.append(int(vertices_index[2]) - 1)
				faces[material_name].append(face)
			elif parts.size() > 4:
				# Triangulate
				var points := []
				for map in parts:
					var vertices_index = map.split("/")
					if vertices_index[0] == "f":
						continue
					var point := []
					point.append(int(vertices_index[0]) - 1)
					point.append(int(vertices_index[1]) - 1)
					point.append(int(vertices_index[2]) - 1)
					points.append(point)
				for i in points.size():
					if i == 0:
						continue
					var face = {v = [], vt = [], vn = []}
					var point0 : Array = points[0]
					var point1 : Array = points[i - 1]
					var point2 : Array = points[i]
					
					face.v.append(point0[0])
					face.v.append(point1[0])
					face.v.append(point2[0])
					
					face.vt.append(point0[1])
					face.vt.append(point1[1])
					face.vt.append(point2[1])
					
					face.vn.append(point0[2])
					face.vn.append(point1[2])
					face.vn.append(point2[2])
					
					faces[material_name].append(face)
