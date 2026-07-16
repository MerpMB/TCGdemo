class_name VariantShaderCache
extends RefCounted
## Shared shader load/cache for variant material factories.
## Owns the only res://assets/shaders path used by material modules.


const SHADERS_ROOT := "res://assets/shaders"

static var _cache: Dictionary = {}


static func create(shader_name: String) -> ShaderMaterial:
	var cache_key := shader_name
	if _cache.has(cache_key):
		var cached: Shader = _cache[cache_key]
		var material := ShaderMaterial.new()
		material.shader = cached
		return material

	var path := "%s/%s.gdshader" % [SHADERS_ROOT, shader_name]
	if not ResourceLoader.exists(path):
		push_warning("VariantShaderCache: variant shader missing '%s'." % path)
		return null

	var shader := load(path) as Shader
	_cache[cache_key] = shader
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


static func cached_count() -> int:
	return _cache.size()


static func clear() -> void:
	_cache.clear()
