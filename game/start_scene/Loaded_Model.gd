extends Node3D

# Compute shader running code from 
# https://docs.godotengine.org/en/stable/tutorials/shaders/compute_shaders.html

var render_device
var shader
var model_mesh : Mesh

func _ready() -> void:
	render_device = RenderingServer.create_local_rendering_device()
	var shader_file := load("res://shaders/rayTriangleIntersect.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = render_device.shader_create_from_spirv(shader_spirv)


func on_model_load() -> void:
	if (model_mesh is Mesh):
		#Write mesh to GPU
		var mesh_input := PackedVector3Array(model_mesh.get_faces())
		var input_bytes := mesh_input.to_byte_array()
		
		var buffer : RID = render_device.storage_buffer_create(input_bytes.size(), input_bytes)
		var model_uniform := RDUniform.new()
		model_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		model_uniform.binding = 0
		model_uniform.add_id(buffer)
		
		#Write Ray to GPU
		var ray_orientation = -get_child(0).global_transform.basis.z.normalized()
		var ray_position = Vector3(get_child(0).global_position)
		var ray_position_byte_array = PackedVector3Array([ray_position]).to_byte_array()
		var ray_orientation_byte_array = PackedVector3Array([ray_orientation]).to_byte_array()
		
		var intersections_byte_array = PackedVector3Array([Vector3(0, 0 ,0)]).to_byte_array()
		
		var intersections_buffer : RID = render_device.storage_buffer_create(ray_position_byte_array.size())
		var ray_origin_buffer : RID = render_device.storage_buffer_create(ray_position_byte_array.size(), ray_position_byte_array)
		var ray_direction_buffer : RID = render_device.storage_buffer_create(ray_orientation_byte_array.size(), ray_orientation_byte_array)
		
		var ray_origin_uniform := RDUniform.new()
		ray_origin_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		ray_origin_uniform.binding = 1
		ray_origin_uniform.add_id(ray_origin_buffer)
		
		var ray_direction_uniform := RDUniform.new()
		ray_direction_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		ray_direction_uniform.binding = 2
		ray_direction_uniform.add_id(ray_direction_buffer)
		
		var intersections_uniform := RDUniform.new()
		intersections_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		intersections_uniform.binding = 3
		intersections_uniform.add_id(intersections_buffer)
		
	
		var uniform_set : RID = render_device.uniform_set_create([
			#Create the uniforms outisde the uniform set.
			model_uniform,
			ray_origin_uniform,
			ray_direction_uniform,
			intersections_uniform
		], shader, 0)
		
		#Create Pipeline
		var pipeline : RID = render_device.compute_pipeline_create(shader)
		var compute_list : int = render_device.compute_list_begin()
		
		render_device.compute_list_bind_compute_pipeline(compute_list, pipeline)
		render_device.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
		render_device.compute_list_dispatch(compute_list, 1, 1, 1)
		render_device.compute_list_end()
		
		render_device.submit()
		render_device.sync()
		
		#Retrive intersections from buffer
		var output_bytes : PackedByteArray = render_device.buffer_get_data(intersections_buffer)
		var output := output_bytes.to_float32_array()
		print(output)

func load_model(path) -> void:
	var model: PackedScene = load(path)
	# Load Model into the scene
	if model.can_instantiate():
		add_child(model.instantiate())
		grab_mesh_from_scene(%Loaded_Model)
		on_model_load()

func grab_mesh_from_scene(scene_root):
	model_mesh = get_deepest_node(scene_root).get_mesh()

func get_deepest_node(current_node):
	if (current_node.get_child(0) is Node):
		return get_deepest_node(current_node.get_child(0))
	else:
		return current_node
