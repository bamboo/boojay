"""
correct
"""
o1 = object()
o2 = o1
if o1 is not o2:
	print "incorrect"
else:
	print "correct"
	