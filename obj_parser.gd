extends Node

# Obj parser made by Ezcha
# Created on 7/11/2018
# https://ezcha.net
# https://github.com/Ezcha/gd-obj
# MIT License
# https://github.com/Ezcha/gd-obj/blob/master/LICENSE

static func parse_obj(obj_path : String, mtl_path := "") -> Mesh:
	var file := File.new()
	file.open(obj_path, File.READ)
	var obj := file.get_as_text()
	var mats : Dictionary
	if mtl_path:
		mats = _parse_mtl_file(mtl_path)
	
	# Setup
	var mesh := Mesh.new()
	var vertices := PoolVector3Array()
	var normals := PoolVector3Array()
	var uvs := PoolVector2Array()
	var faces := {}
	
	var mat_name : String
	
	# Parse
	var lines := obj.split("\n", false)
	for line in lines:
		var parts : PoolStringArray = line.split(" ", false)
		match parts[0]:
			"v":
				vertices.append(Vector3(float(parts[1]), float(parts[2]), float(parts[3])))
			"vn":
				normals.append(Vector3(float(parts[1]), float(parts[2]), float(parts[3])))
			"vt":
				uvs.append(Vector2(float(parts[1]), 1.0 - float(parts[2])))
			"usemtl":
				# Material group
				mat_name = parts[1]
				if not mat_name in faces:
					faces[mat_name] = []
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
					faces[mat_name].append(face)
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
						
						faces[mat_name].append(face)
	
	for material_group in faces.keys():
		# Mesh Assembler
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		if mats:
			st.set_material(mats[material_group])
		
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


# Returns an array of materials from a MTL file
static func _parse_mtl_file(path : String) -> Dictionary:
	var file := File.new()
	file.open(path, File.READ)
	var obj := file.get_as_text()

	var mats := {}
	var currentMat
	
	var lines := obj.split("\n", false)
	for line in lines:
		var parts : String = line.split(" ", false)
		match parts[0]:
			"newmtl":
				# Create a new material
				currentMat = SpatialMaterial.new()
				mats[parts[1]] = currentMat
			"Kd":
				currentMat.albedo_color = Color(float(parts[1]), float(parts[2]), float(parts[3]))
			"map_Kd":
				currentMat.albedo_texture = _get_texture(path, parts[1])
			"map_Ks":
				currentMat.albedo_texture = _get_texture(path, parts[1])
			"map_Ka":
				currentMat.albedo_texture = _get_texture(path, parts[1])
	return mats


static func _get_texture(mtl_filepath : String, tex_filename : String) -> ImageTexture:
	var texfilepath := mtl_filepath.get_base_dir().plus_file(tex_filename)
	var image := Image.new()
	image.load(texfilepath)
	var texture := ImageTexture.new()
	texture.create_from_image(image)
	return texture
