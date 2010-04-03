"""
test
"""

jar = [|
	import java.lang
	
	class Base:
		pass
|]

test = [|
	import java.lang

	class Foo(Base):
		pass
		
	print "test"
|]

runTestWithJar(test, jar)
