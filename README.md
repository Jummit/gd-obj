# GD Obj

A `.obj` parser utility for Godot.

## Why

As of Godot 3.2, Godot is unable to import `.obj` files outside of the `res://` directory, or during application runtime.
gd-obj enables both of these features. gd-obj supports uvs, faces, normals, and non triangulated meshes.

## How to use

Load obj_parser: `const ObjParser = preload("res://addons/gd-obj/obj_parser.gd")`
Call `ObjParser.parse_file(path_to_file)`. It will return a `Mesh` instance.
