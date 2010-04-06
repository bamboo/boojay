"""
override with no primitive type parameter
"""

jar = [|
	import java.lang
	
	class Base:
		virtual def WithParameter(param as string):
			pass
|]

test = [|
	import java.lang

	class Foo(Base):
		override def WithParameter(param as string):
			pass
		
	print "override with no primitive type parameter"
|]

runTestWithJar(test, jar)
