@tool
@icon("res://addons/egg_generator/icons/egg_icon.svg")
extends SubViewport
## used to convert a specked_egg_shader material into a cubemap that can be used with the cubemapped_egg shader material instead
class_name ConvertSpeckledMaterialToCubemap

## size of the faces of the cube
@export var image_size:int = 64

## multiplier used to increase image quality
@export var down_scale:int = 2

## Assign egg speckle material
@export var egg_material:ShaderMaterial

## filename to save the result in
@export var cubemap_filename:String  = "egg_cubemap.png"

## click to run
@export var convert_to_cubemap_now:bool = false:
	set (p_value):
		convert_now()

var camera:Camera3D

var cube:MeshInstance3D

var convert_material:ShaderMaterial

# converts the material now
func convert_now() -> void:

	if egg_material == null:
		print("Assign speckle material to Egg Material!")
		return
	
	if camera == null:
		set_up_camera()
	
	set_up_material()
	
	size = Vector2i.ONE * image_size * down_scale
	# NOTE: images are flipped to match the results when using EYEDIR on a samplerCube in a shader
	camera.fov = 90.0
	await get_tree().process_frame # bonus frame wait
	
	camera.rotation_degrees = Vector3(0.0, 0.0, 0.0)
	await get_tree().process_frame # wait for camera to render
	var front_image:Image = flip_image(get_texture().get_image())
	
	camera.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	await get_tree().process_frame # wait for camera to render
	var back_image:Image = flip_image(get_texture().get_image())
	
	camera.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	await get_tree().process_frame # wait for camera to render
	var top_image:Image = flip_image(get_texture().get_image())
	
	camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	await get_tree().process_frame # wait for camera to render
	var bottom_image:Image = flip_image(get_texture().get_image())
	
	camera.rotation_degrees = Vector3(0.0, 90.0, 0.0)
	await get_tree().process_frame # wait for camera to render
	var left_image:Image = flip_image(get_texture().get_image())
	
	camera.rotation_degrees = Vector3(0.0, -90.0, 0.0)
	await get_tree().process_frame # wait for camera to render
	var right_image:Image = flip_image(get_texture().get_image())
	
	await get_tree().process_frame # bonus frame wait
	
	var all_images:Array[Image] = [left_image, right_image, top_image, bottom_image, front_image, back_image]
	save_cubemap_png(all_images, "res://" + cubemap_filename)
	print("complete")
		

# flips an image and resizes it
func flip_image(source:Image, skip_flip:bool = false) -> Image:
	var new_image:Image = source.duplicate(true)
	if skip_flip:
		pass
	else:
		for x in range(0, source.get_width()):
			for y in range(0, source.get_height()):
				new_image.set_pixel(x, y, source.get_pixel(source.get_width() - x - 1, y))
	if down_scale > 1:
		@warning_ignore("integer_division")
		new_image.resize(source.get_width() / down_scale, source.get_height() / down_scale, Image.INTERPOLATE_LANCZOS)
	return new_image

## save the resulting cubemap to a file
func save_cubemap_png(all_images:Array[Image], path_name:String) -> void:
	# assumes images are in order: [left_image, right_image, top_image, bottom_image, front_image, back_image]
	var image_dimensions:Vector2i = Vector2i(all_images[0].get_width(), all_images[0].get_height())
	var new_image:Image = Image.create(image_dimensions.x * 3, image_dimensions.y * 2, false, all_images[0].get_format())
	
	var source_rect:Rect2i = Rect2i(0, 0, image_dimensions.x, image_dimensions.y)
	new_image.blit_rect(all_images[0], source_rect, Vector2i(0, 0)) # right
	new_image.blit_rect(all_images[1], source_rect, Vector2i(image_dimensions.x, 0)) # left
	new_image.blit_rect(all_images[2], source_rect, Vector2i(image_dimensions.x * 2, 0)) # top
	new_image.blit_rect(all_images[3], source_rect, Vector2i(0, image_dimensions.y)) # bottom
	new_image.blit_rect(all_images[4], source_rect, Vector2i(image_dimensions.x, image_dimensions.y)) # back
	new_image.blit_rect(all_images[5], source_rect, Vector2i(image_dimensions.x * 2, image_dimensions.y)) # front
	new_image.save_png(path_name)
	
	# set up import settings on the image
	await get_tree().process_frame
	EditorInterface.get_resource_filesystem().scan() # 
	await get_tree().process_frame
	
	var import_settings:ConfigFile = ConfigFile.new()
	import_settings.load(path_name + ".import")
	print(import_settings)
	import_settings.set_value("remap", "importer", "cubemap_texture")
	import_settings.set_value("remap", "type", "CompressedCubemap")
	import_settings.set_value("params", "slices/arrangement", 2)
	import_settings.set_value("params", "mipmaps/generate", false)
	import_settings.save(path_name + ".import")
	
	EditorInterface.get_resource_filesystem().scan() 

## adds camera an display mesh
func set_up_camera() -> void:
	camera = Camera3D.new()
	camera.owner = self
	camera.fov = 90.0
	add_child(camera)
	cube = MeshInstance3D.new()
	cube.mesh = BoxMesh.new()
	cube.owner = self
	add_child(cube)
	own_world_3d = true
	
func set_up_material() -> void:
	convert_material = ShaderMaterial.new()
	var shader := load("res://addons/egg_generator/shaders/speckled_egg_converter.gdshader")
	convert_material.shader = shader
	
	# copies all parameters from the speckled egg shader to the converter material
	convert_material.set_shader_parameter("noise_texture", egg_material.get_shader_parameter("noise_texture"))
	convert_material.set_shader_parameter("base_colour", egg_material.get_shader_parameter("base_colour"))
	convert_material.set_shader_parameter("speckle_colour", egg_material.get_shader_parameter("speckle_colour"))
	convert_material.set_shader_parameter("noise_threshold", egg_material.get_shader_parameter("noise_threshold"))
	convert_material.set_shader_parameter("soften_threshold", egg_material.get_shader_parameter("soften_threshold"))
	convert_material.set_shader_parameter("blunt_increase", egg_material.get_shader_parameter("blunt_increase"))
	convert_material.set_shader_parameter("blunt_range", egg_material.get_shader_parameter("blunt_range"))
	convert_material.set_shader_parameter("point_increase", egg_material.get_shader_parameter("point_increase"))
	convert_material.set_shader_parameter("point_range", egg_material.get_shader_parameter("point_range"))
	
	cube.material_override = convert_material
	
