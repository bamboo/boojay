"""
test
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
		
	print "test"
|]

runTestWithJar(test, jar)
