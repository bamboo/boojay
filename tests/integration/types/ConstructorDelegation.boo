"""
ltuae
42
"""
class ConstructorDelegation:
	def constructor():
		self(42)
	def constructor(value):
		self.value = value
	public value as object
	
print ConstructorDelegation("ltuae").value
print ConstructorDelegation().value 