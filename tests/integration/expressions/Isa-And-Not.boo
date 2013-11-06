"""
correct
"""
o as object = "foo"
if o isa string and not len(o) > 2:
	print "incorrect"
	
if o isa string and not len(o) > 3:
	print "correct"