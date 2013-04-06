"""
42
ltuae
"""
static class StaticProperties:
	Primitive:
		get: return _primitive
		set: _primitive = value
	_primitive as int
		
	String:
		get: return _string
		set: _string = value
	_string as string
	
StaticProperties.Primitive = 42
print StaticProperties.Primitive

StaticProperties.String = "ltuae"
print StaticProperties.String