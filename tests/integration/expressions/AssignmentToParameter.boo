"""
before: parameter
after: assigned
"""
def assignTo(p):
	print "before: $p"
	p = 'assigned'
	print "after: $p"
	
assignTo 'parameter'