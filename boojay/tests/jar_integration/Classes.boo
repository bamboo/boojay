"""
test
"""

jar = [|
	import java.lang
|]

test = [|
	import java.lang

	print "test"
|]

runTestWithJar(test, jar)
