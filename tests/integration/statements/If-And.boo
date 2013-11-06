"""
a1
b1
b2
c1
c2
c3
correct
"""
def b(label, v as bool):
	print label
	return v
	
if b("a1", false) and not b("a2", true) and b("a3", true):
	print "incorrect"
	
if b("b1", true) and not b("b2", true) and b("b3", true):
	print "incorrect"
	
if b("c1", true) and not b("c2", false) and not b("c3", false):
	print "correct"