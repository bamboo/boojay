"""
no parameter override
"""

jar = [|
	import java.lang
	
	class Base:
		virtual def WithoutParameter():
			pass
|]

test = [|
	import java.lang

	class Foo(Base):
		override def WithoutParameter():
			pass
		
	print "no parameter override"
|]

runTestWithJar(test, jar)
