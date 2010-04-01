"""
test
"""

jar = [|
	import java.lang
	
	class Unused:
		pass
|]

test = [|
	import java.lang

	print "test"
|]

runTestWithJar(test, jar)
