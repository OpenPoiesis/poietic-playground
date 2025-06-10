class_name Pictogram extends Object

const placeable_nodes = ["Stock", "FlowRate", "Auxiliary", "Cloud", "GraphicalFunction", "Smooth", "Delay"]

const tile_size = 30
const default_image_scale = 1.0

var name: String
var shape: Shape2D
var svg_buffer: PackedByteArray
var offset: Vector2 = Vector2()

# enum Flags { FLIP_HORIZONTALLY, FLIP_VERTICALLY, ROTATE }
# enum Orientation { NORTH, EAST, SOUTH, WEST }

var magnets: Array[Magnet]

class Magnet:
	var name: String
	var position: Vector2

func _init(name: String, shape: Shape2D, magnets: Array[Magnet] = []):
	self.name = name
	self.shape = shape
	self.magnets = magnets
	var relative_path = name + ".svg"
	var path: String
	self.svg_buffer = FileAccess.get_file_as_bytes("res://resources/pictograms/" + relative_path)

var _image_cache: Dictionary[float, Image] = {}

func get_image(scale: float = default_image_scale) -> Image:
	var image = _image_cache.get(scale)
	if image:
		return image
	image = Image.new()
	_image_cache[scale] = image
	if image.load_svg_from_buffer(svg_buffer, scale) == OK:
		for x in range(0, image.get_width()):
			for y in range(0, image.get_height()):
				var pixel = image.get_pixel(x, y)
				image.set_pixel(x, y, pixel.inverted())
	return image	

func get_texture(scale: float = default_image_scale) -> ImageTexture:
	return ImageTexture.create_from_image(get_image(scale))

func get_magnet(name: String) -> Magnet:
	for magnet in magnets:
		if magnet.name == name:
			return magnet
	return null
	
func nearest_magnet(point: Vector2) -> Magnet:
	var offset_point = point + offset
	var nearest: Magnet = null
	var min_dist: float = 0.0
	for i in range(len(magnets)):
		var magnet = magnets[i]
		var dist = magnet.position.distance_to(point)
		if not min_dist:
			min_dist = dist
			nearest = magnet
		elif dist < min_dist:
			min_dist = dist
			nearest = magnet
	return nearest

func nearest_connection(point: Vector2) -> Vector2:
	if magnets and len(magnets) > 0:
		var magnet = nearest_magnet(point)
		return magnet.position
	else:
		return Vector2()
