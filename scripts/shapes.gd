class_name Shapes
## The four symbol shapes used by symbol puzzles: 0 sphere, 1 cube,
## 2 triangular prism, 3 cylinder.

const COUNT := 4


static func mesh(index: int, size: float) -> Mesh:
	match index:
		0:
			var s := SphereMesh.new()
			s.radius = size / 2.0
			s.height = size
			return s
		1:
			var b := BoxMesh.new()
			b.size = Vector3.ONE * size
			return b
		2:
			var p := PrismMesh.new()
			p.size = Vector3(size, size, size)
			return p
		_:
			var c := CylinderMesh.new()
			c.top_radius = size / 2.0
			c.bottom_radius = size / 2.0
			c.height = size
			return c


## Orient shapes so their profile faces a wall whose normal is along x.
static func rotation(index: int) -> Vector3:
	match index:
		2:
			return Vector3(0, 90, 0)
		3:
			return Vector3(0, 0, 90)
		_:
			return Vector3.ZERO
