"""
test
"""

jar = [|
	import java.lang
	
	class Base:
		virtual def WithParameter(param as int):
			pass
|]

test = [|
	import java.lang

	class Foo(Base):
		override def WithParameter(param as int):
			pass
		
	print "test"
|]

runTestWithJar(test, jar)
