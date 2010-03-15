"""
test
"""

jar = [|
	import java.lang
	
	class Foo:
		pass
|]

test = [|
	import java.lang

	print "test"
|]

runTestWithJar(test, jar)
