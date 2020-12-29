extends Node

"""
A utility to parse .obj object files

Loads the material if the path to the .mtl file is specified.
"""

const ObjParserInteractive = preload("obj_parser_interactive.gd")

static func parse_obj_interactive(obj_path : String, mtl_path := "") -> ObjParserInteractive:
	return ObjParserInteractive.new(obj_path,
			{} if not mtl_path else _parse_mtl_file(mtl_path))


static func parse_obj(obj_path : String, mtl_path := "") -> Mesh:
	var file := File.new()
	file.open(obj_path, File.READ)
	var obj := file.get_as_text()
	var materials : Dictionary
	if mtl_path:
		materials = _parse_mtl_file(mtl_path)
	
	var mesh := Mesh.new()
	var vertices := []
	var normals := []
	var uvs := []
	var faces := {}
	var material_name : String
	
	var lines : Array = obj.split("\n", false)
	for line in lines:
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
	
	for material_group in faces.keys():
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		if materials:
			st.set_material(materials[material_group])
		
		for face in faces[material_group]:
			if face.v.size() != 3:
				continue
			
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
		mesh = st.commit(mesh)
	
	return mesh


static func _parse_mtl_file(path : String) -> Dictionary:
	var file := File.new()
	file.open(path, File.READ)
	var obj := file.get_as_text()

	var materials := {}
	var current_material : SpatialMaterial
	
	var lines := obj.split("\n", false)
	for line in lines:
		var parts : PoolStringArray = line.split(" ", false)
		match parts[0]:
			"newmtl":
				current_material = SpatialMaterial.new()
				materials[parts[1]] = current_material
			"Kd":
				current_material.albedo_color = Color(float(parts[1]), float(parts[2]), float(parts[3]))
			"map_Kd":
				current_material.albedo_texture = _get_texture(path, parts[1])
			"map_Ks":
				current_material.albedo_texture = _get_texture(path, parts[1])
			"map_Ka":
				current_material.albedo_texture = _get_texture(path, parts[1])
	return materials


static func _get_texture(mtl_file : String, texture_file : String) -> ImageTexture:
	var texture_path := mtl_file.get_base_dir().plus_file(texture_file)
	var image := Image.new()
	image.load(texture_path)
	var texture := ImageTexture.new()
	texture.create_from_image(image)
	return texture
