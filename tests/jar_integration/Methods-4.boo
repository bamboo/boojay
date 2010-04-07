"""
override with no primitive type parameter in super
"""

jar = [|
	import java.lang
	
	class Bundle:
		pass
	
	class Base:
		virtual def CallingSuperWithParameter(param as Bundle):
			pass
|]

test = [|
	import java.lang

	class Foo(Base):
		override def CallingSuperWithParameter(param as Bundle):
			super(param)
		
	print "override with no primitive type parameter in super"
|]

runTestWithJar(test, jar)
