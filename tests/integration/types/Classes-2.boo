"""
true
false
"""
import java.lang

callable Code() as void

interface IEnvironment:
	pass
	
class DummyEnv(IEnvironment):
	pass
	
static class Environments:
	
	_environment as IEnvironment
	
	Current:
		get: return _environment
	
	def With(environment as IEnvironment, code as Code):
		previous = _environment
		_environment = environment
		
		try:
			code()
		ensure:
			_environment = previous
		
print Environments.Current is null

Environments.With(DummyEnv()):
	print Environments.Current is null
	